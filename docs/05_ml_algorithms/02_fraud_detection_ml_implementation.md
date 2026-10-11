# 02. Fraud Detection Models: Implementation, Feature Selection & Hyperparameter Tuning

A comprehensive, engineering-focused implementation guide for deploying production-grade Machine Learning fraud detection systems. This guide details optimal feature selection, hyperparameter tuning strategies for extreme class imbalance, asymmetric cost optimization, and sub-5ms low-latency model serving.

---

## 1. End-to-End Real-Time Fraud Architecture

Payment authorization imposes strict execution budgets: **total round-trip network latency must not exceed 50ms**, leaving **less than 10ms for real-time feature retrieval and model inference**.

```
                         Payment Authorization Request (ISO 8583 / JSON)
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. Streaming Ingestion & Fast Feature Enrichment (Latency Budget: < 4ms)               │
│    - Online In-Memory Feature Store (Redis / Dragonfly)                                │
│    - Point-in-time sliding aggregates: 5-min velocity, 24-hr spend, distinct MCCs      │
│    - Device & IP reputation cache (risk scores, proxy/VPN flags)                       │
└──────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 2. Compiled ML Model Scoring (Latency Budget: < 3ms)                                   │
│    - Primary GBDT Ensemble (Compiled C++ via Treelite / ONNX Runtime)                  │
│    - Asymmetric cost-sensitive loss (optimized for rare-event fraud: 0.01% - 0.1%)     │
│    - Real-time probability calibration: P(Fraud | X)                                   │
└──────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 3. Policy & Decision Engine (Latency Budget: < 2ms)                                    │
│    - P(Fraud) < Threshold_low  ──► Auto-Approve (Frictionless checkout)                │
│    - Threshold_low ≤ P(Fraud) < Threshold_high ──► Step-Up Challenge (3DS OTP / SMS)   │
│    - P(Fraud) ≥ Threshold_high ──► Hard Decline (Block authorization)                  │
└──────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 4. Asynchronous Feedback Loop (Hours to 90 Days Post-Auth)                             │
│    - Real-time event logging to Kafka / Snowflake (zero train-serving skew)            │
│    - Issuer chargeback ingestion & TC40/SAFE fraud reports (delayed 30-90 days)        │
│    - Automated monitoring: Population Stability Index (PSI) & Recall at 0.5% FPR       │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Optimal Feature Engineering & Selection for Fraud

Fraud models require features that capture anomalous deviations in speed, location, entity relationships, and behavioral patterns.

### The 5 Core Feature Families in Payment Fraud

| Feature Family | Example Attributes | Data Store & Computation | Predictive Signal |
| :--- | :--- | :--- | :--- |
| **1. Velocity & Frequency** | `txns_last_5m`, `txns_last_1h`, `unique_cards_per_device_24h` | In-memory Redis sliding windows | Card testing bots, brute force attacks |
| **2. Monetary Deviation** | `amount_ratio_30d = amount / mean_amount_30d`, `amount_zscore` | Online Feature Store | Account takeover bust-out spending |
| **3. Geo-Spatial Velocity** | `haversine_km / delta_hours`, `country_mismatch_flag` | Real-time computed | Impossible travel (e.g., London $\to$ Tokyo in 1h) |
| **4. Graph & Entity Topology** | `device_degree_centrality`, `shared_phone_cluster_size` | Graph analytics / Precomputed | Fraud rings, organized syndicate farms |
| **5. Behavioral Biometrics** | `keystroke_dynamics`, `paste_count`, `form_fill_duration` | Client-side SDK telemetry | Credential stuffing, automated scripts |

---

### High-Cardinality Categorical Encoding in Fraud

Payment fraud detection is dominated by high-cardinality, heavy-tailed categorical entities:
- `merchant_id` (10M+ distinct merchants)
- `terminal_id` / `card_acceptor_id` (POS hardware devices)
- `device_fingerprint_hash` (browser/canvas/hardware identifiers)
- `issuer_bin` (6–8 digit Bank Identification Numbers, 50,000+ banks)
- `ip_subnet_c` / `asn` (Autonomous System Numbers, internet routing blocks)

Standard encoding techniques fail catastrophically in this domain:
- **One-Hot Encoding**: Causes combinatorial dimensionality explosion, memory exhaustion, and split starvation in decision trees.
- **Frequency / Count Encoding**: Captures volume but misses risk propensity (a merchant with 1M transactions and 0.01% fraud has identical encoding to a high-risk merchant with 1M transactions and 12% fraud).
- **Greedy Target Encoding (Standard Mean Target Statistics)**: Causes severe **target leakage and conditional shift**.

---

### The Greedy Target Statistic (TS) Leakage Trap in Fraud

To understand why CatBoost's Ordered Target Encoding is the gold standard, consider how standard (greedy) target encoding operates:

> **TS_c = Σ_{i: x_i = c} y_i / Σ_{i: x_i = c} 1**

#### Worked Failure Scenario in Payment Fraud:
1. Suppose a new merchant `merchant_xyz` appears in the training set with **only 1 transaction**, and that transaction was fraudulent ($y_1 = 1$).
2. Greedy Target Encoding computes:
   - `TS(merchant_xyz) = 1 / 1 = 1.0` (100% fraud rate).
3. The GBDT tree discovers this feature and creates an aggressive root split: `IF TS ≥ 0.90 THEN PREDICT FRAUD`.
4. The model essentially memorizes the label $y_1$ via its own feature value!
5. In production, 50 legitimate transactions arrive at `merchant_xyz`. Because the training set assigned it `TS = 1.0`, the model flags or declines all 50 legitimate customers—causing catastrophic False Positives and merchant attrition.

Even with Out-of-Fold (K-fold) target encoding, **conditional shift** persists: the distribution of target statistics computed on training subsets diverges systematically from the distribution computed on the full holdout/test set.

---

### CatBoost Ordered Target Encoding (Ordered TS): The Mathematical Solution

CatBoost eliminates target leakage by introducing the **Online Sequential Principle** paired with **Random Permutations**.

```
Training Instances: [ x_1, x_2, x_3, ..., x_n ]
                         │
                         ▼
