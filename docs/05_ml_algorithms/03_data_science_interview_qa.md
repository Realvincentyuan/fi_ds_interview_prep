# Data Science Interview Questions & Answers: Finance, Risk & Payments

A curated master collection of 15 high-frequency, rigorous data science and machine learning interview questions asked at top financial institutions (**Capital One, JPMorgan Chase, American Express, Stripe, Visa, Wise, Apple Pay**).

---

## Question 1: Why do banks still use Logistic Regression + WOE instead of XGBoost or Deep Learning for credit card underwriting?

### Interviewer's Intent:
Tests whether the candidate understands the difference between theoretical academic ML performance (Kaggle/AUC) and real-world banking regulations, model risk management (**SR 11-7**), and legal requirements (**FCRA / ECOA**).

### Comprehensive Answer:
While XGBoost or neural networks can deliver a 1–3% lift in ROC-AUC, tier-1 retail banks still rely on **Weight of Evidence (WOE) transformed Logistic Regression** for consumer credit underwriting due to three non-negotiable regulatory and operational imperatives:

1. **Adverse Action Notices (FCRA & Equal Credit Opportunity Act - Reg B)**:
   - Federal law dictates that if an applicant is denied credit or offered sub-optimal terms, the bank must provide the applicant with the **top 4 principal reasons** for the adverse action (e.g., *"Number of delinquent accounts in past 24 months"*, *"Proportion of balances to credit limits too high"*).
   - In a WOE Logistic Regression scorecard, each feature bin translates to an exact additive point deduction:
     > **Bin Points = Factor × β_j × WOE_ij**
   - The bank can mathematically prove the exact factors that pulled the applicant below the cutoff. In complex black-box models or even post-hoc SHAP explainers, explanations can suffer from instability, correlation confounding, and non-deterministic baseline attribution, creating substantial legal liability.

2. **Guaranteed Monotonicity & Economic Intuition**:
   - Regulatory examiners (Federal Reserve, OCC, CFPB) mandate that risk models exhibit **strict monotonicity**. As a borrower's revolving credit utilization increases from 20% to 90%, the modeled default risk *must strictly increase*.
   - In decision trees, splits in low-sample regions can create localized reversals (e.g., a tiny tree leaf predicting 85% utilization is safer than 70% utilization due to sample noise). Coarse binning and monotonic WOE transformations guarantee economic sanity across all feature domains.

3. **Model Risk Management & Audit Defense (SR 11-7)**:
   - Under Federal Reserve SR 11-7, banks must document every step of the model's conceptual soundness, developmental evidence, and coefficient stability. A linear logistic regression with 15–20 orthogonal binned features can be fully validated, stress-tested, and audited by internal model governance teams and external regulators.

### Executive Talking Script:
> *"In consumer credit, AUC is secondary to legal compliance and regulatory defensibility. Under the Fair Credit Reporting Act, we are legally required to provide 4 adverse action reason codes for rejected applicants. A WOE scorecard offers deterministic, additive point attributions that are legally auditable. Furthermore, coarse binning guarantees monotonicity—preventing localized non-sensical predictions that raw tree algorithms produce in sparse feature regions. While we use XGBoost extensively for fraud and marketing, core underwriting remains anchored in scorecards or monotonically constrained GAMs."*

---

## Question 2: In fraud detection, the fraud rate is often 0.01% (extreme imbalance). Why is SMOTE dangerous in payment transactions, and how should you address imbalance in production?

### Interviewer's Intent:
Detects junior candidates who recite textbook rescoring techniques (SMOTE, random oversampling) without understanding high-dimensional sparse tabular data, training-serving skew, and business cost functions.

### Comprehensive Answer:

#### Why SMOTE (Synthetic Minority Over-sampling Technique) is Dangerous:
1. **Creates Hallucinated, Impossible Financial Combinations**:
   - SMOTE interpolates between $k$-nearest neighbors in continuous Euclidean space:
     > **x_new = x_i + λ × (x_k - x_i), where λ ∈ [0, 1]**
   - Payment features are heavily discrete, categorical, or power-law distributed (Merchant Category Codes, ZIP codes, device IDs, discrete transaction amounts). Interpolating between a $2,000 electronics purchase in New York and a $5 coffee in London creates synthetic transactions at non-existent coordinates with physically impossible attributes.
2. **Distorts Graph and Entity Topologies**:
   - In modern fraud architectures, entity resolution links transactions via IP subnets, cardholder IDs, and device fingerprints. SMOTE synthesizes isolated feature vectors that break relational graph consistency.
