


-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 07: FINAL DASHBOARD KPIs
-- SCHEMA: s_atikesanli
--
-- PURPOSE:
-- Prepare final KPIs for Tableau dashboards.
--
-- CUSTOMER SATISFACTION:
-- RQ1: Delivery performance and satisfaction
-- RQ2: Delivery duration and satisfaction
-- RQ3: Freight costs and satisfaction
-- RQ4: Product categories and satisfaction
--
-- MARKETING:
-- RQ5: Marketing lead conversion and seller acquisition
-- =====================================================


-- =====================================================
-- STEP 1: OVERALL CUSTOMER SATISFACTION KPIs
-- =====================================================

SELECT

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND average_review_score IS NOT NULL
    ) AS reviewed_delivered_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_performance = 'On time or early'
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delivery_performance IN (
                      'On time or early',
                      'Late'
                  )
            ),
            0
        ),
        2
    ) AS on_time_delivery_rate,

    ROUND(
        (AVG(delivery_duration_days) FILTER (
            WHERE order_status = 'delivered'
              AND chronology_status = 'Valid chronology'
        ))::numeric,
        2
    ) AS average_delivery_time_days,

    ROUND(
        (AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND chronology_status = 'Valid chronology'
              AND total_freight_value IS NOT NULL
        ))::numeric,
        2
    ) AS average_freight_cost,

    ROUND(
        (AVG(average_review_score) FILTER (
            WHERE order_status = 'delivered'
        ))::numeric,
        2
    ) AS average_customer_review_score

FROM s_atikesanli.int_order_customer_satisfaction;


-- =====================================================
-- STEP 2: DELIVERY PERFORMANCE AND SATISFACTION
-- RQ1
-- =====================================================

SELECT

    delivery_performance,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage_of_orders

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND average_review_score IS NOT NULL

GROUP BY delivery_performance

ORDER BY total_orders DESC;


-- =====================================================
-- STEP 3: DELIVERY DURATION AND SATISFACTION
-- RQ2
-- =====================================================

SELECT

    CASE
        WHEN delivery_duration_days <= 7
            THEN '0-7 days'
        WHEN delivery_duration_days <= 14
            THEN '8-14 days'
        WHEN delivery_duration_days <= 21
            THEN '15-21 days'
        ELSE 'More than 21 days'
    END AS delivery_duration_group,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(delivery_duration_days)::numeric,
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score

FROM s_atikesanli.int_order_customer_satisfaction

WHERE order_status = 'delivered'
  AND chronology_status = 'Valid chronology'
  AND delivery_duration_days IS NOT NULL
  AND average_review_score IS NOT NULL

GROUP BY 1

ORDER BY
    MIN(delivery_duration_days);


-- =====================================================
-- STEP 4: FREIGHT COST AND CUSTOMER SATISFACTION
-- RQ3
-- =====================================================

SELECT

    CASE
        WHEN freight_percentage <= 5
            THEN '0-5%'
        WHEN freight_percentage <= 10
            THEN '5-10%'
        WHEN freight_percentage <= 15
            THEN '10-15%'
        ELSE 'More than 15%'
    END AS freight_cost_group,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(total_freight_value)::numeric,
        2
    ) AS average_freight_cost,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score

FROM (

    SELECT

        total_freight_value,

        average_review_score,

        100.0 * total_freight_value
        / NULLIF(total_product_value, 0)
            AS freight_percentage

    FROM s_atikesanli.int_order_customer_satisfaction

    WHERE order_status = 'delivered'
      AND chronology_status = 'Valid chronology'
      AND total_product_value > 0
      AND total_freight_value IS NOT NULL
      AND average_review_score IS NOT NULL

) AS freight_analysis

GROUP BY 1

ORDER BY
    MIN(freight_percentage);


-- =====================================================
-- STEP 5: CUSTOMER SATISFACTION BY PRODUCT CATEGORY
-- RQ4
-- =====================================================

WITH category_orders AS (

    SELECT DISTINCT

        oi.order_id,

        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category_name,

        v.average_review_score

    FROM s_atikesanli.olist_order_items oi

    JOIN s_atikesanli.olist_products p
        ON oi.product_id = p.product_id

    LEFT JOIN s_atikesanli.olist_product_category_translation pct
        ON p.product_category_name =
           pct.product_category_name

    JOIN s_atikesanli.int_order_customer_satisfaction v
        ON oi.order_id = v.order_id

    WHERE v.order_status = 'delivered'
      AND v.average_review_score IS NOT NULL

)

SELECT

    category_name,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score

FROM category_orders

GROUP BY category_name

ORDER BY average_review_score DESC;


