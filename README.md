# What Does Poor Service Cost a Business?
### A Customer Operations Intelligence Project

---

Having spent seven years in operations watching businesses make decisions from gut feeling when the data was sitting right there.

This project is my answer to one question a business owner asked me during a conversation: *"After all your analysis, what does poor service actually cost a business?"*

The answer, built across Python, SQL, Tableau, and Excel, is **£6.05 million in customer lifetime value sitting at active churn risk** and a roadmap for what to do about it.

---

## The Business Context

This analytics portfolio does not analyze customers in isolation.

This project treats customer data by connecting what happens inside the business (SLA breaches, staffing gaps, inventory pressure) to what customers experience as a result (dissatisfaction, complaint volumes, churn signals), and then answering the question that actually matters in a management meeting: *what does this cost us, and what do we do about it?*

Every finding in this project follows a four-step analytical framework:

**Analysis** → what is happening  
**Implication** → what this means for the business  
**Recommendation** → what to do about it  
**Risk of Inaction** → what it costs to wait  

---

## The Findings 

Before the methodology, here is what the data actually says.

**The business has a service crisis, not a service problem.**
An SLA breach rate of 89.4% means nearly nine in ten customer tickets are not resolved within the agreed timeframe. This is not a dip - it is the default experience.

**The cost is quantifiable.**
£6.05 million in customer lifetime value sits with customers who have experienced repeated SLA failures and report satisfaction scores below 2.5 out of 5. At a conservative 20% churn rate among this group, that is £1.21 million in lost lifetime value. At 30%, £1.72 million.

**The damage is concentrated where it hurts most.**
Corporate customers represent 70% of the at-risk CLV despite being a small share of the customer base. Losing one corporate account is financially equivalent to losing 13 retail customers. They are receiving no differentiated service.

**Germany is both the biggest problem and the biggest opportunity.**
LOC_03 and LOC_07, both Germany-based breach SLA targets at 94%+. Internal CSAT of 2.49 sits 1.56 points below the German market average of 4.05. In a market where 67% of consumers switch after two bad experiences, this is not a performance gap. It is a retention emergency.

**The fix is operational, not commercial.**
Resolution speed is the single most controllable driver of customer satisfaction in this dataset. CSAT drops from 4.64 on same day resolution to 1.82 on tickets taking five or more days. The business does not need a new product or a new market. It needs to resolve tickets faster.

---

## Project Structure

```
customer-operations-intelligence/
│
├── notebooks/
│   ├── 01_data_generation.ipynb        # UCI dataset + synthetic table generation
│   ├── 02_data_cleaning.ipynb          # Cleaning, imputation, quality report
│   ├── 03_exploratory_analysis.ipynb   # Revenue, segment, ticket EDA
│   ├── 04_customer_experience.ipynb    # CLV at risk, churn flags, CSAT analysis
│   ├── 05_business_implications.ipynb  # Churn scenarios, cost of inaction
│   ├── 06_market_context.ipynb         # German e-commerce benchmarking
│   ├── 07_load_mysql.ipynb             # Load clean data into MySQL
│   ├── queries.sql                     # 16 business queries across 4 phases
│   ├── executive_summary.xlsx          # Board-level 4-tab management report
│   └── data/
│       ├── raw/                        # Four messy CSV files
│       └── processed/                  # Four clean CSV files + charts + risk profiles
│
└── README.md
```

---

## The Data

**Foundation:** UCI Online Retail II dataset. A real transactional data from a UK-based online retailer, 2009–2011. 1,067,371 transaction rows across two Excel sheets.

**Extended with three synthetic tables** built in Python to mirror a real multi-location service operation:

| Table | Rows | What it contains |
|---|---|---|
| transactions_clean | 1,041,670 | Revenue, products, customers, countries |
| customers_clean | 5,942 | Segments, CLV, acquisition channels, regions |
| tickets_clean | 15,000 | Issue categories, resolution times, CSAT scores, SLA flags |
| operations_clean | 64 | Location performance, SLA rates, staffing, inventory by quarter |

**Deliberate messiness was introduced** into all four raw tables, inconsistent category labels, missing values, duplicate rows, data entry errors because cleaning decisions are analytical decisions. The `data_quality_report.csv` documents every choice made and why.

---

## Tools and Why

| Tool | Role in this project |
|---|---|
| **Python** | Data generation, cleaning, EDA, churn risk modelling, market benchmarking |
| **SQL (MySQL)** | 16 business queries across operational, customer, implication, and market phases |
| **Tableau Public** | Interactive four-panel dashboard with KPI row, filters, and annotated charts |
| **Excel** | Four-tab executive summary — KPI Scorecard, Findings, Action Plan, Benchmarks |

This combination mirrors how real BI teams work. A data engineer generates and models the data. An analyst queries it in SQL. A BI developer builds the dashboard. A senior analyst writes the business narrative. This project does all four.

---

## The Six Notebooks — What Each One Does

**Notebook 01 - Data Generation**  
Loads the UCI dataset, profiles it raw, and generates three synthetic tables with realistic patterns built in: SLA breaches clustered at specific locations, seasonal complaint spikes, corporate customers with higher CLV and more demanding expectations.

**Notebook 02 - Data Cleaning**  
Takes four messy tables and produces four clean ones. Every cleaning decision is documented with a reason: what was dropped, what was imputed, what was standardised and why. Produces a data quality report showing before and after for each table.

**Notebook 03 - Exploratory Analysis**  
Six key findings with charts: revenue seasonality, geographic concentration, segment CLV distribution, ticket patterns by category, seasonal ticket spikes, and location-level SLA performance. Every finding follows the four-step framework.