3. **Severe Probability Distortion**:
   - Artificially inflating fraud from 0.01% to 10% or 50% severely distorts the posterior probability calibration $P(Y=1 \mid X)$. When deployed in production against the true 0.01% base rate, the model produces a catastrophic wave of False Positives, overwhelming fraud operations review queues.

#### What to Do Instead in Production:
1. **Cost-Sensitive Asymmetric Loss**:
   - Optimize the model directly on business dollars rather than binary accuracy by weighting False Negatives (fraud losses) significantly higher than False Positives (customer friction):
     > **Weight_pos = Cost(FN) / Cost(FP)**
2. **Precision-Recall Curve (PR-AUC) Threshold Tuning**:
   - Never use default 0.5 probability cutoffs. Calibrate the decision threshold on a holdout set to maximize the net economic value:
     > **Net Value = Captured Fraud Dollars - False Positive Review Costs - Customer Churn Penalty**
3. **Focal Loss**:
   - Down-weights easy, well-classified negative transactions and focuses gradient updates on hard, ambiguous edge cases:
     > **FL(p_t) = - α_t × (1 - p_t)^γ × ln(p_t)**
4. **Controlled Negative Downsampling with Odds-Ratio Recalibration**:
   - Downsample legitimate transactions by factor $\beta$ (e.g., keep 10% of legit transactions to speed up training), but **mathematically correct the predicted probabilities** at inference time using Bayes' rule:
     > **p_calibrated = p_sample / [ p_sample + ( (1 - p_sample) / β ) ]**

---

## Question 3: Walk through the formula for Population Stability Index (PSI). What do PSI values mean, and how do you diagnose the root cause when PSI spikes above 0.25?

### Interviewer's Intent:
Evaluates whether the candidate has production monitoring experience under bank Model Risk Governance guidelines.

### Comprehensive Answer:

#### Mathematical Formulation:
PSI measures the divergence between the development/baseline distribution (**Expected**) and the current production distribution (**Actual**) across $B$ predefined score or feature buckets (typically 10 deciles):

> **PSI = Σ_{i=1}^B [ (Actual_i - Expected_i) × ln( Actual_i / Expected_i ) ]**

- `Actual_i`: Percentage of current production accounts falling into bucket $i$.
- `Expected_i`: Percentage of development/baseline accounts falling into bucket $i$.

#### Regulatory Interpretation Thresholds:
| PSI Value | Status | Operational Action |
| :--- | :--- | :--- |
| **PSI < 0.10** | **Stable** | No action required; model operating within expected parameters. |
| **0.10 ≤ PSI < 0.25** | **Moderate Shift** | Warning threshold. Increase monitoring frequency; analyze sub-populations. |
| **PSI ≥ 0.25** | **Severe Shift** | **Action required.** Freeze automated limit increases, recalibrate, or revert to conservative policy rules. |

#### Root Cause Diagnostic Workflow when PSI > 0.25:
1. **Decompose to Characteristic Stability Index (CSI)**:
   - Calculate PSI for *each individual input feature* (known as CSI).
   - If model PSI is 0.28, but only one feature (e.g., `revolving_utilization_6m`) has a CSI of 0.45 while other features have CSI < 0.05, the shift is isolated to that specific attribute.
2. **Distinguish Macroeconomic Shift vs. Upstream Pipeline Corruption**:
   - **Pipeline Bug**: Did an upstream bureau vendor change null value encoding (e.g., from `-999` to `NULL`)? Did a mobile app update drop device fingerprint tracking?
   - **Macroeconomic Shock**: Did interest rates rise or inflation surge, shifting the true national distribution of debt-to-income?
   - **Portfolio Mix Shift**: Did marketing launch a promotional campaign targeting a new subprime customer segment?
3. **Evaluate Discrimination Degradation (KS & AUC)**:
   - Check if the **Kolmogorov-Smirnov (KS)** statistic and AUC remained stable. If the distribution shifted (high PSI) but the model still separates goods from bads with high KS, the model may only require threshold recalibration rather than full retraining.

---

## Question 4: Why can standard GBDT Feature Importance (Gain or Split Count) be dangerously misleading, and how does TreeSHAP solve this?

### Interviewer's Intent:
Tests deep understanding of tree-based interpretability, feature attribution biases, and cooperative game theory.

### Comprehensive Answer:

#### Biases in Traditional GBDT Importance:
1. **Split Count (Weight / Frequency)**:
   - Simply counts how many times a feature is split on across all trees.
   - **Bias**: Strongly favors continuous features with high cardinality or noisy attributes that provide negligible variance reduction on each split, while penalizing powerful binary features that split decisively at tree roots.
