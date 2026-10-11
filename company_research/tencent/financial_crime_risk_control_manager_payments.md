# Tencent Dossier: Financial Crime Risk Control Manager (Payments)

> **Role Title**: Financial Crime Risk Control Manager (Payments)  
> **Company**: Tencent / Tenpay Global Pte. Ltd.  
> **Business Group**: Corporate Development Group (CDG) — Financial Technology (FiT)  
> **Location**: Singapore  
> **Scope**: Overseas Acquiring Business, Cross-Border Payments, and International Merchant Risk  
> **Job Reference**: LinkedIn ID: 4473729104  
> **Job Link**: [LinkedIn Job Listing](https://sg.linkedin.com/jobs/view/financial-crime-risk-control-manager-payments-at-tencent-4473729104)

---

## 1. Executive Summary & Business Unit Context

### Tencent Financial Technology (FiT) & Tenpay Global
While Tencent is globally renowned for WeChat, gaming, and cloud services, its **Financial Technology (FiT)** division operates one of the largest payment infrastructures in the world (**Tenpay / Weixin Pay**). 

**Tenpay Global Pte. Ltd.** (headquartered in Singapore) is Tencent's primary vehicle for international payment expansion, licensed under the **Monetary Authority of Singapore (MAS)** Payment Services Act.

```mermaid
flowchart TD
    subgraph Tenpay Global Core Business Lines
        B1[1. Cross-Border Acquiring: Inbound<br/>Enabling global merchants to accept Weixin Pay / UnionPay from Chinese consumers]
        B2[2. Overseas Merchant Acquiring: Outbound<br/>Acquiring international Visa, Mastercard, JCB, Amex payments for overseas merchants]
        B3[3. Cross-Border Remittance: WeRemit<br/>P2P cross-border transfers and business disbursements across APAC/Europe]
        B4[4. Global Digital Commerce<br/>Payment processing for gaming, digital entertainment, and SaaS]
    end
```

### The Strategic Mission of the Role
As Tencent accelerates its international acquiring footprint across Southeast Asia, Europe, and Latin America, it takes on direct **acquirer liability**:
- If an acquired merchant goes bankrupt, commits bust-out fraud, or runs illegal gambling/counterfeit goods schemes, **Tenpay Global is financially liable to the card schemes (Visa/Mastercard) and regulators (MAS)**.
- This role owns the end-to-end **merchant risk lifecycle**, **card scheme compliance**, **transaction fraud monitoring**, and **AML/CFT risk controls** for international payments.

---

## 2. End-to-End Overseas Merchant Acquiring Risk Lifecycle

In payment acquiring, risk control spans the entire lifecycle of a merchant:

```mermaid
flowchart LR
    KYB[1. Merchant Onboarding & KYB] --> Underwriting[2. Risk Scoring & Underwriting]
    Underwriting --> Reserves[3. Reserve & Payout Terms]
    Reserves --> Monitoring[4. Real-Time Txn Monitoring]
    Monitoring --> Dispute[5. Chargeback & Scheme Mgmt]
    Dispute --> Audit[6. Periodic Review & Offboarding]
```

### Phase 1: Merchant Onboarding & KYB (Know Your Business)
- **Ultimate Beneficial Owner (UBO)** identification (threshold: $\ge 25\%$ ownership).
- **Sanctions & PEP Screening**: Screening corporate entities and directors against OFAC, UN, EU, and MAS sanction lists.
- **Website & Business Model Due Diligence**: Validating terms of service, refund policy, pricing consistency, and intellectual property (avoiding counterfeit goods/infringing brands).
- **Merchant Category Code (MCC) Assignment**: Assigning precise MCCs (e.g., 5732 Electronics vs 7995 Gambling) to prevent transaction laundering.

### Phase 2: Underwriting & Financial Exposure Assessment
- **Credit Risk / Solvency Check**: Reviewing financial statements, processing history, and bank statements.
- **Fulfillment Lag Exposure**: Calculating the duration between consumer payment and goods delivery. Long delivery horizons (e.g., airlines, custom furniture, annual SaaS) create high unfulfilled delivery liability if the merchant fails.

### Phase 3: Mitigation Terms & Collateralization
- **Rolling Reserves**: Withholding a percentage of daily gross processing volume (e.g., 5–10% for 180 days) to buffer against potential future chargebacks.
- **Settlement Delay (T+N)**: Payout schedules set based on merchant risk tier (e.g., T+2 vs T+7 vs T+14).
- **Processing Volume Caps**: Enforcing monthly volume limits to detect sudden surges indicative of bust-out attacks.

### Phase 4: Ongoing Transaction Monitoring & Anomaly Detection
- **Velocity Rules**: Unusual spikes in transaction count or average order value (AOV).
- **Cross-Border Geo Mismatch**: Merchant registered in Singapore processing 95% of card transactions from Ukrainian cards at 3:00 AM.
- **Transaction Laundering / Aggregation Detection**: Detecting unauthorized sub-merchants funneling illegal payments through an approved shell merchant.

### Phase 5: Card Scheme Compliance & Dispute Management
- **Visa & Mastercard Monitoring Thresholds**:
  - **Visa Acquirer Monitoring Program (VAMP)** / **VFMP** (Fraud): Thresholds triggered if dispute or fraud ratios exceed $0.9\%$ (90–100 bps).
  - **Mastercard Excessive Chargeback Program (ECP)** / **BRAM** (Brand Risk Management) / **ANOP** (Audit Non-Compliance).
- **Excessive Chargeback Remediation Plans**: Managing fines ($25,000–$100,000+ per scheme tier) and merchant termination if thresholds are breached.

---

## 3. Financial Crime & Regulatory Compliance in Singapore (MAS)

Because Tenpay Global operates under MAS oversight in Singapore, the Risk Control Manager must master:

| Regulatory Area | Key Requirement | Application to Tencent Payments |
| :--- | :--- | :--- |
| **MAS Notice PSN01** | AML / Counter-Financing of Terrorism for Payment Services | Mandatory customer due diligence (CDD), transaction screening, and high-risk country risk rating. |
| **MAS Notice PSN02** | Prevention of Money Laundering for Digital Payment Token / Cross-border | Risk mitigation for cross-border fund transfers and remittances. |
| **Suspicious Transaction Reporting (STR)** | Mandatory filing with CAD (Commercial Affairs Department) | Flagging anomalous patterns: structuring / smurfing, sudden high-value velocity, inconsistent business rationale. |
| **Travel Rule** | FATF Recommendation 16 | Originator and beneficiary details must travel alongside cross-border fund transfers exceeding statutory thresholds. |

---

## 4. Key Responsibilities & Problem Statements

### 1. Risk Framework Design & Implementation
- Formulate dynamic merchant risk policies tailored for different international markets (APAC, Europe, LATAM) balancing onboarding conversion against loss prevention.
- Build portfolio-level **Key Risk Indicators (KRIs)**: Portfolio Chargeback Rate, Fraud Loss Rate (bps), High-Risk Merchant Exposure %, Delayed Settlement Collateral Coverage.

### 2. Detection Logic & Model Strategy
- Collaborate with tech teams to configure rule engines and risk scoring models (decision trees, LightGBM, anomaly clustering).
- Build automated alerts for transaction laundering, rapid refund surges, and card testing scripts.

### 3. Investigation & Incident Management
- Conduct deep-dive investigations on suspicious merchants, frozen funds, and coordinated fraud syndicates.
- Lead closed-loop post-mortems: When an unexpected loss or scheme warning occurs, identify root-cause vulnerabilities, update rules, and re-underwrite similar merchants in the portfolio.

### 4. Cross-Functional & Cross-Regional Collaboration
- Act as the bridge between **Singapore local compliance/product teams** and **Headquarters (Shenzhen/Hong Kong) technology and risk operations teams**.
- Bilingual fluency (English & Mandarin) is critical to communicate regulatory demands to engineering and executive leadership.

---

## 5. Interview Preparation: High-Frequency Questions & Frameworks

### Category 1: Merchant Acquiring & Underwriting Risk
> **Question**: *"A fast-growing cross-border e-commerce merchant applies to accept international credit cards. Their projected volume is $5M/month, selling electronics with 3-week global shipping. How do you underwrite and structure their risk terms?"*

**Answer Framework**:
1. **Identify the Inherent Risk Profile**: Electronics have high resale value $\rightarrow$ high target for stolen cards (CNP fraud). 3-week fulfillment lag means that if the merchant fails or ships empty boxes, chargebacks will flood in 30–60 days later.
2. **KYB & Verification**:
   - Check corporate registry, verify UBOs, review 6 months of historical processing statements, chargeback rates, and refund ratios with prior acquirers.
   - Mystery shopping / site inspection: verify shipping fulfillment contracts, return policies, and stock availability.
3. **Mitigation Terms**:
   - **Rolling Reserve**: 10% rolling reserve for 180 days (covering the 120-day card scheme dispute window).
   - **Settlement Terms**: T+5 or T+7 delayed settlement to ensure initial tracking numbers are validated.
   - **Volume Cap**: Initial cap of $1M for the first 60 days; ramp up only after observing mature chargeback rates $< 0.5\%$.
   - **Mandatory 3DS 2.0**: Require step-up authentication on transactions above $150 to shift fraud liability to issuers.

---

### Category 2: Transaction Laundering / Aggregation
> **Question**: *"How do you detect if an approved online travel agency merchant is secretly acting as a payment aggregator for unauthorized high-risk merchants (e.g., online gaming, adult, or IPTV subscriptions)?"*

**Answer Framework**:
1. **Transaction Amount Anomaly**: Travel tickets usually have round or specific price bands ($200–$800) with low transaction frequency per user. Transaction laundering displays micro-transactions ($5–$20) at high velocity, or repeated charges on the same card in minutes.
2. **MCC & Descriptor Discrepancies**: Cardholders dispute charges with descriptor mismatch ("I didn't buy airline tickets; I bought gaming tokens").
3. **Traffic & Web Analytics**: Use web crawling tools (e.g., Web Shield, LegitScript) to check if payment gateway tokens from the approved merchant site appear on unauthorized third-party URLs.
4. **Action**: Immediate payout freeze, forensic audit, and offboarding under Mastercard BRAM / Visa rules.

---

### Category 3: Card Scheme Fines & Remediation
> **Question**: *"Our acquiring portfolio’s chargeback ratio for Visa transactions spikes to 1.15% in month 1. What immediate actions do you take to avoid formal Visa Acquirer Monitoring Program (VAMP) fines?"*

**Answer Framework**:
1. **Portfolio Decomposition**:
   - Calculate ratio: $\text{Dispute Ratio} = \frac{\text{Disputed Txns}}{\text{Settled Txns}}$.
   - Segment by merchant: Identify the top 5 merchants driving 80% of the chargebacks (the Pareto principle in risk).
2. **Immediate Remediation on Bad Actors**:
   - Immediately pause processing or enable strict 3DS 2.0 / fraud scoring rules on offending merchants.
   - Issue automated refunds for transactions flagged with early fraud warnings (Visa TC40 / Mastercard SAFE signals) before they turn into formal chargebacks.
3. **Engage the Card Scheme**:
   - Proactively submit an Acquirer Remediation Plan to Visa showing merchant containment actions, updated risk filters, and expected downward trajectory below 0.90% within 30 days.

---

### Category 4: AML / Sanctions & MAS Compliance
> **Question**: *"Under MAS regulations, how do you handle an overseas merchant payout when the beneficial owner has a partial name match against an OFAC or MAS sanction list?"*

**Answer Framework**:
1. **Immediate Payout Hold**: Place an automatic system hold on outgoing settlements without alerting the customer (avoiding 'tipping off' under AML law).
2. **Secondary Level Screening**:
   - Check unique identifiers: Date of birth (DOB), nationality, national ID/passport number, and corporate incorporation country against the sanction notice metadata.
3. **False Positive Resolution vs Escalation**:
   - If proven false positive (common name, different DOB/nationality): Document audit trail and release hold.
   - If confirmed true match or partial high-confidence match: Escalate to MLRO (Money Laundering Reporting Officer), file a Suspicious Transaction Report (STR) with Singapore CAD, and freeze assets as legally mandated.

---

## 6. High-Impact Questions to Ask Tencent Interviewers

1. *"How is the risk architecture structured between Tencent’s Shenzhen FiT core risk engine and Tenpay Global’s local Singapore infrastructure to meet MAS data localization and real-time processing requirements?"*
2. *"With the international rollout of Weixin Pay cross-border acquiring for foreign merchants, what has been the biggest challenge in balancing localized payment customs with Tencent's centralized fraud models?"*
3. *"How does Tenpay Global leverage AI and graph analytics to uncover complex transaction laundering syndicates operating across multiple offshore shell corporations?"*
