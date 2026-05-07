-- ============================================================
-- PROJECT: What Does Poor Service Cost a Business?
-- Customer Operations Intelligence — SQL Query File
-- ============================================================
-- Database: customer_ops
-- Tables:   transactions, customers, tickets, operations
-- Tool:     MySQL Workbench
-- Author:   Henrietta Mensah
-- ============================================================


-- ============================================================
-- SETUP: Create Database and Load Tables
-- ============================================================

CREATE DATABASE IF NOT EXISTS customer_ops;
USE customer_ops;


-- ============================================================
-- PHASE 1 — OPERATIONAL PERFORMANCE QUERIES
-- ============================================================

-- Q1.1 Overall SLA breach rate by location
-- Business question: Which locations are failing to meet SLA targets?
SELECT
    location_id,
    COUNT(ticket_id)                          AS total_tickets,
    SUM(sla_breached)                         AS breached_tickets,
    ROUND(AVG(sla_breached) * 100, 1)         AS breach_rate_pct,
    ROUND(AVG(csat_score), 2)                 AS avg_csat,
    ROUND(AVG(resolution_days), 1)            AS avg_resolution_days
FROM tickets
GROUP BY location_id
ORDER BY breach_rate_pct DESC;


-- Q1.2 SLA achievement trend by location and quarter
-- Business question: Is operational performance improving or deteriorating over time?
SELECT
    location_id,
    quarter,
    region,
    ROUND(sla_achievement_rate * 100, 1)      AS sla_achievement_pct,
    sla_status,
    staff_count,
    inventory_level,
    ticket_volume_handled
FROM operations
ORDER BY location_id, quarter;


-- Q1.3 Locations consistently below 70% SLA achievement
-- Business question: Which locations require immediate management intervention?
SELECT
    location_id,
    region,
    COUNT(quarter)                            AS quarters_tracked,
    ROUND(AVG(sla_achievement_rate) * 100, 1) AS avg_sla_pct,
    MIN(ROUND(sla_achievement_rate * 100, 1)) AS worst_quarter_pct,
    SUM(CASE WHEN sla_status = 'Critical' THEN 1 ELSE 0 END) AS critical_quarters
FROM operations
GROUP BY location_id, region
HAVING avg_sla_pct < 70
ORDER BY avg_sla_pct ASC;


-- Q1.4 Monthly ticket volume trend
-- Business question: When does service demand peak and how does this align with revenue?
SELECT
    DATE_FORMAT(ticket_date, '%Y-%m')         AS month,
    COUNT(ticket_id)                          AS total_tickets,
    SUM(sla_breached)                         AS breached,
    ROUND(AVG(sla_breached) * 100, 1)         AS breach_rate_pct,
    ROUND(AVG(csat_score), 2)                 AS avg_csat
FROM tickets
GROUP BY DATE_FORMAT(ticket_date, '%Y-%m')
ORDER BY month;


-- Q1.5 Ticket volume by issue category and priority
-- Business question: What types of issues consume the most service capacity?
SELECT
    issue_category,
    priority,
    COUNT(ticket_id)                          AS ticket_count,
    ROUND(AVG(resolution_days), 1)            AS avg_resolution_days,
    ROUND(AVG(sla_breached) * 100, 1)         AS breach_rate_pct,
    ROUND(AVG(csat_score), 2)                 AS avg_csat
FROM tickets
GROUP BY issue_category, priority
ORDER BY issue_category, 
    CASE priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        ELSE 4 
    END;


-- ============================================================
-- PHASE 2 — CUSTOMER ANALYTICS QUERIES
-- ============================================================

-- Q2.1 Revenue by customer segment
-- Business question: Which segment drives the most transaction revenue?
SELECT
    c.segment,
    COUNT(DISTINCT t.customer_id)             AS customer_count,
    COUNT(DISTINCT t.invoice)                 AS total_orders,
    ROUND(SUM(t.revenue), 2)                  AS total_revenue,
    ROUND(AVG(t.revenue), 2)                  AS avg_order_revenue,
    ROUND(SUM(t.revenue) / COUNT(DISTINCT t.customer_id), 2) AS revenue_per_customer
FROM transactions t
JOIN customers c ON ROUND(CAST(t.customer_id AS DECIMAL(10,0)),0) = ROUND(CAST(c.customer_id AS DECIMAL(10,0)),0)
WHERE t.customer_id != 'GUEST'
GROUP BY c.segment
ORDER BY total_revenue DESC;