2. **Gain (Gini / Variance Reduction)**:
   - Measures total improvement in accuracy brought by a feature to the branches it is on.
   - **Inconsistency Property**: If a model changes such that a feature increases its impact on the output, traditional Gain importance can paradoxically *decrease*! (Demonstrated by Lundberg & Lee, 2017).
   - **Masking / Correlation Confounding**: When two features are correlated (e.g., `annual_income` and `monthly_salary`), the tree may arbitrarily pick one at the top split and suppress the gain of the other, making the second feature look completely unimportant.

#### How TreeSHAP Solves This:
TreeSHAP is grounded in cooperative game theory (Shapley values), distributing total payout (model prediction) among players (features) according to their marginal contributions across all possible subsets $S$:

> **φ_i = Σ_{S ⊆ F \ {i}} [ |S|! (|F| - |S| - 1)! / |F|! ] × [ f(S ∪ {i}) - f(S) ]**

TreeSHAP uniquely satisfies four mathematical axioms required for regulatory defensibility:
1. **Efficiency**: The sum of SHAP values across all features equals the difference between model output and expected base value: **Σ φ_i = f(x) - E[f(x)]**.
2. **Symmetry**: If two features contribute equally to all possible feature coalitions, their SHAP values are identical.
3. **Dummy Player (Null Effect)**: A feature that does not change the model prediction in any coalition receives a SHAP value of zero.
4. **Additivity / Monotonicity**: If a model is updated such that a feature's marginal contribution increases, its SHAP attribution is guaranteed to never decrease.

Furthermore, TreeSHAP optimizes the exponential $O(2^{|F|})$ subset calculation down to polynomial time **$O(T \cdot L \cdot D^2)$** (where $T$ = trees, $L$ = leaves, $D$ = maximum tree depth), making real-time exact attribution computationally feasible.

---

## Question 5: Why do raw tree models produce uncalibrated probabilities, and how do you calibrate them for expected dollar decisioning?

### Interviewer's Intent:
Evaluates understanding of probability calibration (Platt Scaling vs. Isotonic Regression) and how probability estimates tie directly into business profit and loss (P&L).

### Comprehensive Answer:

#### Why Tree Models are Uncalibrated:
1. **Sigmoid Compression & Leaf Purity Bias**: Decision tree leaves compute sample averages across a small number of instances. Ensembles push predicted probabilities away from 0.0 and 1.0 (towards intermediate values) or conversely overfit extreme leaves in deep trees.
2. **Under-sampling / Imbalanced Learning**: When training on downsampled negative datasets, the predicted score reflects the sampled distribution rather than real-world prevalence.
3. **Boosting Dynamics**: Gradient boosting optimizes rank-order (surrogate loss like log-loss or exponential loss) rather than absolute probabilistic calibration.

#### Why Accurate Calibration is Mandatory in Finance:
In finance, decision thresholds are based on **Expected Value Optimization**:
> **Expected Profit = [ P(Legit) × Cardholder_Interchange_Fee ] - [ P(Fraud) × Fraud_Loss ]**

If a model predicts `Score = 0.80`, but the empirical historical default rate for applicants with that score is actually `35%`, loan pricing, loss provisioning (CECL reserves), and approval cutoffs will be completely wrong.

#### Calibration Techniques:

1. **Platt Scaling (Sigmoid Fitting)**:
   - Fits a univariate logistic regression on top of the raw model output $f(x)$:
     > **P(Y=1 | x) = 1 / [ 1 + exp( - (A · f(x) + B) ) ]**
   - **Pros**: Non-overfitting, works with small calibration sets, preserves ranking.
   - **Cons**: Assumes the calibration error curve is strictly sigmoidal.

2. **Isotonic Regression (Piecewise Constant)**:
   - Fits a non-parametric, isotonic (monotonically non-decreasing) step function using the Pool Adjacent Violators Algorithm (PAVA).
   - **Pros**: Extremely flexible; corrects arbitrary non-linear distortion curves.
   - **Cons**: Prone to overfitting on small datasets; requires a separate, sufficiently large validation set.

3. **Evaluation via Brier Score & Reliability Diagrams**:
   - **Brier Score**: Mean squared difference between predicted probabilities and actual outcomes:
     > **BS = (1 / N) × Σ (p_i - y_i)^2**
   - **Reliability Diagram**: Bins predicted probabilities (e.g., 0.0-0.1, 0.1-0.2) and plots mean predicted probability on the X-axis against observed empirical event frequency on the Y-axis. Perfect calibration forms a 45-degree diagonal.