Generate S Independent Random Permutations: σ_1, σ_2, ..., σ_S
                         │
                         ▼
For sample i under permutation σ_s:
Compute Target Statistic using ONLY instances that PRECEDES sample i:
{ j : σ_s(j) < σ_s(i) }
                         │
                         ▼
Instance i's OWN label y_i is STRICTLY EXCLUDED from its own feature!
```

#### 1. The Mathematical Formulation of Ordered TS
Let `σ = (σ_1, ..., σ_n)` be a random permutation of the training set. For sample `i` with categorical value `x_i = c`, its Ordered Target Statistic `Ordered_TS(x_i)` is computed strictly using samples that precede `i` in permutation `σ`:

> **Ordered_TS(x_i) = [ Σ_{j: σ(j) < σ(i), x_j = c} y_j + (a × p) ] / [ Σ_{j: σ(j) < σ(i), x_j = c} 1 + a ]**

Where:
- `Σ_{j: σ(j) < σ(i), x_j = c} y_j`: Count of fraudulent transactions for category `c` observed **strictly before** sample `i` in permutation `σ`.
- `Σ_{j: σ(j) < σ(i), x_j = c} 1`: Total count of transactions for category `c` observed **strictly before** sample `i` in permutation `σ`.
- `p`: The **global prior** (the overall baseline fraud rate across the entire training dataset, e.g., 0.0005 or 0.05%).
- `a`: The **prior weight / smoothing parameter** (Laplace smoothing, typically set between 1.0 and 5.0).
- **Sample `i`'s own label `y_i` is completely excluded** from both the numerator and denominator!

#### 2. Numerical Walkthrough with Prior Smoothing:
Let global prior fraud rate `p = 0.001` (0.1%), smoothing weight `a = 2.0`.
- **First time a merchant appears in the permutation** (count = 0):
  - `Ordered_TS = [ 0 + (2.0 × 0.001) ] / [ 0 + 2.0 ] = 0.001`
  - It cleanly defaults to the **global prior**! Zero target leakage.
- **Second time it appears after 1 fraud event** (count = 1, fraud = 1):
  - `Ordered_TS = [ 1 + (2.0 × 0.001) ] / [ 1 + 2.0 ] = 1.002 / 3.0 = 0.334`
  - Instead of spiking to 1.0, the smoothing parameter pulls the estimate toward the global baseline, preventing leaf memorization.
- **High-volume mature merchant** (1,000 transactions, 2 fraud):
  - `Ordered_TS = [ 2 + (2.0 × 0.001) ] / [ 1,000 + 2.0 ] = 2.002 / 1002 ≈ 0.002`
  - The sample evidence overwhelms the prior, reflecting the true empirical risk.

#### 3. Why Multiple Permutations Are Mandatory:
If CatBoost used only a single permutation:
- Instances near the beginning of the order would have target statistics based on very few samples (high variance).
- Instances near the end would have statistics based on many samples (low variance).
- **The Solution**: CatBoost generates multiple independent random permutations (typically 4 in training). For each tree constructed in the ensemble, a different random permutation is used to calculate the Ordered TS, ensuring variance symmetry across all training samples.

---

### Dynamic On-The-Fly Feature Combinations in CatBoost

Fraud attacks rarely manifest along a single categorical dimension. Sophisticated fraud syndicates rotate individual attributes while maintaining a consistent attack footprint across **joint intersections**:
- `device_fingerprint` + `mcc_code` (Legitimate iPhone transacting at an electronics store vs. high-risk gambling MCC).
- `issuer_country` + `merchant_country` + `card_type` (Cross-border prepaid card attack).

#### How CatBoost Constructs Combinations On The Fly:
1. In standard GBDTs, modeling joint categorical interactions requires manual feature engineering (e.g., string concatenation: `df['device_mcc'] = df['device'] + '_' + df['mcc']`), causing exponential feature space explosion.
2. CatBoost combines categorical features **dynamically during tree construction**:
   - At the root split, CatBoost evaluates single features (e.g., split on `mcc_code`).
   - At subsequent split candidates within that tree branch, CatBoost automatically pairs `mcc_code` with all other categorical features in the dataset (e.g., `mcc_code + device_hash`).
   - It computes the **Ordered TS for the joint combination on the fly** for that sub-tree!
3. This allows the model to uncover subtle syndicate attack vectors without manual combinatorial feature engineering.

---

### Inference-Time Execution & Production Serving

During real-time production scoring (or testing):
1. The random permutations are no longer used.
2. The target statistic is computed over the **entire completed training dataset**:

> **Ordered_TS_production(c) = [ Σ_{j ∈ Train: x_j = c} y_j + (a × p) ] / [ Σ_{j ∈ Train: x_j = c} 1 + a ]**

3. **Discretization to Bins for Sub-Millisecond Lookup**:
   - During training, CatBoost automatically quantizes continuous Target Statistics into integer bins (e.g., 255 discrete buckets).
   - In production C++ serving (via CatBoost C++ API or ONNX), evaluating categorical features requires only an $O(1)$ hash table lookup into a pre-binned float array, adding **less than 0.2ms to inference latency**.

---

### Production CatBoost Fraud Training Recipe

```python
from catboost import CatBoostClassifier, Pool
import numpy as np

