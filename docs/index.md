# Financial Technology & AI Interview Preparation Hub

> **Target Companies & Roles**: Capital One / PULSE, Wise, Tencent (Tenpay Global), Stripe, Adyen, Visa, Mastercard, American Express, PayPal, Block/Square, and Tier-1 Tech Risk & Analytics Teams.  
> **Target Positions**: Senior Business Manager (Fraud Operations Strategy), Director of Product Analytics, Financial Crime Risk Control Manager, Machine Learning Engineer (Risk/Fraud), Data Scientist, Quantitative Risk Analyst, Product/Data Analyst, Financial Systems Architect, AI Engineer.

---

## 📌 Repository Architecture & Navigation

This repository is organized into dedicated modular domains covering technical concepts, mathematical formulations, production architectures, system design cases, and application management:

```
fi_ds_interview_prep/
├── 01_payment_systems_and_networks/    # Payment Rails, 4-Party Model, Clearing & Settlement, ISO 8583
├── 02_fraud_detection_and_risk/        # Real-Time Fraud Engines, Feature Streaming, Class Imbalance
├── 03_data_analytics/                  # Fintech Metrics, Advanced SQL Patterns, A/B Testing & CUPED
├── 04_ai_fundamentals/                 # Transformers, Enterprise RAG, AI Agents, Compliance & Explainability
├── 05_ml_algorithms/                   # GBDT, Credit Scorecards (WOE), Anomaly Detection, Calibration
├── 06_case_studies/                    # End-to-End System Design & Business Analytics Case Studies
│   ├── case_01_realtime_fraud_detection.md
│   └── case_02_payment_routing_authorization.md
└── company_research/                   # Company-Specific Interview Dossiers & Strategic Intel
    ├── pulse_capital_one/
    │   ├── README.md
    │   └── senior_business_manager_fraud_operations_strategy.md
    ├── wise/
    │   ├── README.md
    │   └── director_product_analytics_apac.md
    └── tencent/
        ├── README.md
        └── financial_crime_risk_control_manager_payments.md
```

---

## 📚 Module Overviews & Quick Links

### 💳 [01. Payment Systems & Payment Networks](01_payment_systems_and_networks/README.md)
- **The Four-Party Model**: Cardholders, Merchants, Payment Gateways/Acquirers, Payment Networks (Visa/MC), and Issuing Banks (Capital One, Chase).
- **Transaction Lifecycles**: Split-second Authorization (< 2s) vs. Batch Clearing vs. Settlement (T+1/T+3).
- **Financial Economics**: Interchange breakdown, network assessment, merchant discount rate (MDR), and Durbin amendment caps.
- **Protocols & Standards**: ISO 8583 bitmap message structures vs. modern ISO 20022 XML/JSON specifications.
- **Modern Rails**: Real-time push rails (FedNow, RTP) vs. pull rails (Card networks, ACH).

---

### 🛡️ [02. Fraud Detection & Risk Management](02_fraud_detection_and_risk/README.md)
- **Fraud Taxonomies**: Card-Not-Present (CNP), Account Takeover (ATO), Synthetic Identity, Bust-Out, and Friendly Fraud.
- **Real-Time Scoring Architecture**: Sub-50ms latency budget, dual-tier rule and ML engines, and in-memory caches.
- **Streaming Feature Engineering**: Sliding window velocity counters (`10m`, `1h`, `24h`), impossible travel heuristics, and entity novelty.
- **Severe Class Imbalance**: Managing 0.05% fraud rates, cost-sensitive loss functions, and probability recalibration.
- **Delayed Label Problem**: Addressing the 30-90 day chargeback cycle window and label maturation.
- **Graph Analytics**: Graph Neural Networks (GNN) and connected components to expose syndicate fraud rings.

---

### 📊 [03. Data Analytics & Product Experimentation](03_data_analytics/README.md)
- **Payments KPI Hierarchy**: Gross Payment Volume (GPV), Net Take Rate, Authorization Rate, Chargeback Ratio, and Loss bps.
- **Advanced SQL Patterns**: Rolling transaction window aggregations, monthly cohort retention analysis, and decline chain detection.
- **Experimentation in Fintech**: Sample Ratio Mismatch (SRM), variance reduction via **CUPED**, two-sided network spillover, and risk guardrail metrics.

---

### 🤖 [04. AI Fundamentals & GenAI Architectures](04_ai_fundamentals/README.md)
- **Foundation Models**: Scaled dot-product self-attention, Encoder vs. Decoder architectures, and Mixture of Experts (MoE).
- **Enterprise Financial RAG**: Dense vector + BM25 hybrid search, cross-encoder rerankers, and RAG Triad evaluation.
- **AI Agents**: ReAct loops, deterministic schema-validated tool calling, and human-in-the-loop (HITL) safety boundaries.
- **Compliance & Explainability**: Equal Credit Opportunity Act (ECOA), Adverse Action notices, TreeSHAP attribution, and disparate impact audits.