---

## Question 6: Walk through the complete mathematical derivation of a FICO-style Credit Scorecard from raw customer data to a 300–850 point scale.

### Interviewer's Intent:
The signature quantitative credit risk interview question at Capital One, Discover, and AmEx.

### Comprehensive Answer:

#### Step 1: Feature Binning & WOE Transformation
- For each continuous attribute (e.g., `Debt-to-Income`), perform quantile fine-binning into 20–50 buckets.
- Merge into 4–8 coarse bins ensuring monotonicity of bad rates and minimum 5% sample representation.
- Calculate Weight of Evidence for each bin $i$:
  > **WOE_i = ln( (G_i / G_total) / (B_i / B_total) )**

#### Step 2: Logistic Regression Modeling
- Fit regularized logistic regression on the transformed WOE variables:
  > **ln(Odds) = ln( P(Good) / P(Bad) ) = β_0 + β_1 WOE_1 + β_2 WOE_2 + ... + β_k WOE_k**
- Constrain all coefficients $\beta_j > 0$ to guarantee that higher points always align with favorable risk.

#### Step 3: Deriving the Scaling Equation
We desire a linear mapping from log-odds to integer score points:
> **Score = Offset + Factor × ln(Odds)**

The bank establishes two commercial anchor points:
1. **Target Score ($S_0$)** at **Target Odds ($O_0$)**: e.g., Score = 600 at Odds = 50:1.
2. **Points to Double the Odds (PDO)**: Score increases by $PDO$ (e.g., 20 points) when Odds double ($2 \times O_0$):
   > **Score + PDO = Offset + Factor × ln(2 × Odds) = Offset + Factor × [ ln(Odds) + ln(2) ]**

Subtracting the base score equation:
> **PDO = Factor × ln(2)  ==>  Factor = PDO / ln(2)**

Substituting back to solve for Offset:
> **Offset = S_0 - Factor × ln(O_0)**

#### Step 4: Decomposing into Scorecard Table
Substitute the logistic regression formula into the score equation:
> **Score = Offset + Factor × [ β_0 + Σ (β_j × WOE_j) ]**
> **Score = [ Offset + Factor × β_0 ] + Σ [ Factor × β_j × WOE_j ]**

- **Base Score Points** = `Offset + Factor × β_0`
- **Bin Points for Feature $j$, Bin $i$** = `Factor × β_j × WOE_ij`

The credit evaluation engine simply adds integer points from lookup tables for each applicant attribute, summing directly to the final consumer credit score (e.g., 724).

---

## Question 7: How do you detect synthetic identity theft and organized fraud rings that evade single-transaction classifiers?

### Interviewer's Intent:
Tests whether the candidate understands relational network architectures, entity resolution, and graph algorithms beyond standard tabular feature engineering.

### Comprehensive Answer:

#### Why Single-Transaction Classifiers Fail:
Synthetic identity fraudsters fabricate personas by combining real SSNs (often stolen from children or deceased individuals) with fictitious names, addresses, and phone numbers. They systematically "nurture" credit profiles over 12–24 months by paying small balances on time to build prime FICO scores, before orchestrating a synchronized **"bust-out"** (maxing out multiple lines of credit simultaneously and vanishing). Each individual transaction appears entirely normal.

#### 3-Pillar Graph & Entity Resolution Defense:

```
[ Ingest Identity & Device Telemetry ]
               │
               ▼
1. Deterministic & Probabilistic Entity Resolution (Address, Phone, Device, SSN)
               │
               ▼
2. Graph Topology Construction (Heterogeneous Nodes & Edges)
               │
               ▼
3. Graph Algorithms & GNN Scoring
   ├── Cyclic Fund Flow Detection (Circular AML Layering)
   ├── High-Degree Hub Detection (Shared Device / P.O. Box Multiplexing)
   └── GraphSAGE / RGCN Embeddings for Unseen Node Risk Propagation
```

1. **Entity Resolution & Identity Graph Construction**:
   - Construct a heterogeneous bipartite graph:
     - **Entity Nodes**: Cardholder ID, SSN, Device Hash, Bank Account, Physical Address, IP Subnet.
     - **Edges**: `authorized_user_on`, `accessed_from_device`, `shares_physical_address`, `transferred_funds_to`.
2. **Graph Metric Feature Extraction**:
   - **Degree Centrality**: Sudden spike in distinct SSNs linking to a single physical device IMEI indicates a fraud factory.
   - **Authorized User Piggybacking Clusters**: Fraud syndicates sell "tradelines" to boost synthetic credit scores. A credit card account with 40+ unrelated authorized users is a known bust-out indicator.
   - **Directed Cycle Detection**: Uncovers circular layering schemes ($A \to B \to C \to A$) used to artificially inflate merchant processing volume or wash illicit funds.