# Define high-cardinality categorical fields
categorical_cols = [
    "merchant_id", "mcc_code", "card_acceptor_id",
    "device_fingerprint_hash", "issuer_bin", "billing_postal_code"
]

# Create CatBoost Pools
train_pool = Pool(
    data=X_train,
    label=y_train,
    cat_features=categorical_cols
)

val_pool = Pool(
    data=X_val,
    label=y_val,
    cat_features=categorical_cols
)

# CatBoost parameters optimized for extreme imbalance fraud
catboost_params = {
    "iterations": 1000,
    "learning_rate": 0.03,
    "depth": 6,
    "loss_function": "Logloss",
    "eval_metric": "PR-AUC:use_weights=false",  # Always evaluate on PR-AUC
    
    # Categorical handling parameters
    "cat_features": categorical_cols,
    "one_hot_max_size": 10,       # Categories with ≤10 unique values use One-Hot
    "max_ctr_complexity": 2,      # Maximum combination depth (pairs: cat1 + cat2)
    
    # Asymmetric cost-weighting for rare fraud (e.g. 0.05% base rate)
    "auto_class_weights": "Balanced",  # or custom class_weights=[1.0, 15.0]
    
    # Regularization & Tree structure
    "l2_leaf_reg": 5.0,
    "random_strength": 0.8,       # Perturbs split scoring to prevent greedy memorization
    "early_stopping_rounds": 50,
    "random_seed": 42,
    "verbose": 100
}

