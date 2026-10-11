# 06. Case Studies & System Design for Payments & Risk

Structured repository of end-to-end case studies and system design interviews tailored for Fintech, Payment Processors, and Financial ML roles (Capital One, Stripe, Adyen, Visa, PayPal, Square).

---

## 1. The Fintech Case Interview Framework (The 6-Step Structure)

When given an ambiguous prompt like *"How would you reduce fraud losses on peer-to-peer payments?"* or *"Design an authorization optimization engine"*, follow this structured roadmap:

```mermaid
flowchart TD
    Step1["1. Scope & Business Objective (5 min)<br/>Clarify constraints, North Star KPI, Trade-offs"] --> Step2["2. System & Data Architecture (10 min)<br/>Event pipelines, latency budget, data storage"]
    Step2 --> Step3["3. Feature Engineering & Signal Design (10 min)<br/>Streaming vs batch, entity graphs, velocity counters"]
    Step3 --> Step4["4. Modeling & Decision Tier (10 min)<br/>Algorithm choice, loss formulation, calibration, multi-tier routing"]
    Step4 --> Step5["5. Evaluation & Experimentation (5 min)<br/>PR-AUC, cost curves, A/B rollout, guardrail metrics"]
    Step5 --> Step6["6. Failure Modes & Edge Cases (5 min)<br/>Cold start, adversary adaptation, feedback delay, fallback rules"]
```

---

## 2. Directory of Detailed Case Studies

| Case Study | Domain / Focus | Key Challenges | Target Roles |
| :--- | :--- | :--- | :--- |
| **[Case 01: Real-Time Fraud Detection Engine](file:///Users/vincent_yuan/GitHub/career_repos/cof_interview_prep/06_case_studies/case_01_realtime_fraud_detection.md)** | Machine Learning System Design | 10k TPS, < 50ms latency, 0.05% imbalance, delayed labels | ML Engineer, Risk Data Scientist, Platform Architect |
| **[Case 02: Smart Payment Routing & Auth Optimization](file:///Users/vincent_yuan/GitHub/career_repos/cof_interview_prep/06_case_studies/case_02_payment_routing_authorization.md)** | Payments Product Analytics & RL | Dynamic acquirer routing, soft decline retry logic, interchange cost minimization | Product Analyst, ML Scientist, Payment Operations |

---

## 3. High-Frequency Interview Prompts to Practice

1. **Card Testing Mitigation**: *"A merchant experiences an attack where 50,000 authorization attempts occur within 15 minutes with $1 amounts across stolen card numbers. How do you detect and stop this in real time without hurting legit checkout?"*
2. **Buy Now Pay Later (BNPL) Underwriting**: *"Design a real-time credit decisioning model for a new BNPL consumer with zero credit bureau history at point-of-sale in under 200ms."*
3. **P2P Scam / Authorized Push Payment (APP) Fraud**: *"How do you prevent elderly users from being coerced into wiring money to fraudulent accounts when the legitimate user themselves is authenticating the transfer?"*
4. **Dispute Rate Surge Recovery**: *"A key merchant's chargeback rate jumped from 0.4% to 1.2% this month, putting them at risk of Visa/Mastercard monitoring program fines. Formulate a diagnostic analysis and action plan."*