-- Q2.2 Top 20 customers by total transaction revenue
-- Business question: Who are the highest-value customers by actual spend?
SELECT
    t.customer_id,
    c.segment,
    c.region,
    c.clv                                     AS assigned_clv,
    COUNT(DISTINCT t.invoice)                 AS total_orders,
    ROUND(SUM(t.revenue), 2)                  AS total_revenue,
    ROUND(AVG(t.revenue), 2)                  AS avg_order_value,
    MIN(DATE(t.invoice_date))                 AS first_order,
    MAX(DATE(t.invoice_date))                 AS last_order
FROM transactions t
JOIN customers c ON ROUND(CAST(t.customer_id AS DECIMAL(10,0)),0) = ROUND(CAST(c.customer_id AS DECIMAL(10,0)),0)
WHERE t.customer_id != 'GUEST'
GROUP BY t.customer_id, c.segment, c.region, c.clv
ORDER BY total_revenue DESC
LIMIT 20;


-- Q2.3 Revenue by country
-- Business question: How geographically concentrated is the revenue base?
SELECT
    country,
    COUNT(DISTINCT customer_id)               AS unique_customers,
    COUNT(DISTINCT invoice)                   AS total_orders,
    ROUND(SUM(revenue), 2)                    AS total_revenue,
    ROUND(SUM(revenue) / SUM(SUM(revenue)) OVER () * 100, 1) AS revenue_share_pct
FROM transactions
WHERE customer_id != 'GUEST'
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;


-- Q2.4 Customer acquisition channel performance
-- Business question: Which acquisition channels produce the highest-value customers?
SELECT
    acquisition_channel,
    COUNT(customer_id)                        AS customers_acquired,
    ROUND(AVG(clv), 2)                        AS avg_clv,
    ROUND(SUM(clv), 2)                        AS total_clv,
    ROUND(AVG(clv) / SUM(AVG(clv)) OVER () * 100, 1) AS clv_index
FROM customers
GROUP BY acquisition_channel
ORDER BY avg_clv DESC;


-- Q2.5 Monthly revenue trend with growth rate
-- Business question: Is the business growing month on month?
SELECT
    DATE_FORMAT(invoice_date, '%Y-%m')        AS month,
    ROUND(SUM(revenue), 2)                    AS monthly_revenue,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY DATE_FORMAT(invoice_date, '%Y-%m')))
        / LAG(SUM(revenue)) OVER (ORDER BY DATE_FORMAT(invoice_date, '%Y-%m')) * 100
    , 1)                                      AS mom_growth_pct
FROM transactions
WHERE YEAR(invoice_date) IN (2010, 2011)
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY month;


-- ============================================================
-- PHASE 3 — BUSINESS IMPLICATIONS QUERIES
-- ============================================================

-- Q3.1 CLV at risk by segment
-- Business question: How much lifetime value is concentrated in at-risk customers?
SELECT
    c.segment,
    COUNT(DISTINCT cr.customer_id)            AS customers_at_risk,
    ROUND(SUM(c.clv), 2)                      AS clv_at_risk,
    ROUND(AVG(c.clv), 2)                      AS avg_clv_at_risk,
    ROUND(SUM(c.clv) / SUM(SUM(c.clv)) OVER () * 100, 1) AS pct_of_total_risk
FROM customers c
JOIN (
    SELECT
        customer_id,
        SUM(sla_breached)   AS sla_breaches,
        AVG(csat_score)     AS avg_csat
    FROM tickets
    GROUP BY customer_id
    HAVING SUM(sla_breached) >= 2 AND AVG(csat_score) < 2.5
) cr ON ROUND(CAST(c.customer_id AS DECIMAL(10,0)),0) = ROUND(CAST(cr.customer_id AS DECIMAL(10,0)),0)
GROUP BY c.segment
ORDER BY clv_at_risk DESC;


-- Q3.2 Revenue impact of SLA breaches by location
-- Business question: Which locations are creating the most financial exposure through poor service?
SELECT
    t.location_id,
    o.region,
    COUNT(t.ticket_id)                        AS total_tickets,
    SUM(t.sla_breached)                       AS breached_tickets,
    ROUND(AVG(t.sla_breached) * 100, 1)       AS breach_rate_pct,
    ROUND(AVG(t.csat_score), 2)               AS avg_csat,
    COUNT(DISTINCT t.customer_id)             AS unique_customers_affected,
    ROUND(SUM(c.clv), 2)                      AS total_clv_exposed
FROM tickets t
JOIN customers c ON ROUND(CAST(t.customer_id AS DECIMAL(10,0)),0) = ROUND(CAST(c.customer_id AS DECIMAL(10,0)),0)
JOIN (
    SELECT location_id, region,
           AVG(sla_achievement_rate) AS avg_sla
    FROM operations
    GROUP BY location_id, region
) o ON t.location_id = o.location_id
GROUP BY t.location_id, o.region
ORDER BY breach_rate_pct DESC;