# Train model with inherent Ordered Target Statistics
model = CatBoostClassifier(**catboost_params)
model.fit(train_pool, eval_set=val_pool)

# Export to standalone C++ code or ONNX model for <2ms production serving
model.save_model("catboost_fraud_model.cbm")
model.export_model("catboost_fraud_model.onnx", format="onnx")
```

---

### Production Feature Selection Pipeline

In high-throughput risk engines, every additional feature increases Redis memory consumption and network serialization latency. An optimal fraud model uses **30 to 60 high-impact, orthogonal features**.

```
Raw Candidate Feature Pool (300+ features)
                    │
                    ▼
[ Stage 1: Fast Filter Pruning ]
  ├── Drop features with missingness > 60%
  ├── Drop low-variance features (variance < 0.001)
  └── Information Value (IV) filter: Keep IV ≥ 0.05
                    │
                    ▼
[ Stage 2: Collinearity & VIF Pruning ]
  ├── Spearman Rank Correlation: Drop collinear pairs (r > 0.85)
  └── Variance Inflation Factor (VIF): Prune features with VIF > 5.0
                    │
                    ▼
[ Stage 3: Out-of-Time (OOT) Permutation & SHAP Selection ]
  ├── Train baseline LightGBM / XGBoost
  ├── Compute TreeSHAP mean absolute values on Out-of-Time holdout
  └── Retain top 50 features contributing 95% cumulative SHAP importance
                    │
                    ▼
[ Stage 4: Feature Stability & Drift Screening ]
  └── Characteristic Stability Index (CSI): Drop features with historical monthly CSI > 0.15
                    │
                    ▼
Final Production Feature Set (35 - 50 Features)
```

---

## 3. Hyperparameter Tuning Deep Dive for Fraud GBDTs

Under extreme class imbalance (fraud rate 0.01% – 0.1%), default hyperparameters in XGBoost, LightGBM, and CatBoost will fail. The model will converge toward predicting the majority class (99.9% legitimate) to minimize standard log-loss.

### Key Hyperparameters & Production Tuning Guidelines

| Hyperparameter | LightGBM Name | XGBoost Name | Default Value | Fraud Production Recommendation | Engineering Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Class Weight** | `scale_pos_weight` | `scale_pos_weight` | `1.0` | **`5.0` to `20.0`** (NOT full ratio!) | Setting to full ratio (e.g., 1000.0) destroys precision and blows up False Positives. A moderate weight gives fraud gradients enough signal without flooding operations queues. |
| **Tree Depth** | `max_depth` | `max_depth` | `-1` / `6` | **`4` to `7`** | Deep trees memorize specific cardholder IDs or transient fraud batches. Shallow trees enforce generalizable risk boundaries. |
| **Number of Leaves** | `num_leaves` | N/A | `31` | **`20` to `63`** | In LightGBM, `num_leaves < 2^(max_depth)` prevents leaf-wise overfitting in sparse categorical regions. |
| **Min Child Weight** | `min_child_samples` | `min_child_weight` | `20` / `1` | **`50` to `300`** | Crucial! Ensures a tree leaf must contain at least 50–300 samples before a split is approved. Prevents isolated leaves dedicated to single fraud attacks. |
| **Column Subsample** | `feature_fraction` | `colsample_bytree` | `1.0` | **`0.6` to `0.8`** | Decorrelates individual trees. Prevents dominant features (e.g., transaction amount) from masking subtle behavioral features. |
| **Row Subsample** | `bagging_fraction` | `subsample` | `1.0` | **`0.7` to `0.8`** | Introduces stochastic bagging variance reduction, preventing overfitting on repetitive legitimate merchant transactions. |
| **Learning Rate** | `learning_rate` | `learning_rate` | `0.1` | **`0.01` to `0.03`** | Smaller learning rates paired with early stopping yield smoother decision manifolds and more stable probability calibration. |
| **L1 Regularization** | `reg_alpha` | `reg_alpha` | `0.0` | **`0.1` to `5.0`** | Encourages feature sparsity; naturally sets coefficients of noisy or redundant categorical indicators to zero. |
| **L2 Regularization** | `reg_lambda` | `reg_lambda` | `0.0` / `1.0` | **`1.0` to `10.0`** | Penalizes extreme leaf weights, preventing extreme probability spikes on rare feature combinations. |

---

### Asymmetric Custom Loss Functions

Instead of relying on heuristic sample re-weighting (`scale_pos_weight`), production systems implement **custom loss functions** directly encoding business economics into the gradient updates.

#### 1. Asymmetric Cost-Sensitive Log-Loss
Assigns distinct business costs to False Negatives ($c_{FN}$, e.g., $150 chargeback loss) versus False Positives ($c_{FP}$, e.g., $3 review/friction cost):

> **Loss_cost = Σ [ - c_FN × y_i × ln(p_i) - c_FP × (1 - y_i) × ln(1 - p_i) ]**

To feed this loss into LightGBM or XGBoost, compute the first derivative (**gradient $g_i$**) and second derivative (**hessian $h_i$**) with respect to the raw margin output $z_i$ (where $p_i = \sigma(z_i)$):

> **Gradient (g_i) = p_i × [ y_i × (c_FP - c_FN) + c_FP ] - (y_i × c_FN)**  
> **Hessian (h_i) = p_i × (1 - p_i) × [ y_i × (c_FN - c_FP) + c_FP ]**

#### 2. Focal Loss for Extreme Rarity
Focal loss dynamically scales cross-entropy based on how difficult an example is to classify, preventing the overwhelming sea of easy legitimate transactions from dominating gradient updates:

> **FL(p_t) = - α_t × (1 - p_t)^γ × ln(p_t)**

- `γ` (Focusing Parameter): Typically set to **`2.0`**. When an easy negative has $p_t \approx 0.99$, $(1 - 0.99)^2 = 0.0001$, scaling down its gradient impact by a factor of 10,000!
- `α_t` (Class Balance Factor): Set to **`0.25` – `0.75`** to adjust baseline class priority.

---

### Automated Hyperparameter Optimization with Optuna

Grid search is computationally prohibitive, and random search is inefficient for complex tree ensembles. The production standard is **Bayesian Optimization using Tree-structured Parzen Estimators (TPE)** via Optuna.

#### Key Optimization Guidelines:
1. **Never Optimize on ROC-AUC**: A model can achieve 0.98 ROC-AUC while having terrible precision at low false positive rates.
2. **Optimize on Business Metrics**: Use **Recall at a Fixed False Positive Rate** (e.g., *Maximize Recall at FPR = 0.5%*) or **Net Dollar Savings**.
3. **Walk-Forward Validation**: Evaluate objective trials on an Out-of-Time (OOT) validation cohort to ensure temporal stability.

#### Python Implementation Recipe:

```python
import optuna
import lightgbm as lgb
import numpy as np
from sklearn.metrics import precision_recall_curve

