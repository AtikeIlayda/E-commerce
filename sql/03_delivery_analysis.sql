

-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 03: DELIVERY ANALYSIS
-- SCHEMA: s_atikesanli
-- RESEARCH QUESTIONS: RQ1 AND RQ2
-- =====================================================


-- STEP 1: Define the eligible analytical population
-- RQ1 and RQ2

SELECT

    COUNT(*) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE delivery_performance = 'Late'
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_performance = 'On time or early'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE average_review_score IS NOT NULL
    ) AS orders_with_reviews

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND delivery_duration_days IS NOT NULL
  AND delivery_duration_days >= 0
  AND average_review_score IS NOT NULL;


-- STEP 2: Compare average review scores
-- RQ1: Delivery performance and customer satisfaction

SELECT

    delivery_performance,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND average_review_score IS NOT NULL
  AND delivery_performance IN (
      'Late',
      'On time or early'
  )

GROUP BY delivery_performance

ORDER BY delivery_performance;


-- STEP 3: Examine review score distribution
-- RQ1: Delivery performance and customer satisfaction

SELECT

    delivery_performance,

    average_review_score,

    COUNT(*) AS total_orders

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND average_review_score IS NOT NULL
  AND delivery_performance IN (
      'Late',
      'On time or early'
  )

GROUP BY
    delivery_performance,
    average_review_score

ORDER BY
    delivery_performance,
    average_review_score;



-- STEP 4: Satisfaction by delivery duration
-- RQ2

WITH duration_groups AS (

    SELECT

        CASE
            WHEN delivery_duration_days <= 7
                THEN '0-7 days'
            WHEN delivery_duration_days <= 14
                THEN '8-14 days'
            WHEN delivery_duration_days <= 21
                THEN '15-21 days'
            WHEN delivery_duration_days <= 30
                THEN '22-30 days'
            ELSE 'More than 30 days'
        END AS delivery_duration_group,

        delivery_duration_days,
        average_review_score

    FROM s_atikesanli.int_order_customer_satisfaction

    WHERE order_status = 'delivered'
      AND chronology_status = 'Valid chronology'
      AND delivery_duration_days IS NOT NULL
      AND delivery_duration_days >= 0
      AND average_review_score IS NOT NULL
)

SELECT

    delivery_duration_group,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(delivery_duration_days)::numeric,
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score

FROM duration_groups

GROUP BY delivery_duration_group

ORDER BY
    CASE
        WHEN delivery_duration_group = '0-7 days' THEN 1
        WHEN delivery_duration_group = '8-14 days' THEN 2
        WHEN delivery_duration_group = '15-21 days' THEN 3
        WHEN delivery_duration_group = '22-30 days' THEN 4
        ELSE 5
    END;



-- STEP 5: Calculate correlation between delivery
-- duration and customer review scores
-- RQ2

SELECT

    COUNT(*) AS total_orders,

    ROUND(
        CORR(
            delivery_duration_days,
            average_review_score
        )::numeric,
        4
    ) AS delivery_duration_review_correlation,

    ROUND(
        AVG(delivery_duration_days)::numeric,
        2
    ) AS average_delivery_duration,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND delivery_duration_days IS NOT NULL
  AND delivery_duration_days >= 0
  AND average_review_score IS NOT NULL;


-- =====================================================
-- END OF INITIAL DELIVERY ANALYSIS
-- =====================================================


/*
=====================================================
SCRIPT 03: DELIVERY ANALYSIS
SUMMARY OF FINDINGS
=====================================================

RESEARCH QUESTIONS:
RQ1: Does delivery performance relate to customer
satisfaction?

RQ2: Is longer delivery time associated with lower
customer satisfaction?

1. ANALYTICAL POPULATION
- Eligible orders: 95,178
- Late orders: 7,609 (7.99%)
- On-time or early orders: 87,569 (92.01%)

2. RQ1: DELIVERY PERFORMANCE AND SATISFACTION
- Average review score for late deliveries: 2.57
- Average review score for on-time/early deliveries: 4.30
- Difference: 1.73 points.

Finding:
Late deliveries are associated with substantially
lower average customer review scores.

Hypothesis: Supported by descriptive results.

3. RQ2: DELIVERY DURATION AND SATISFACTION

Average review scores by delivery duration:

- 0-7 days: 4.42 (25,784 orders)
- 8-14 days: 4.31 (39,730 orders)
- 15-21 days: 4.14 (17,440 orders)
- 22-30 days: 3.61 (7,826 orders)
- More than 30 days: 2.25 (4,398 orders)

Correlation analysis:
- Orders analyzed: 95,178
- Average delivery duration: 12.52 days
- Average review score: 4.16
- Pearson correlation: -0.3350

Finding:
Longer delivery durations are associated with
lower customer review scores.

Hypothesis: Supported by descriptive results.

4. ANALYTICAL CONCLUSION

Both research questions show clear descriptive
relationships between delivery performance and
customer satisfaction.

Late deliveries and longer delivery durations
are associated with lower customer review scores.

These results suggest that delivery reliability
and speed are important factors to investigate
when evaluating customer satisfaction.

LIMITATIONS:
- Correlation does not establish causation.
- Customer review scores are ordinal.
- Statistical significance tests are still required.

NEXT STEP:
Perform Mann-Whitney U and Spearman correlation
tests to formally evaluate both hypotheses.

=====================================================
STATUS: SQL DESCRIPTIVE ANALYSIS COMPLETED
=====================================================
*/