-- Q3.3 Cost of inaction — projected CLV loss at different churn rates
-- Business question: What is the financial exposure if at-risk customers churn?
SELECT
    churn_scenario,
    ROUND(clv_at_risk * churn_rate, 2)        AS projected_clv_loss
FROM (
    SELECT SUM(c.clv) AS clv_at_risk
    FROM customers c
    JOIN (
        SELECT customer_id
        FROM tickets
        GROUP BY customer_id
        HAVING SUM(sla_breached) >= 2 AND AVG(csat_score) < 2.5
    ) cr ON ROUND(CAST(c.customer_id AS DECIMAL(10,0)),0) = ROUND(CAST(cr.customer_id AS DECIMAL(10,0)),0)
) base
CROSS JOIN (
    SELECT '10% churn' AS churn_scenario, 0.10 AS churn_rate UNION ALL
    SELECT '20% churn',                   0.20             UNION ALL
    SELECT '30% churn',                   0.30             UNION ALL
    SELECT '50% churn',                   0.50
) scenarios
ORDER BY churn_rate;


-- Q3.4 Seasonal revenue concentration
-- Business question: How dependent is the business on Q4 performance?
SELECT
    YEAR(invoice_date)                        AS year,
    QUARTER(invoice_date)                     AS quarter,
    ROUND(SUM(revenue), 2)                    AS quarterly_revenue,
    ROUND(SUM(revenue) / SUM(SUM(revenue)) OVER (PARTITION BY YEAR(invoice_date)) * 100, 1) AS pct_of_annual_revenue
FROM transactions
WHERE YEAR(invoice_date) IN (2010, 2011)
GROUP BY YEAR(invoice_date), QUARTER(invoice_date)
ORDER BY year, quarter;


-- Q3.5 Abandoned ticket analysis — hidden service failure
-- Business question: How many customers received no resolution at all?
SELECT
    location_id,
    issue_category,
    COUNT(ticket_id)                          AS total_tickets,
    SUM(CASE WHEN is_abandoned = 1 THEN 1 ELSE 0 END) AS abandoned_tickets,
    ROUND(AVG(CASE WHEN is_abandoned = 1 THEN 1 ELSE 0 END) * 100, 1) AS abandonment_rate_pct
FROM tickets
GROUP BY location_id, issue_category
HAVING abandonment_rate_pct > 5
ORDER BY abandonment_rate_pct DESC;


-- ============================================================
-- PHASE 4 — MARKET CONTEXT QUERIES
-- ============================================================

-- Q4.1 Average order value by country vs overall average
-- Business question: Which markets have above-average transaction values?
SELECT
    country,
    ROUND(AVG(revenue), 2)                    AS avg_order_value,
    ROUND(AVG(revenue) / AVG(AVG(revenue)) OVER () * 100, 1) AS index_vs_avg,
    COUNT(DISTINCT invoice)                   AS order_count
FROM transactions
WHERE customer_id != 'GUEST'
GROUP BY country
HAVING order_count > 50
ORDER BY avg_order_value DESC;


-- Q4.2 CSAT response rate by category
-- Business question: Where is the data quality weakest and why does it matter?
SELECT
    issue_category,
    COUNT(ticket_id)                          AS total_tickets,
    SUM(csat_responded)                       AS responses_received,
    ROUND(AVG(csat_responded) * 100, 1)       AS response_rate_pct,
    ROUND(AVG(csat_score), 2)                 AS avg_csat_where_responded
FROM tickets
GROUP BY issue_category
ORDER BY response_rate_pct ASC;


-- Q4.3 Customer retention signal — repeat purchase analysis
-- Business question: What proportion of customers are repeat buyers?
SELECT
    order_frequency_band,
    COUNT(customer_id)                        AS customers,
    ROUND(AVG(total_revenue), 2)              AS avg_revenue,
    ROUND(AVG(order_count), 1)                AS avg_orders
FROM (
    SELECT
        t.customer_id,
        COUNT(DISTINCT t.invoice)             AS order_count,
        ROUND(SUM(t.revenue), 2)              AS total_revenue,
        CASE
            WHEN COUNT(DISTINCT t.invoice) = 1  THEN '1 order (one-time)'
            WHEN COUNT(DISTINCT t.invoice) <= 3  THEN '2-3 orders'
            WHEN COUNT(DISTINCT t.invoice) <= 10 THEN '4-10 orders'
            ELSE '10+ orders (loyal)'
        END                                   AS order_frequency_band
    FROM transactions t
    WHERE t.customer_id != 'GUEST'
    GROUP BY t.customer_id
) freq
GROUP BY order_frequency_band
ORDER BY avg_orders;


-- ============================================================
-- END OF QUERY FILE
-- Total queries: 16 across 4 phases
-- ============================================================