def evaluate_recall_at_fixed_fpr(y_true, y_pred_probs, target_fpr=0.005):
    """
    Computes fraud recall when the False Positive Rate is capped at exactly 0.5%
    (e.g., Operations can only review 5 false alarms per 1,000 legitimate transactions).
    """
    # Sort instances by predicted fraud probability descending
    desc_order = np.argsort(y_pred_probs)[::-1]
    y_true_sorted = y_true[desc_order]
    
    negatives = (y_true == 0).sum()
    positives = (y_true == 1).sum()
    
    # Cumulative false alarms and true fraud captures
    cum_fp = np.cumsum(y_true_sorted == 0)
    cum_tp = np.cumsum(y_true_sorted == 1)
    
    # Find cutoff index where FPR reaches target_fpr
    max_fp_allowed = int(target_fpr * negatives)
    cutoff_idx = np.searchsorted(cum_fp, max_fp_allowed)
    cutoff_idx = min(cutoff_idx, len(y_true) - 1)
    
    recall_at_fpr = cum_tp[cutoff_idx] / positives
    return recall_at_fpr

def objective(trial, X_train, y_train, X_val, y_val):
    params = {
        "objective": "binary",
        "metric": "auc_mu",
        "boosting_type": "gbdt",
        "n_estimators": 800,
        "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.05, log=True),
        "max_depth": trial.suggest_int("max_depth", 4, 8),
        "num_leaves": trial.suggest_int("num_leaves", 15, 63),
        "min_child_samples": trial.suggest_int("min_child_samples", 50, 300),
        "subsample": trial.suggest_float("subsample", 0.6, 0.9),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 0.9),
        "reg_alpha": trial.suggest_float("reg_alpha", 0.01, 10.0, log=True),
        "reg_lambda": trial.suggest_float("reg_lambda", 0.1, 20.0, log=True),
        "scale_pos_weight": trial.suggest_float("scale_pos_weight", 3.0, 25.0),
        "n_jobs": -1,
        "random_state": 42
    }
    
    model = lgb.LGBMClassifier(**params)
    model.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        callbacks=[lgb.early_stopping(stopping_rounds=40, verbose=False)]
    )
    
    val_preds = model.predict_proba(X_val)[:, 1]
    score = evaluate_recall_at_fixed_fpr(y_val.values, val_preds, target_fpr=0.005)
    return score