**Notebook 04 - Customer Experience Analysis**  
Connects operational failures to customer value. Quantifies the CLV at risk, identifies 1,918 churn-risk customers, builds a customer risk profile with tiers, and surfaces the CSAT non-response signal, the finding that the real picture is probably worse than the data shows.

**Notebook 05 - Business Implications**  
Translates findings into money. Churn scenario modelling at 10%, 20%, 30%, and 50% churn rates. Q4 revenue at risk. Corporate segment financial exposure. A prioritised action plan with the cost of inaction attached to each item.

**Notebook 06 - Market Context**  
Benchmarks internal performance against German e-commerce and European service industry standards. Four benchmarks: CSAT, resolution time, consumer expectations, and geographic concentration. The conclusion - this is not marginal underperformance. It is a service crisis by market standards.

---

## The SQL Queries — 16 Questions in Four Phases

```sql
-- Example: Q3.3 - Cost of inaction at different churn rates
SELECT churn_scenario,
       ROUND(clv_at_risk * churn_rate, 2) AS projected_clv_loss
FROM (
    SELECT SUM(c.clv) AS clv_at_risk
    FROM customers c
    JOIN (
        SELECT customer_id
        FROM tickets
        GROUP BY customer_id
        HAVING SUM(sla_breached) >= 2 AND AVG(csat_score) < 2.5
    ) cr ON c.customer_id = cr.customer_id
) base
CROSS JOIN (
    SELECT '10% churn' AS churn_scenario, 0.10 AS churn_rate UNION ALL
    SELECT '20% churn', 0.20 UNION ALL
    SELECT '30% churn', 0.30 UNION ALL
    SELECT '50% churn', 0.50
) scenarios
ORDER BY churn_rate;
```

The queries are organised across four analytical phases: operational performance, customer analytics, business implications, and market context, matching the notebook structure exactly.

---
## SQL Query Results

![SLA Breach Rate by Location](notebooks/sql_results/1_sla_breach.png)
![Revenue by Customer Segment](notebooks/sql_results/2_revenue_segment.png)
![CLV at Risk by Segment](notebooks/sql_results/3_clv_risk_by_segment.png)
![Cost of Inaction](notebooks/sql_results/4_cost_of_inaction.png)
![Seasonal Revenue](notebooks/sql_results/5_seasonal_revenue.png) 

---
## The Dashboard

**Live on Tableau Public:**  
[Customer Operations Intelligence Dashboard](https://public.tableau.com/views/CustomerOperationsIntelligenceDashboard/CustomerOperationsIntelligenceDashboard)

Six panels on one screen:
- Four KPI tiles: Total Revenue, SLA Breach Rate, Avg CSAT, CLV at Risk
- Monthly revenue trend with November peak annotations
- SLA breach rate by location: LOC_03 and LOC_07 in red
- CSAT score by issue category - Billing at the bottom
- CLV at risk by segment - Corporate at 76.2%
- Churn risk scenario model - cost of inaction visualised

Interactive filters by Segment and Location. Every chart uses a consistent colour logic: red for critical failures, amber for at-risk, teal for acceptable performance.

---

## The Executive Summary

A four-tab Excel workbook designed to be opened in a management meeting (non-technical stakeholders):

- **KPI Scorecard**: six metrics with traffic light status and gap to target
- **Findings & Implications**: six findings with the full four-step framework
- **Priority Action Plan**: five actions ranked by financial impact with owner and timeline
- **Market Benchmarks**: internal vs industry average vs best practice with source citations

---

## How to Run This Project

**Requirements:**
- Python 3.10+ with pandas, numpy, matplotlib, pymysql, sqlalchemy
- Jupyter Notebook
- MySQL (any recent version)
- Tableau Public (free)
- Microsoft Excel or equivalent

**Steps:**

1. Clone the repository and navigate to the `notebooks/` folder
2. Download the UCI Online Retail II dataset from [archive.ics.uci.edu](https://archive.ics.uci.edu/dataset/502/online+retail+ii) and place it in `notebooks/`
3. Run notebooks 01 through 06 in sequence
4. Create a MySQL database called `customer_ops`
5. Run `07_load_mysql.ipynb` to populate the database
6. Open `queries.sql` in MySQL Workbench and run all 16 queries
7. Connect Tableau Public to the clean CSV files in `data/processed/`

---

## Why This Project Exists

Seven years in operations taught me that the gap between data and decisions is not a technology problem. It is a communication problem. Businesses have dashboards. They have reports. What they often do not have is someone who can sit in a management meeting and say here is what this costs you, and here is what happens if you do **NOTHING**.

That is what this project does.

The business owner who asked me *"what does poor service cost a business?"* was not asking for a chart. He was asking for a number he could act on. I also added prioritized action timelines. This project is my attempt to build the analytical infrastructure that produces that number and to do it in a way that is transparent, reproducible, and honest about its limitations.

The UCI Online Retail II dataset provided the transactional foundation. The synthetic tables are realistic but invented. The benchmark figures are sourced from publicly available industry reports. **The analytical framework is mine**.

---

## About

**Henrietta Mensah**  
BI Analyst | Operations Background | MSc Data Analytics  
Based in Berlin, Germany

Seven years managing supply chains, logistics operations, and cross-functional performance reviews across multiple industries. Now applying that operational thinking to data and building analyses that connect what the numbers say to what businesses should do about it.

*Open to Operations & BI/Data Analyst roles.*

---

*Built with the UCI Online Retail II dataset. Synthetic tables generated in Python. All analysis reproducible from the notebooks.*
