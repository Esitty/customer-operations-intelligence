# Data Dictionary
## What Does Poor Service Cost a Business? — Customer Operations Intelligence

This document describes every table, column, data type, and business definition used across this project. All tables are available in `data/processed/` as clean CSV files.

---

## Table of Contents

1. [transactions_clean](#1-transactions_clean)
2. [customers_clean](#2-customers_clean)
3. [tickets_clean](#3-tickets_clean)
4. [operations_clean](#4-operations_clean)
5. [customer_risk_profile](#5-customer_risk_profile)
6. [critical_risk_customers](#6-critical_risk_customers)
7. [data_quality_report](#7-data_quality_report)

---

## 1. transactions_clean

**Source:** UCI Online Retail II dataset (real data)  
**Rows:** 1,041,670  
**Grain:** One row per product line item per invoice  
**File:** `data/processed/transactions_clean.csv`

| Column | Type | Description |
|---|---|---|
| invoice | string | Unique invoice number. Cancellation invoices (prefix C) have been removed during cleaning. |
| stock_code | string | Product stock keeping unit (SKU) code. |
| description | string | Product name and description. Nulls filled with 'Unknown' during cleaning. |
| quantity | integer | Number of units purchased. All negative and zero values removed during cleaning. |
| invoice_date | datetime | Date and time of the transaction. Format: YYYY-MM-DD HH:MM:SS |
| price | float | Unit price in GBP (£). All zero and negative prices removed during cleaning. |
| customer_id | string | Unique customer identifier. Guest checkouts (no ID in source data) are labelled 'GUEST'. |
| country | string | Country of the customer placing the order. |
| revenue | float | Calculated field: quantity × price. Always positive after cleaning. |
| is_guest | boolean | True if the transaction has no customer ID (guest checkout). Guest rows are excluded from customer-level analysis. |

**Key notes:**
- Guest transactions (is_guest = True) are retained for revenue analysis but excluded from all customer segmentation and CLV calculations
- Revenue is recalculated post-cleaning to ensure accuracy after removal of invalid rows
- 25,701 rows were removed during cleaning — cancellations, negative quantities, and zero prices

---

## 2. customers_clean

**Source:** Synthetic — generated in Notebook 01, enriched from real customer IDs in transactions  
**Rows:** 5,942  
**Grain:** One row per unique customer  
**File:** `data/processed/customers_clean.csv`

| Column | Type | Description |
|---|---|---|
| customer_id | string | Unique customer identifier. Matches customer_id in transactions and tickets tables. |
| segment | string | Customer segment. Values: Retail, Corporate, Wholesale. Standardised from inconsistent source labels during cleaning. |
| clv | float | Customer Lifetime Value in GBP (£). Represents the estimated total revenue the business can expect from this customer. |
| acquisition_channel | string | How the customer was acquired. Values: Online, Referral, Direct Sales, Trade Show, Partner. |
| region | string | Geographic region of the customer. Values: UK, Germany, France, Netherlands, EIRE, Other Europe, Unknown. |
| acquisition_date | date | Date the customer was first acquired. Format: YYYY-MM-DD |
| clv_imputed | boolean | True if the CLV value was imputed using segment median (applied to new customers with insufficient purchase history). |

**Key notes:**
- Segment labels were standardised from 6 variants (Retail, retail, RETAIL, Corporate, corporate, Wholesale) to 3 clean values
- 8% of CLV values were missing (new customers) — imputed using segment median: Corporate £6,847, Wholesale £2,842, Retail £597
- 5% of region values were missing — filled with 'Unknown'
- ~2% duplicate rows from a system sync error were removed during cleaning
- Corporate customers have significantly higher CLV (avg ~£6,800) vs Retail (avg ~£597)

---

## 3. tickets_clean

**Source:** Synthetic — generated in Notebook 01  
**Rows:** 15,000  
**Grain:** One row per service ticket  
**File:** `data/processed/tickets_clean.csv`

| Column | Type | Description |
|---|---|---|
| ticket_id | string | Unique ticket identifier. Format: TKT-XXXXX |
| customer_id | string | Customer who raised the ticket. Matches customer_id in customers and transactions tables. |
| location_id | string | Service location that handled the ticket. Values: LOC_01 through LOC_08. |
| ticket_date | date | Date the ticket was raised. Format: YYYY-MM-DD |
| issue_category | string | Standardised issue type. Values: Billing, Delivery, Product Defect, Refund, Account Access, General Enquiry. |
| priority | string | Ticket priority level assigned at creation. Values: Low, Medium, High, Critical. |
| resolution_days | float | Number of days taken to resolve the ticket. Null for abandoned tickets. |
| sla_breached | integer | 1 if the ticket was not resolved within the 2-day SLA target. 0 if resolved within target. Abandoned tickets are flagged as breached (1). |
| csat_score | float | Customer satisfaction score provided after resolution. Scale: 1 (very dissatisfied) to 5 (very satisfied). Null if customer did not respond to survey. |
| status | string | Final ticket status. Values: Resolved, Open, Escalated. |
| is_abandoned | boolean | True if the ticket has no resolution time recorded — the agent did not follow up. |
| csat_responded | boolean | True if the customer completed the CSAT survey. False if no response received. |
| res_band | string | Resolution time banded for analysis. Values: 0-1 days, 1-2 days, 2-5 days, 5+ days, Abandoned. |

**Key notes:**
- SLA target is 2 days for all categories and all locations
- 13 inconsistent issue category names were standardised to 6 clean values during cleaning
- 6% of tickets are abandoned (no resolution recorded) — these are flagged as SLA breached
- 18% of customers did not respond to the CSAT survey — non-response is treated as a signal, not a data gap
- LOC_03 and LOC_07 were deliberately designed with higher breach rates (94%+) to reflect realistic underperformance patterns
- CSAT scores drop significantly with resolution time: avg 4.64 for same-day resolution vs 1.82 for 5+ days

---

## 4. operations_clean

**Source:** Synthetic — generated in Notebook 01  
**Rows:** 64 (8 locations × 8 quarters)  
**Grain:** One row per location per quarter  
**File:** `data/processed/operations_clean.csv`

| Column | Type | Description |
|---|---|---|
| location_id | string | Service location identifier. Values: LOC_01 through LOC_08. |
| quarter | string | Reporting quarter. Format: YYYY-QN (e.g. 2010-Q1) |
| region | string | Geographic region of the location. Values: UK, Germany, France, Netherlands, EIRE. |
| staff_count | float | Number of staff at the location in that quarter. Imputed for LOC_08 using median. |
| sla_target_days | float | The SLA resolution target in days. Set to 2.0 for all locations and all quarters. |
| sla_achievement_rate | float | Proportion of tickets resolved within the SLA target. Range: 0.0 to 1.0. Higher is better. |
| inventory_level | float | Inventory availability as a proportion of target level. Range: 0.0 to 1.0. Drops in Q4. |
| ticket_volume_handled | integer | Total number of tickets handled by the location in that quarter. |
| sla_imputed | boolean | True if the SLA achievement rate was imputed using the location's average (2 missing values). |
| staff_imputed | boolean | True if the staff count was imputed using the overall median (LOC_08 — data gap at onboarding). |
| sla_status | string | Performance classification based on SLA achievement rate. Values: Critical (<50%), At Risk (50–70%), Compliant (>70%). |

**Key notes:**
- LOC_03 and LOC_07 consistently show SLA achievement rates of 42–62% (Critical status)
- LOC_03 is deliberately understaffed (3–5 staff vs 8–20 for other locations)
- Q4 inventory levels drop to 45–70% of target across all locations (seasonal pressure)
- One data entry error was corrected: 'Location_03' standardised to 'LOC_03' for 2010-Q2

---

## 5. customer_risk_profile

**Source:** Generated in Notebook 04  
**Rows:** 5,453  
**Grain:** One row per customer who has raised at least one ticket  
**File:** `data/processed/customer_risk_profile.csv`

| Column | Type | Description |
|---|---|---|
| customer_id | string | Unique customer identifier. |
| total_tickets | integer | Total number of tickets raised by this customer. |
| sla_breaches | integer | Total number of tickets where SLA was breached for this customer. |
| avg_csat | float | Average CSAT score across all responded tickets for this customer. |
| segment | string | Customer segment. Values: Retail, Corporate, Wholesale. |
| clv | float | Customer Lifetime Value in GBP (£). |
| region | string | Geographic region. |
| churn_risk | boolean | True if the customer meets both churn risk criteria: 2+ SLA breaches AND average CSAT below 2.5. |
| risk_tier | string | Risk classification. Values: Low Risk, High Risk (churn risk, CLV below £2,000), Critical Risk (churn risk, CLV £2,000+). |

**Key notes:**
- 1,918 customers (35.2%) are flagged as churn risk
- 702 customers are classified as Critical Risk — these hold the highest CLV and have experienced the worst service
- Total CLV at risk across all churn-risk customers: £6,046,143 (33.5% of total portfolio CLV)
- Corporate segment holds £4,242,008 of that risk across 501 accounts

---

## 6. critical_risk_customers

**Source:** Generated in Notebook 04  
**Rows:** 20  
**Grain:** Top 20 highest-CLV customers in the Critical Risk tier  
**File:** `data/processed/critical_risk_customers.csv`

| Column | Type | Description |
|---|---|---|
| customer_id | string | Unique customer identifier. |
| segment | string | Customer segment. |
| region | string | Geographic region. |
| clv | float | Customer Lifetime Value in GBP (£). |
| total_tickets | integer | Total tickets raised. |
| sla_breaches | integer | Total SLA breaches experienced. |
| avg_csat | float | Average CSAT score. |

**Key notes:**
- These 20 accounts represent the highest financial exposure in the churn risk group
- All meet Critical Risk criteria: 2+ SLA breaches, CSAT below 2.5, CLV above £2,000
- Recommended action: personal account manager outreach within 5 business days

---

## 7. data_quality_report

**Source:** Generated in Notebook 02  
**Rows:** 19  
**Grain:** One row per cleaning decision made  
**File:** `data/processed/data_quality_report.csv`

| Column | Type | Description |
|---|---|---|
| table | string | Which table the cleaning decision applied to. |
| metric | string | What was measured or addressed. |
| before | integer/float | The count or value before cleaning. |
| after | integer/float | The count or value after cleaning. |
| change | integer/float | The difference between before and after. |
| action_taken | string | Description of the cleaning decision made and the business reason for it. |

**Key notes:**
- 19 cleaning decisions documented across all four tables
- Every decision includes a business justification — not just what was done but why
- This report is the data lineage record for the project

---

## Relationships Between Tables

```
transactions_clean
    └── customer_id → customers_clean.customer_id

tickets_clean
    └── customer_id → customers_clean.customer_id
    └── location_id → operations_clean.location_id

customer_risk_profile
    └── customer_id → customers_clean.customer_id
    └── derived from tickets_clean

critical_risk_customers
    └── subset of customer_risk_profile (top 20 by CLV, Critical Risk tier only)
```

---

## Key Business Definitions

| Term | Definition |
|---|---|
| SLA | Service Level Agreement — the 2-day resolution target committed to all customers across all issue categories |
| SLA Breach | Any ticket not resolved within 2 days of being raised, including abandoned tickets |
| CLV | Customer Lifetime Value — the total revenue the business expects to receive from a customer over the entire relationship |
| CSAT | Customer Satisfaction Score — rated 1 (very dissatisfied) to 5 (very satisfied), collected after ticket resolution |
| Churn Risk | A customer who has experienced 2 or more SLA breaches AND has an average CSAT below 2.5 |
| Critical Risk | A churn-risk customer whose CLV exceeds £2,000 — requiring immediate account management intervention |
| CLV at Risk | The total CLV held by all customers classified as churn risk — £6,046,143 in this dataset |
| Guest Transaction | A transaction with no customer ID — retained for revenue analysis but excluded from customer-level analysis |
| Resolution Band | Resolution time grouped into: 0-1 days, 1-2 days, 2-5 days, 5+ days, Abandoned |

---

*Data dictionary maintained by Henrietta Mensah · Customer Operations Intelligence Project · May 2026*