# Run 100 trials using Tree-structured Parzen Estimator (TPE)
# study = optuna.create_study(direction="maximize", sampler=optuna.samplers.TPESampler(seed=42))
# study.optimize(lambda trial: objective(trial, X_train, y_train, X_val, y_val), n_trials=100)
```

---

## 4. Cost-Sensitive Thresholding & Multi-Tier Routing

Once the model predicts calibrated fraud probabilities $P(\text{Fraud} \mid X)$, the business must establish operating cutoffs.

### Analytical Threshold Derivation

Let:
- $L_{\text{FN}}$: Loss when fraud is missed (Chargeback dollar amount + scheme network fines, e.g., $150).
- $C_{\text{FP}}$: Cost when legitimate transaction is declined (Customer friction + lost interchange profit, e.g., $5).

The expected financial loss of deciding to Approve versus Decline:
- Expected Loss of **Approve** = $P(\text{Fraud}) \times L_{\text{FN}}$
- Expected Loss of **Decline** = $(1 - P(\text{Fraud})) \times C_{\text{FP}}$

A transaction should be declined when the Expected Loss of Approving exceeds the Expected Loss of Declining:
> **P(Fraud) × L_FN ≥ (1 - P(Fraud)) × C_FP**  
> **P(Fraud) × [ L_FN + C_FP ] ≥ C_FP**

The theoretical cost-optimal cutoff is:

> **Threshold_optimal = C_FP / [ C_FP + L_FN ]**

*Example*: If $C_{\text{FP}} = \$3.00$ and $L_{\text{FN}} = \$147.00$:
> **Threshold_optimal = \$3 / (\$3 + \$147) = 3 / 150 = 0.02 (2.0%)**

Any transaction with a calibrated fraud probability $\ge 2.0\%$ should be intervened upon.

---

### Three-Tier Operational Routing Architecture

In modern fintech, models do not merely binary approve or decline; they route transactions through a **three-tier risk cascade**:

```
[ Predicted Calibrated P(Fraud) ]
                 │
                 ├── P(Fraud) < 0.5% ─────────► [ Tier 1: Auto-Approve ] (98.5% volume)
                 │                              Seamless frictionless checkout
                 │
                 ├── 0.5% ≤ P(Fraud) < 5.0% ──► [ Tier 2: Step-Up Challenge ] (1.2% volume)
                 │                              Trigger 3DS 2.0 SMS OTP / Passkey
                 │                              • Success ──► Approved
                 │                              • Fail / Abandon ──► Declined
                 │
                 └── P(Fraud) ≥ 5.0% ─────────► [ Tier 3: Hard Block ] (0.3% volume)
                                                Direct issuer decline; block card/device
```

- **Tier 1 (Frictionless Auto-Approve)**: Captures 98%+ of legitimate volume without user annoyance.
- **Tier 2 (Step-Up Verification)**: Balances customer experience and security. Legitimate users pass in seconds via biometric FaceID/SMS OTP, while automated bots and stolen card fraud rings abandon checkout.
- **Tier 3 (Automated Hard Block)**: Reserve hard declines strictly for extreme fraud probabilities to minimize embarrassing False Declines at checkout.

---

## 5. Sub-5ms Low-Latency Model Serving (Treelite / ONNX)

Standard Python/Scikit-Learn/LightGBM model inference takes 10–25ms due to Python runtime overhead, pointer chasing across decision tree nodes, and GIL locking. This is unacceptable inside a 40ms payment gateway budget.

### The Compilation Solution: Treelite
Treelite compiles tree ensembles into **branchless, self-contained C code or native shared libraries (`.so` / `.dylib`)**:

```
Trained LightGBM / XGBoost Model (JSON / Model file)
                      │
                      ▼
       [ Treelite Compiler Engine ]
                      │
                      ▼