3. **Inductive Graph Neural Networks (GraphSAGE / RGCN)**:
   - Propagate embeddings across multi-hop neighborhoods. If an account has clean bureau metrics but is 2 hops away from confirmed bust-out syndicates in the shared device graph, the GNN embedding captures this network risk and flags the account for enhanced manual review.

---

## Question 8: How do you validate a model under Federal Reserve SR 11-7 / OCC 2011-12 guidance?

### Interviewer's Intent:
Essential governance question for any Senior Data Scientist, Quantitative Risk Analyst, or Risk Product Manager at a US regulated financial institution.

### Comprehensive Answer:
Federal Reserve Supervisory Letter **SR 11-7** establishes that model risk must be managed like credit or operational risk. A robust model validation covers three mandatory core pillars:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SR 11-7 Validation Pillars                      │
├─────────────────────┬──────────────────────────┬───────────────────────┤
│ 1. Conceptual       │ 2. Ongoing               │ 3. Outcomes Analysis  │
│    Soundness        │    Monitoring            │    & Backtesting      │
├─────────────────────┼──────────────────────────┼───────────────────────┤
│ • Economic theory   │ • Population drift (PSI) │ • Backtesting on OOT  │
│ • Design rationale  │ • Feature drift (CSI)    │ • Benchmark comparison│
│ • Data integrity    │ • Override tracking      │ • Stress testing &    │
│ • Feature selection │ • Systemic bug monitoring│   sensitivity tests   │
└─────────────────────┴──────────────────────────┴───────────────────────┘
```

1. **Evaluation of Conceptual Soundness**:
   - **Economic Justification**: Does the mathematical formulation match financial theory?
   - **Design Rationale**: Why was this specific model architecture chosen over simpler alternatives?
   - **Data Quality & Selection**: Documentation of training samples, filtering criteria, proxy variables, and absence of target leakage.
   - **Monotonicity**: Validation that model behavior respects economic causality (e.g., rising delinquencies cannot increase credit limit).

2. **Ongoing Monitoring Plan**:
   - **Population Stability Index (PSI)** tracked monthly across score deciles.
   - **Characteristic Stability Index (CSI)** tracking drift on key driver features.
   - **Policy Override Monitoring**: Tracking the performance of underwriter manual overrides ("low-side" and "high-side" exceptions).

3. **Outcomes Analysis & Benchmarking**:
   - **Out-of-Time (OOT) Backtesting**: Evaluating performance on an out-of-time test cohort at least 12–18 months after the training observation window.
   - **Challenger / Benchmark Models**: Comparing the candidate model against an independent benchmark (e.g., standard FICO score or baseline logistic regression).
   - **Sensitivity & Stress Testing**: Perturbing key inputs (e.g., simulating 10% nationwide unemployment or a 300 bps interest rate hike) to evaluate capital adequacy and default surges under severe economic distress.

---

## Question 9: Why does binary classification fail for long-term loan default modeling, and how does Survival Analysis solve it?

### Interviewer's Intent:
Tests understanding of time-to-event dynamics, right-censoring, CECL accounting requirements, and loan prepayment economics.

### Comprehensive Answer:

#### The Failure of Binary Classification:
1. **Right-Censoring**: A 5-year auto loan originated 12 months ago has not defaulted *yet*. If we label it `0` (non-default), we introduce label bias because it may default in month 24. If we drop active loans, we introduce severe survivorship bias.
2. **Fixed Observation Window Fallacy**: Classifying default as a binary outcome over 12 months ignores *when* the default occurred. A loan defaulting in month 2 results in catastrophic loss; a loan defaulting in month 58 has already repaid 90% of principal plus substantial interest.
3. **Competing Risks (Prepayment vs. Default)**: In mortgages and installment loans, borrowers can exit the portfolio through two competing paths: **Default (credit loss)** or **Prepayment (loss of future interest margin)**. Binary classification cannot model competing termination hazards simultaneously.

#### The Survival Analysis Solution:
Survival analysis models the **hazard function** $\lambda(t)$—the instantaneous rate of default at time $t$ given that the borrower has survived up to time $t$:

1. **Cox Proportional Hazards Model**:
   > **λ(t | X) = λ_0(t) × exp( β_1 X_1 + β_2 X_2 + ... + β_k X_k )**
   - Semi-parametric: Separates the baseline macroeconomic hazard $\lambda_0(t)$ from individual borrower risk factors $X$.
   - Naturally handles **right-censored loans**: Active performing loans contribute valid observation time up to the current date without requiring an arbitrary default label.

2. **Application to CECL & Lifetime Expected Credit Losses**:
   - Under CECL accounting rules, banks must hold capital reserves for the **entire lifetime expected loss** of a loan at origination.
   - Survival analysis allows continuous calculation of marginal default probability in each future period:
     > **P(Default in month t) = S(t - 1) - S(t)**
   - Enabling discounted lifetime cash flow simulations across multiple macroeconomic scenarios.

---

## Question 10: How do you mathematically test for Fair Lending and Disparate Impact under ECOA? What do you do if a feature causes disparate impact?

### Interviewer's Intent:
Tests compliance knowledge of the Equal Credit Opportunity Act (ECOA), Consumer Financial Protection Bureau (CFPB) oversight, and algorithmic fairness mitigation.

### Comprehensive Answer:

#### 1. The Four-Fifths (80%) Rule & Adverse Impact Ratio (AIR)
Under federal fair lending guidelines, credit models must not produce unjustified disparate impact against protected classes (race, ethnicity, sex, age):

> **Adverse Impact Ratio (AIR) = Selection Rate (Approval Rate) of Protected Group / Selection Rate of Reference Group**

- **Rule**: If `AIR < 0.80 (80%)`, the model demonstrates prima facie evidence of **Disparate Impact**.

#### 2. Statistical Parity vs. Equalized Odds
- **Demographic / Statistical Parity**: Requires identical approval rates across groups:
  > **P(Y_pred = 1 | Group = A) = P(Y_pred = 1 | Group = B)**
  - Often commercially unviable in credit risk if underlying credit bureau profiles differ due to broader socioeconomic disparities.
- **Equal Opportunity / Equalized Odds**: Requires that false positive rates or true positive rates be equal across groups:
  > **P(Y_pred = 1 | Y_true = 1, Group = A) = P(Y_pred = 1 | Y_true = 1, Group = B)**
  - Ensures equally creditworthy applicants have identical chances of approval regardless of protected group membership.

#### 3. Remediation Workflow when a Model Fails Fair Lending Audits:
1. **Identify and Remove Proxy Variables**:
   - Even if race or gender is never included in the training data, features like `ZIP code`, `educational institution`, or `first-time homebuyer grant status` can act as high-fidelity proxies. Compute mutual information and correlation between features and protected attributes.
2. **Search for Less Discriminatory Alternatives (LDA)**:
   - Regulators require banks to search for alternative models that achieve substantially equivalent predictive power (AUC / Gini) with lower disparate impact.
3. **Adversarial Debiasing & Multi-Task Fairness Constraints**:
   - Train the primary risk model with an adversary network attempting to predict protected class from the risk score. Gradients are back-propagated with sign reversal to remove demographic correlation from internal embeddings.
4. **Fairness-Aware Threshold Optimization**:
   - Set group-specific score cutoffs that equalize approval odds for equally qualified borrowers, provided this complies with local institutional legal frameworks.

---

## Question 11: Compare ROC-AUC, PR-AUC, Brier Score, and the Kolmogorov-Smirnov (KS) Statistic. Which metric do you report to an Executive vs. a Model Validator?

### Interviewer's Intent:
Evaluates precision in metric selection based on business stakeholder vs. technical auditor requirements.

### Comprehensive Answer:

| Metric | Primary Purpose | Strengths | Major Limitation | Target Audience |
| :--- | :--- | :--- | :--- | :--- |
| **ROC-AUC** | Global discriminative ranking | Threshold-independent; invariant to class priors | Highly misleading under severe class imbalance (0.01% fraud) | Data Scientists, ML Engineers |
| **PR-AUC** | Precision vs. Recall ranking | Directly penalizes False Positives in rare-event domains | Value depends on base event rate; cannot compare across different datasets | Fraud Strategy Managers, Operations Leads |
| **KS Statistic** | Maximum separation between Good & Bad CDFs | Regulatory standard in retail credit underwriting | Focuses strictly on a single cutoff point; ignores shape elsewhere | **Model Risk Examiners (SR 11-7), Regulators** |
| **Brier Score** | Mean squared probabilistic error | Evaluates calibration accuracy of predicted probabilities | Does not evaluate rank separation directly | Quantitative Finance, Capital Reserves (CECL) |

#### Deep-Dive on the Kolmogorov-Smirnov (KS) Statistic:
The KS statistic is the universal retail banking standard for underwriting scorecards:

> **KS = max | CDF_Good(s) - CDF_Bad(s) |**

- Plotted across all score thresholds $s$.
- **Standard Scale**:
  - `KS < 20`: Inadequate separation.
  - `20 ≤ KS ≤ 40`: Standard acceptable credit card model.
  - `40 ≤ KS ≤ 60`: Strong, high-performing underwriting scorecard.
  - `KS > 60`: Unusually high; investigate potential target leakage.

### What to Report:
- **To the Executive (C-Suite / Product Head)**: Report **Dollar P&L Impact & Precision/Recall Trade-off** (*"At an approval rate of 68%, our charge-off rate is 2.1%, yielding $14M in net incremental margin"*).
- **To the Model Validator (MRM / SR 11-7 Auditor)**: Report **KS Statistic, Population Stability Index (PSI), and Brier Calibration Curve**.

---

## Question 12: How do you address Reject Inference in credit risk modeling, and why does ignoring it bias your model?

### Interviewer's Intent:
Advanced credit risk question testing understanding of sample selection bias (**Heckman correction**).

### Comprehensive Answer:

#### The Reject Inference Problem:
A bank can only observe the repayment performance (Good vs. Bad) of applicants who were **approved and booked**. By definition, applicants who were **rejected** have no performance labels.
- If you train a model strictly on accepted borrowers, you are training on a truncated, non-random sample of the population (**Sample Selection Bias**).
- When the new model is deployed to score the entire applicant pool, it will misestimate risk on marginal and near-prime applicants, systematically underestimating default probabilities in regions where previous underwriting policies rejected applicants.

#### Standard Methodologies to Solve Reject Inference:

1. **Credit Bureau Augmentation (Gold Standard)**:
   - For rejected applicants, purchase bureau performance data 12–24 months later to observe whether they defaulted on credit products obtained from *other* lenders.
   - Provides true empirical labels for rejected applicants without statistical approximations.

2. **Parceling (Proportional Weighting)**:
   - Train a base model on accepted applicants.
   - Score the rejected population using this model.
   - Divide rejected applicants into score bands. For each band, estimate the expected bad rate using accepted performance multiplied by an **Accept-to-Reject Inflation Factor** (typically 1.5x to 3.0x higher risk).
   - Randomly assign Good/Bad pseudo-labels according to this inflated bad rate, add the rejected cohort back into the training dataset with downweighted sample weights, and retrain.

3. **Bivariate Probit (Heckman Two-Stage Selection Model)**:
   - **Stage 1 (Selection Equation)**: Models the probability of being approved: `P(Approved | Z)`.
   - **Stage 2 (Outcome Equation)**: Models default risk `P(Default | X)` conditional on selection, including the Inverse Mills Ratio derived from Stage 1 to mathematically correct for sample selection correlation.

---

## Question 13: How do you design a real-time feature store pipeline for fraud detection with <50ms end-to-end SLA, and how do you prevent train-serving skew?

### Interviewer's Intent:
Tests production ML system design capabilities, low-latency streaming infrastructure, and data pipeline integrity.

### Comprehensive Answer:

```
[ Authorization Request: 40ms Total Budget ]
                     │
                     ▼
  ┌─────────────────────────────────────────────────────────┐
  │  1. In-Memory Online Feature Store (Redis / Dragonfly)   │
  │     - User 1h Velocity: 4 txns                           │
  │     - User 24h Spend: $1,420                             │
  │     - Latency: < 4ms                                    │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │  2. Compiled Model Scoring (C++ Treelite / ONNX)         │
  │     - 500 GBDT Trees                                     │
  │     - Latency: < 3ms                                    │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │  3. Rule Engine & Decision (Approve / Step-Up / Decline) │
  │     - Latency: < 2ms                                    │
  └─────────────────────────────────────────────────────────┘