-- =====================================================
-- STEP 6: MARKETING FUNNEL KPIs
-- RQ5
-- =====================================================

SELECT

    COUNT(DISTINCT m.mql_id)
        AS total_qualified_leads,

    COUNT(DISTINCT cd.mql_id)
        AS converted_leads,

    COUNT(DISTINCT m.mql_id)
        - COUNT(DISTINCT cd.mql_id)
        AS non_converted_leads,

    ROUND(
        100.0 * COUNT(DISTINCT cd.mql_id)
        / NULLIF(COUNT(DISTINCT m.mql_id), 0),
        2
    ) AS lead_conversion_rate,

    COUNT(DISTINCT cd.seller_id)
        AS acquired_sellers

FROM s_atikesanli.olist_mql m

LEFT JOIN s_atikesanli.olist_closed_deals cd
    ON m.mql_id = cd.mql_id;


-- =====================================================
-- STEP 7: MARKETING CONVERSION BY LEAD ORIGIN
-- RQ5
-- =====================================================

SELECT

    COALESCE(m.origin, 'Unknown')
        AS lead_origin,

    COUNT(DISTINCT m.mql_id)
        AS total_leads,

    COUNT(DISTINCT cd.mql_id)
        AS converted_leads,

    ROUND(
        100.0 * COUNT(DISTINCT cd.mql_id)
        / NULLIF(COUNT(DISTINCT m.mql_id), 0),
        2
    ) AS conversion_rate

FROM s_atikesanli.olist_mql m

LEFT JOIN s_atikesanli.olist_closed_deals cd
    ON m.mql_id = cd.mql_id

GROUP BY m.origin

ORDER BY conversion_rate DESC;


-- =====================================================
-- STEP 8: SELLER ACQUISITION BY BUSINESS SEGMENT
-- =====================================================

SELECT

    COALESCE(
        cd.business_segment,
        'Unknown'
    ) AS business_segment,

    COUNT(DISTINCT cd.mql_id)
        AS converted_leads,

    COUNT(DISTINCT cd.seller_id)
        AS acquired_sellers,

    ROUND(
        100.0 * COUNT(DISTINCT cd.seller_id)
        / NULLIF(
            SUM(COUNT(DISTINCT cd.seller_id)) OVER (),
            0
        ),
        2
    ) AS percentage_of_acquired_sellers,

    COUNT(DISTINCT s.seller_id)
        AS matched_marketplace_sellers

FROM s_atikesanli.olist_closed_deals cd

LEFT JOIN s_atikesanli.olist_sellers s
    ON cd.seller_id = s.seller_id

GROUP BY cd.business_segment

ORDER BY acquired_sellers DESC;


-- =====================================================
-- STEP 9: SELLER MARKETPLACE PERFORMANCE
-- =====================================================

SELECT

    cd.seller_id,

    cd.business_segment,

    COUNT(DISTINCT oi.order_id)
        AS total_orders,

    COUNT(DISTINCT oi.product_id)
        AS unique_products,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS total_sales,

    ROUND(
        AVG(v.average_review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        AVG(v.delivery_delay_days)::numeric,
        2
    ) AS average_delivery_delay_days

FROM s_atikesanli.olist_closed_deals cd

JOIN s_atikesanli.olist_sellers s
    ON cd.seller_id = s.seller_id

LEFT JOIN s_atikesanli.olist_order_items oi
    ON cd.seller_id = oi.seller_id

LEFT JOIN s_atikesanli.int_order_customer_satisfaction v
    ON oi.order_id = v.order_id

GROUP BY
    cd.seller_id,
    cd.business_segment

ORDER BY total_sales DESC;


-- =====================================================
-- STEP 10: SELLER MATCHING COVERAGE
-- =====================================================

SELECT

    COUNT(DISTINCT cd.seller_id)
        AS total_acquired_sellers,

    COUNT(DISTINCT s.seller_id)
        AS matched_marketplace_sellers,

    COUNT(DISTINCT cd.seller_id)
        - COUNT(DISTINCT s.seller_id)
        AS unmatched_sellers,

    ROUND(
        100.0 * COUNT(DISTINCT s.seller_id)
        / NULLIF(COUNT(DISTINCT cd.seller_id), 0),
        2
    ) AS seller_matching_rate

FROM s_atikesanli.olist_closed_deals cd

LEFT JOIN s_atikesanli.olist_sellers s
    ON cd.seller_id = s.seller_id;


-- =====================================================
-- STEP 11: FINAL DASHBOARD DATA VALIDATION
-- =====================================================

SELECT

    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_rows

FROM s_atikesanli.int_order_customer_satisfaction;


-- =====================================================
-- END OF SCRIPT 07
-- =====================================================