Generated C Code (Loops converted to hardcoded nested IF-THEN / Bitwise operations)
                      │
                      ▼
    [ Clang / GCC Native Compilation (-O3) ]
                      │
                      ▼
   High-Performance Native Shared Object (libmodel.so)
   - Inference Latency: < 0.8ms per transaction
   - Zero Python Runtime Overhead
   - Multi-threaded C++ / Rust microservice embedding
```

#### Compilation Workflow:
```python
import treelite
import treelite_runtime

# 1. Ingest trained LightGBM model
model = treelite.Model.load("fraud_lgbm_model.txt", model_format="lightgbm")

# 2. Compile to native C code package
model.export(
    toolchain="gcc",
    libpath="./libfraud_model.so",
    params={"parallel_comp": 8, "quantize": 1}
)

# 3. Load inside production low-latency serving container
predictor = treelite_runtime.Predictor("./libfraud_model.so", nthread=1)
# Benchmark: ~0.4ms per batch of 1 transaction on commodity x86 CPU!
```

---

## 6. Delayed Feedback & Continuous Model Retraining

The most deceptive aspect of fraud machine learning is **Label Lag**.

### The Label Delay Phenomenon
- When a fraudulent transaction occurs today, the cardholder does not notice until their monthly statement arrives.
- The dispute is filed, submitted to the issuer, and processed via Visa/Mastercard chargeback networks (**TC40 / SAFE reports**).
- **Average label maturation lag is 30 to 90 days!**

```
Transaction Date (Day 0) ──► First 14 Days: 90% of fraud is UNLABELED (Appears Legit!)
                                └──► Day 30: ~50% of chargebacks received
                                      └──► Day 60: ~85% of chargebacks received
                                            └──► Day 90: Mature labels (100%)
```

### Production Strategies for Label Delay:

1. **The Mature Observation Window (Lagged Training)**:
   - Train supervised models strictly on transactions that are **older than 60–90 days**, ensuring the Good vs. Bad label distribution has matured.
2. **Semi-Supervised / Positive-Unlabeled (PU) Learning**:
   - For transactions in the recent 14-day window:
     - Confirmed fraud ($Y = 1$) is a reliable positive label.
     - Unconfirmed transactions are treated as **unlabeled**, not confirmed negatives ($Y = 0$).
     - Apply Elkan-Noto PU learning or EM-based re-weighting to update models on recent data without mislabeling undiscovered fraud.
3. **Shadow Mode & Canary Rollout**:
   - Never replace a live fraud model instantaneously.
   - Run the new candidate model in **Shadow Mode** for 14 days, scoring live production traffic in parallel without taking automated actions.
   - Compare score distributions, correlation with the production champion model, and early fraud alert velocity.
   - Ramp up traffic: `5%` $\to$ `20%` $\to$ `50%` $\to$ `100%`.

---

## 7. Model Monitoring & Production Kill-Switches

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Production Health Dashboard                     │
├───────────────────────┬────────────────────────┬───────────────────────┤
│ Metric                │ Normal Operational Band│ Alert Trigger / Action│
├───────────────────────┼────────────────────────┼───────────────────────┤
│ **Population Drift**  │ PSI < 0.10             │ PSI ≥ 0.25: Trigger   │
│                       │                        │ emergency review      │
│ **Inference Latency** │ P99 < 5ms              │ P99 > 15ms: Bypass to │
│                       │                        │ lightweight fallback  │
│ **Alert Approval Rate**│ 97.5% – 98.5%         │ Drop below 96.0%:     │
│                       │                        │ Review queue flood    │
│ **Top Feature CSI**   │ CSI < 0.10             │ CSI > 0.20: Pipeline  │
│                       │                        │ upstream bug check    │
└───────────────────────┴────────────────────────┴───────────────────────┘
```

### Emergency Rule Kill-Switch (Circuit Breakers)
If the primary ML scoring engine exceeds timeout thresholds (> 15ms) or crashes due to unexpected data types, the architecture must execute a **graceful fallback**:
1. Fall back to a cached deterministic rule engine (e.g., Velocity checks, Geo-blocking, High-risk country rules).
2. Never default to hard-declining all traffic during a model outage (which destroys merchant revenue); default to conservative rule filtering.