```

#### Low-Latency Serving Pipeline:
1. **Dual Storage Architecture (Lambda / Kappa)**:
   - **Online Feature Store (In-Memory Key-Value: Redis / DynamoDB)**: Stores point-in-time sliding aggregations (`txns_last_10m`, `amount_ratio_30d`, `distinct_merchants_24h`). P99 lookup latency < 5ms.
   - **Offline Feature Store (BigQuery / Snowflake / Apache Iceberg)**: Stores historical transaction logs for batch model training and backtesting.
2. **Streaming Feature Engine (Apache Flink / Spark Streaming)**:
   - Processes real-time authorization event streams via Kafka.
   - Computes stateful streaming aggregations and writes updated values into the online Redis store within 100–200ms of transaction completion.

#### Preventing Train-Serving Skew:
Train-serving skew is the #1 cause of silent fraud model failure in production:
1. **Time-Travel (Point-in-Time Correctness)**:
   - When generating training features from historical logs, features for a transaction at `2026-03-15 14:22:10` must be computed strictly using data available prior to `14:22:10`. Using end-of-day summary tables introduces look-ahead data leakage.
2. **Unified Feature Definitions (Single Codebase)**:
   - Never write feature logic in SQL for training and rewrite it in Python or Java for real-time serving!
   - Use feature store frameworks (e.g., **Feast**, **Tecton**) where feature transformations are defined once and compiled into both streaming Flink jobs and batch SQL queries.
3. **Log-and-Score Architecture**:
   - Log the exact vector of feature values served to the model at real-time inference directly into the training data lake. Training models on logged inference features guarantees zero mathematical divergence.

---

## Question 14: What is Algorithmic Recourse, and how do you generate counterfactual explanations for rejected loan applicants?

### Interviewer's Intent:
Evaluates knowledge of explainable AI, regulatory consumer rights, and actionable counterfactual recommendations.

### Comprehensive Answer:

#### Definition:
**Algorithmic Recourse** provides an applicant who was rejected with an actionable, minimal set of behavioral changes that would flip the model's decision from Decline to Approve:
- *Feature Attribution (SHAP)* tells the user: *"You were declined because your revolving debt is too high."* (Diagnostic, but not actionable).
- *Algorithmic Recourse (Counterfactual)* tells the user: *"If you pay down $1,800 of credit card debt over the next 4 months, your approval probability will exceed the required 70% threshold."* (Actionable guidance).

#### Mathematical Formulation:
Find a counterfactual profile `x_recourse` that changes the prediction while minimizing the distance (cost) from the applicant's current profile `x`:

> **x_recourse = argmin_{x'} [ dist(x, x') + λ × ( f(x') - y_target )^2 ]**

Subject to three mandatory real-world constraints:
1. **Plausibility & Manifold Closeness**: The synthetic counterfactual `x_recourse` must lie within the realistic data distribution (e.g., an applicant cannot have 25 years of credit history with an age of 21).
2. **Actionability & Directionality**:
   - **Immutable Features**: Age, race, gender cannot be changed.
   - **Monotonic Non-Decreasing Features**: Credit history length can only increase; age can only increase.
   - **Actionable Features**: Outstanding balance, number of open lines, requested loan amount.
3. **Sparsity**: The recommended changes must involve at most 2–3 attributes to remain understandable and achievable for the applicant.

---

## Question 15: Why does standard k-fold cross-validation fail on financial time series, and how does Purged Group TimeSeriesSplit fix it?

### Interviewer's Intent:
Evaluates understanding of temporal dependencies, serial correlation, label leakage, and walk-forward validation in quantitative risk and algorithmic trading.

### Comprehensive Answer:

#### Why Standard K-Fold Cross-Validation Fails:
1. **Future Look-Ahead Leakage**:
   - Standard k-fold randomly shuffles samples. The model will train on data from October 2026 to predict outcomes in March 2026, leaking future macroeconomic trends, market volatility, and seasonal holiday spending patterns into past training splits.
2. **Information Leakage via Overlapping Labels (Serial Correlation)**:
   - In financial data, labels often span multi-month horizons (e.g., *"Will the borrower default within the next 90 days?"*).
   - If a training sample starts at $t_0$ and evaluates performance up to $t_0 + 90$, and a test sample starts at $t_0 + 30$, their observation windows overlap by 60 days. The model memorizes shared market shocks, producing artificially inflated validation scores that collapse in production.

#### The Purged Group TimeSeriesSplit Solution:

```
Time Axis ────────────────────────────────────────────────────────►
[ Train Fold 1: Jan - Jun ] [ Purge Window: 90d ] [ Test Fold 1: Oct - Dec ]
                                  ▲
                                  │
      (Prevents label overlap between training and testing events)
```

1. **Walk-Forward Expanding / Rolling Window**:
   - Training folds strictly precede testing folds in chronological order.
2. **Purging**:
   - Removes training labels whose evaluation period overlaps with the beginning of the test set:
     > **Drop training instances where: End_Date(train) ≥ Start_Date(test)**
3. **Embargoing**:
   - When test folds precede subsequent train folds, auto-correlation in feature state can leak backward. An embargo buffer (e.g., 30–60 days) is introduced immediately after the test window before resuming training sample collection.
4. **Grouped by Entity (Cardholder / Merchant)**:
   - All transactions from a given entity must reside strictly within a single fold to prevent identity memorization across splits.