---

### 🧠 [05. Machine Learning Algorithms for Risk & Payments](05_ml_algorithms/README.md)
- **Gradient Boosted Decision Trees (GBDT)**: LightGBM leaf-wise tree growth, histogram binning, and handling missing values.
- **Credit Scorecards**: Weight of Evidence (WOE), Information Value (IV), and log-odds scaling to score points.
- **Unsupervised Anomaly Detection**: Isolation Forests, autoencoder reconstruction errors, and Mahalanobis distance.
- **Metric Evaluation & Calibration**: Why PR-AUC outperforms ROC-AUC, Brier score, Platt scaling, and Isotonic regression.

---

### 💼 [06. Case Studies & System Design](06_case_studies/README.md)
- **The 6-Step Fintech Case Interview Framework**: Scoping $\rightarrow$ Architecture $\rightarrow$ Signal Design $\rightarrow$ Modeling $\rightarrow$ Evaluation $\rightarrow$ Failure Modes.
- **[Case Study 01: Real-Time Fraud Detection Engine](06_case_studies/case_01_realtime_fraud_detection.md)**: 15k TPS, < 40ms P99 latency, LightGBM + ONNX, Redis sliding windows.
- **[Case Study 02: Payment Routing & Auth Optimization](06_case_studies/case_02_payment_routing_authorization.md)**: Contextual Thompson Sampling, network tokenization, and soft decline recovery.

---

### ⚡ [Company Research: PULSE / Capital One (Debit Network)](company_research/pulse_capital_one/README.md)
- **[Senior Business Manager, Fraud Operations Strategy Dossier](company_research/pulse_capital_one/senior_business_manager_fraud_operations_strategy.md)**:
  - Strategic analysis of the **$182k–$208k base + incentives** leadership role in Houston, TX / Deerfield, IL leading ~8 fraud risk specialists.
  - Deep-dive into **debit network uniqueness**: Demand Deposit Account (DDA) cash drain, single-message real-time clearing, Regulation E liability rules, and Durbin Amendment (Reg II) routing.
  - Fraud threat vectors: ATM cash-out runs, hardware shimming, PINless debit CNP surges, and 150+ ISO 8583 authorization telemetry fields in **PULSE DebitProtect**.

---

### 🌏 [Company Research: Wise (APAC Hub)](company_research/wise/README.md)
- **[Director, Product Analytics (APAC - Singapore) Dossier](company_research/wise/director_product_analytics_apac.md)**:
  - Complete job analysis for the **SGD 230k–318k + RSUs** executive role leading ~10 product analysts.
  - Deep-dive into Wise's **Autonomous Squads model**, the **4 Mission Pillars** (Price, Speed, Convenience, Transparency), and direct APAC rails (FAST/PayNow, DuitNow, NPP, PromptPay, UPI).
  - Interview stages breakdown, sample leadership & trade-off questions, and case scenarios.

---

### 🐉 [Company Research: Tencent / Tenpay Global](company_research/tencent/README.md)
- **[Financial Crime Risk Control Manager (Payments) Dossier](company_research/tencent/financial_crime_risk_control_manager_payments.md)**:
  - In-depth guide for Tenpay Global's **Overseas Acquiring & Cross-Border Payments** business in Singapore.
  - Complete merchant lifecycle risk framework (KYB, underwriting, rolling reserves, transaction laundering detection).
  - Card scheme compliance thresholds (**Visa VAMP/VFMP**, **Mastercard ECP/BRAM**) and Singapore **MAS Notices PSN01/PSN02** regulatory controls.
  - Strategic answers for merchant underwriting cases, portfolio chargeback surges, and AML/sanctions screening.

---

## 🗓️ 6-Week Structured Study Roadmap

| Week | Focus Areas | Key Milestone |
| :---: | :--- | :--- |
| **Week 1** | **Payment Mechanics & Rails** | Master the 4-party model, interchange math, ISO 8583, and decline codes. |
| **Week 2** | **Fraud Dynamics & Feature Systems** | Implement sliding window velocity counters, understand delayed labels and class imbalance. |
| **Week 3** | **Machine Learning & Scorecards** | Deep-dive into LightGBM, TreeSHAP, WOE/IV credit scorecards, and PR-AUC optimization. |
| **Week 4** | **Data Analytics & Experimentation** | Solve complex SQL queries on rolling intervals and simulate CUPED variance reduction. |
| **Week 5** | **AI Fundamentals & System Design** | Practice end-to-end low-latency system design cases and enterprise RAG architecture. |
| **Week 6** | **Mock Interviews & Application Drive** | Polish STAR behavioral stories, finalize resume keywords, and run mock case studies. |
