

-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 04: FREIGHT AND CATEGORY ANALYSIS
-- SCHEMA: s_atikesanli
-- RESEARCH QUESTIONS: RQ3 AND RQ4
-- =====================================================


-- STEP 1: Prepare order-level freight information
-- RQ3: Freight costs and customer satisfaction

WITH freight_per_order AS (

    SELECT
        order_id,
        SUM(freight_value) AS total_freight,
        SUM(price) AS total_product_value,
        COUNT(*) AS total_items

    FROM s_atikesanli.olist_order_items

    GROUP BY order_id
)

SELECT

    COUNT(*) AS eligible_orders,

    ROUND(AVG(f.total_freight)::numeric, 2)
        AS average_freight_per_order,

    ROUND(AVG(f.total_product_value)::numeric, 2)
        AS average_product_value,

    ROUND(AVG(f.total_items)::numeric, 2)
        AS average_items_per_order,

    ROUND(AVG(v.average_review_score)::numeric, 2)
        AS average_review_score

FROM s_atikesanli.int_order_customer_satisfaction v

JOIN freight_per_order f
    ON v.order_id = f.order_id

WHERE v.order_status = 'delivered'
  AND v.chronology_status = 'Valid chronology'
  AND v.average_review_score IS NOT NULL;


-- STEP 2: Compare customer satisfaction across
-- freight cost quartiles
-- RQ3

WITH freight_per_order AS (

    SELECT
        order_id,
        SUM(freight_value) AS total_freight

    FROM s_atikesanli.olist_order_items

    GROUP BY order_id

),

freight_groups AS (

    SELECT

        v.order_id,
        f.total_freight,
        v.average_review_score,

        NTILE(4) OVER (
            ORDER BY f.total_freight
        ) AS freight_quartile

    FROM s_atikesanli.int_order_customer_satisfaction v

    JOIN freight_per_order f
        ON v.order_id = f.order_id

    WHERE v.order_status = 'delivered'
      AND v.chronology_status = 'Valid chronology'
      AND v.average_review_score IS NOT NULL
)

SELECT

    freight_quartile,

    COUNT(*) AS total_orders,

    ROUND(AVG(total_freight)::numeric, 2)
        AS average_freight,

    ROUND(AVG(average_review_score)::numeric, 2)
        AS average_review_score

FROM freight_groups

GROUP BY freight_quartile

ORDER BY freight_quartile;


-- STEP 3: Calculate correlation between freight
-- costs and customer satisfaction
-- RQ3

WITH freight_per_order AS (

    SELECT
        order_id,
        SUM(freight_value) AS total_freight

    FROM s_atikesanli.olist_order_items

    GROUP BY order_id
)

SELECT

    COUNT(*) AS total_orders,

    ROUND(
        CORR(
            f.total_freight,
            v.average_review_score
        )::numeric,
        4
    ) AS freight_review_correlation,

    ROUND(AVG(f.total_freight)::numeric, 2)
        AS average_freight,

    ROUND(AVG(v.average_review_score)::numeric, 2)
        AS average_review_score

FROM s_atikesanli.int_order_customer_satisfaction v

JOIN freight_per_order f
    ON v.order_id = f.order_id

WHERE v.order_status = 'delivered'
  AND v.chronology_status = 'Valid chronology'
  AND v.average_review_score IS NOT NULL;


-- STEP 4: Customer satisfaction by product category
-- RQ4

WITH order_category AS (

    SELECT

        oi.order_id,

        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        ) AS product_category,

        COUNT(*) AS item_count

    FROM s_atikesanli.olist_order_items oi

    JOIN s_atikesanli.olist_products p
        ON oi.product_id = p.product_id

    LEFT JOIN s_atikesanli.olist_product_category_translation t
        ON p.product_category_name =
           t.product_category_name

    GROUP BY
        oi.order_id,
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        )
)

SELECT

    oc.product_category,

    COUNT(DISTINCT oc.order_id) AS total_orders,

    SUM(oc.item_count) AS total_items,

    ROUND(
        AVG(v.average_review_score)::numeric,
        2
    ) AS average_review_score

FROM order_category oc

JOIN s_atikesanli.int_order_customer_satisfaction v
    ON oc.order_id = v.order_id

WHERE v.order_status = 'delivered'
  AND v.chronology_status = 'Valid chronology'
  AND v.average_review_score IS NOT NULL

GROUP BY oc.product_category

ORDER BY average_review_score DESC;


-- STEP 5: Identify categories with the lowest
-- customer satisfaction
-- RQ4

WITH order_category AS (

    SELECT

        oi.order_id,

        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        ) AS product_category

    FROM s_atikesanli.olist_order_items oi

    JOIN s_atikesanli.olist_products p
        ON oi.product_id = p.product_id

    LEFT JOIN s_atikesanli.olist_product_category_translation t
        ON p.product_category_name =
           t.product_category_name

    GROUP BY
        oi.order_id,
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        )
)

SELECT

    oc.product_category,

    COUNT(DISTINCT oc.order_id) AS total_orders,

    ROUND(
        AVG(v.average_review_score)::numeric,
        2
    ) AS average_review_score

FROM order_category oc

JOIN s_atikesanli.int_order_customer_satisfaction v
    ON oc.order_id = v.order_id

WHERE v.order_status = 'delivered'
  AND v.chronology_status = 'Valid chronology'
  AND v.average_review_score IS NOT NULL

GROUP BY oc.product_category

HAVING COUNT(DISTINCT oc.order_id) >= 50

ORDER BY average_review_score ASC

LIMIT 15;


-- =====================================================
-- END OF FREIGHT AND CATEGORY ANALYSIS
-- =====================================================

-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 04: FREIGHT AND CATEGORY ANALYSIS
-- SCHEMA: s_atikesanli
-- RESEARCH QUESTIONS: RQ3 AND RQ4
-- =====================================================

-- PURPOSE:
-- Analyze the relationship between freight costs,
-- product categories, and customer satisfaction.
--
-- STEP 1: Overall Freight Metrics
-- Calculate average freight cost, product value,
-- items per order, and average review score.
--
-- STEP 2: Freight Cost Quartiles
-- Divide orders into four freight cost groups
-- and compare average customer review scores.
--
-- STEP 3: Freight and Review Correlation
-- Calculate Pearson correlation to investigate
-- the relationship between freight costs
-- and customer satisfaction.
--
-- STEP 4: Satisfaction by Product Category
-- Calculate order counts, item counts, and
-- average review scores for each category.
--
-- STEP 5: Lowest-Rated Product Categories
-- Identify the 15 lowest-rated categories
-- with at least 50 orders.
--
-- KEY FINDINGS:
-- 95,178 eligible orders analyzed.
-- Average freight per order: 22.76.
-- Average review score: 4.16.
-- Review scores decreased from 4.32 in the
-- lowest freight quartile to 3.94 in the highest.
-- Freight-review correlation: -0.0898 (weak negative).
-- Office furniture had the lowest average review
-- score among categories with at least 50 orders (3.64).
--
-- CONCLUSIONS:
-- RQ3: Hypothesis supported. Higher freight costs
-- are associated with lower review scores, although
-- the relationship is weak.
--
-- RQ4: Hypothesis supported descriptively.
-- Average review scores differ across product categories.
--
-- NOTE:
-- Results show associations, not causation.
-- Statistical significance has not yet been tested.
--
-- =====================================================
-- END OF SCRIPT SUMMARY
-- =====================================================
