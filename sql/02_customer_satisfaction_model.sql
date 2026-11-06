


-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 02: CUSTOMER SATISFACTION MODEL
-- SCHEMA: s_atikesanli
--
-- PURPOSE:
-- Create an order-level analytical dataset.
--
-- RESEARCH QUESTIONS PREPARED:
-- RQ1: Delivery performance and satisfaction
-- RQ2: Delivery duration and satisfaction
-- RQ3: Freight costs and satisfaction
-- RQ4: Product categories and satisfaction
--
-- GRAIN:
-- One row per order
-- =====================================================


-- STEP 1: Aggregate order items to order level

CREATE OR REPLACE VIEW
s_atikesanli.int_order_items AS

SELECT

    order_id,

    COUNT(*) AS total_items,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(DISTINCT seller_id) AS unique_sellers,

    ROUND(SUM(price)::numeric, 2) AS total_product_value,

    ROUND(SUM(freight_value)::numeric, 2) AS total_freight_value,

    ROUND(
        SUM(price + freight_value)::numeric,
        2
    ) AS total_order_value

FROM s_atikesanli.olist_order_items

GROUP BY order_id;


-- STEP 2: Aggregate customer reviews to order level

CREATE OR REPLACE VIEW
s_atikesanli.int_order_reviews AS

SELECT

    order_id,

    COUNT(*) AS total_review_records,

    ROUND(AVG(review_score)::numeric, 2)
        AS average_review_score,

    MIN(review_score) AS minimum_review_score,

    MAX(review_score) AS maximum_review_score,

    COUNT(DISTINCT review_score) AS unique_review_scores,

    MIN(review_creation_date) AS first_review_date,

    MAX(review_creation_date) AS last_review_date

FROM s_atikesanli.olist_order_reviews

GROUP BY order_id;


-- STEP 3: Prepare product category information
-- Aggregate categories to order level.
-- An order can contain multiple product categories.

CREATE OR REPLACE VIEW
s_atikesanli.int_order_categories AS

SELECT

    oi.order_id,

    COUNT(DISTINCT oi.product_id)
        AS total_products,

    COUNT(DISTINCT p.product_category_name)
        AS total_categories,

    STRING_AGG(
        DISTINCT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        ),
        ', '
        ORDER BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name
        )
    ) AS product_categories

FROM s_atikesanli.olist_order_items oi

LEFT JOIN s_atikesanli.olist_products p
    ON oi.product_id = p.product_id

LEFT JOIN s_atikesanli.olist_product_category_translation t
    ON p.product_category_name = t.product_category_name

GROUP BY oi.order_id;




-- STEP 4: Build the main order-level analytical view
-- Corrected for empty date strings

CREATE OR REPLACE VIEW
s_atikesanli.int_order_customer_satisfaction AS

WITH cleaned_orders AS (

    SELECT
        order_id,
        customer_id,
        order_status,

        NULLIF(order_purchase_timestamp, '')::timestamp
            AS purchase_timestamp,

        NULLIF(order_delivered_carrier_date, '')::timestamp
            AS carrier_delivery_timestamp,

        NULLIF(order_delivered_customer_date, '')::timestamp
            AS actual_delivery_timestamp,

        NULLIF(order_estimated_delivery_date, '')::timestamp
            AS estimated_delivery_timestamp

    FROM s_atikesanli.olist_orders

)

SELECT

    o.order_id,
    o.customer_id,
    o.order_status,

    o.purchase_timestamp,
    o.carrier_delivery_timestamp,
    o.actual_delivery_timestamp,
    o.estimated_delivery_timestamp,

    -- Delivery duration in days

    CASE
        WHEN o.order_status = 'delivered'
         AND o.purchase_timestamp IS NOT NULL
         AND o.actual_delivery_timestamp IS NOT NULL
         AND o.actual_delivery_timestamp >= o.purchase_timestamp

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.actual_delivery_timestamp
                        - o.purchase_timestamp
                    )
                ) / 86400.0
            )::numeric,
            2
        )
        ELSE NULL
    END AS delivery_duration_days,

    -- Delivery delay in days

    CASE
        WHEN o.order_status = 'delivered'
         AND o.actual_delivery_timestamp IS NOT NULL
         AND o.estimated_delivery_timestamp IS NOT NULL

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.actual_delivery_timestamp
                        - o.estimated_delivery_timestamp
                    )
                ) / 86400.0
            )::numeric,
            2
        )
        ELSE NULL
    END AS delivery_delay_days,

    -- Delivery performance

    CASE
        WHEN o.order_status <> 'delivered'
            THEN 'Not delivered'

        WHEN o.actual_delivery_timestamp IS NULL
          OR o.estimated_delivery_timestamp IS NULL
            THEN 'Missing delivery information'

        WHEN o.actual_delivery_timestamp >
             o.estimated_delivery_timestamp
            THEN 'Late'

        ELSE 'On time or early'
    END AS delivery_performance,

    -- Chronology validation

    CASE
        WHEN o.order_status <> 'delivered'
            THEN 'Not applicable'

        WHEN o.purchase_timestamp IS NULL
          OR o.carrier_delivery_timestamp IS NULL
          OR o.actual_delivery_timestamp IS NULL
            THEN 'Missing chronology information'

        WHEN o.carrier_delivery_timestamp <
             o.purchase_timestamp
            THEN 'Invalid chronology'

        WHEN o.actual_delivery_timestamp <
             o.carrier_delivery_timestamp
            THEN 'Invalid chronology'

        WHEN o.actual_delivery_timestamp <
             o.purchase_timestamp
            THEN 'Invalid chronology'

        ELSE 'Valid chronology'
    END AS chronology_status,

    -- Review information

    r.total_review_records,
    r.average_review_score,
    r.minimum_review_score,
    r.maximum_review_score,
    r.unique_review_scores,

    -- Order item information

    i.total_items,
    i.unique_products,
    i.unique_sellers,
    i.total_product_value,
    i.total_freight_value,
    i.total_order_value,

    -- Product category information

    c.total_categories,
    c.product_categories

FROM cleaned_orders o

LEFT JOIN s_atikesanli.int_order_reviews r
    ON o.order_id = r.order_id

LEFT JOIN s_atikesanli.int_order_items i
    ON o.order_id = i.order_id

LEFT JOIN s_atikesanli.int_order_categories c
    ON o.order_id = c.order_id;



-- STEP 5: Validate final dataset row count

SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders

FROM s_atikesanli.int_order_customer_satisfaction;


-- STEP 6: Check duplicate order IDs

SELECT

    order_id,

    COUNT(*) AS occurrences

FROM s_atikesanli.int_order_customer_satisfaction

GROUP BY order_id

HAVING COUNT(*) > 1;




-- STEP 7: Check missing analytical information

SELECT

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE average_review_score IS NULL
    ) AS orders_without_reviews,

    COUNT(*) FILTER (
        WHERE total_items IS NULL
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE delivery_duration_days IS NULL
    ) AS orders_without_valid_delivery_duration,

    COUNT(*) FILTER (
        WHERE total_freight_value IS NULL
    ) AS orders_without_freight_information,

    COUNT(*) FILTER (
        WHERE actual_delivery_timestamp IS NULL
    ) AS orders_without_actual_delivery_date

FROM s_atikesanli.int_order_customer_satisfaction;


-- STEP 8: Check delivery chronology classifications

SELECT

    chronology_status,

    COUNT(*) AS total_orders

FROM s_atikesanli.int_order_customer_satisfaction

GROUP BY chronology_status

ORDER BY total_orders DESC;


-- STEP 8: Investigate orders without order items
-- Relevant to RQ3 and RQ4

SELECT

    o.order_status,

    COUNT(*) AS orders_without_items

FROM s_atikesanli.int_order_customer_satisfaction o

WHERE o.total_items IS NULL

GROUP BY o.order_status

ORDER BY orders_without_items DESC;


-- STEP 9: Investigate missing review records
-- Relevant to RQ1-RQ4

SELECT

    o.order_status,

    COUNT(*) AS orders_without_reviews

FROM s_atikesanli.int_order_customer_satisfaction o

WHERE o.average_review_score IS NULL

GROUP BY o.order_status

ORDER BY orders_without_reviews DESC;



-- STEP 10: Check delivery performance distribution

SELECT

    delivery_performance,

    COUNT(*) AS total_orders

FROM s_atikesanli.int_order_customer_satisfaction

GROUP BY delivery_performance

ORDER BY total_orders DESC;


-- STEP 11: Inspect sample analytical records

SELECT *

FROM s_atikesanli.int_order_customer_satisfaction

ORDER BY purchase_timestamp

LIMIT 20;

 -- STEP 12: Validate chronology flags in analytical view

SELECT

    chronology_status,

    COUNT(*) AS total_orders

FROM s_atikesanli.int_order_customer_satisfaction

GROUP BY chronology_status

-- STEP 13: Validate order-level uniqueness

SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows

FROM s_atikesanli.int_order_customer_satisfaction;
ORDER BY total_orders DESC;



 /*
=====================================================
SCRIPT 02: CUSTOMER SATISFACTION MODEL
SUMMARY OF ANALYSIS AND FINDINGS
=====================================================

PURPOSE:
Prepared an order-level analytical view combining
orders, customer reviews, order items, freight costs,
delivery information and product categories.

WHAT WE DID:
- Aggregated multiple customer reviews per order
  using the average review score.
- Aggregated order items and freight values
  to prevent duplicate order counting.
- Calculated delivery duration and delivery delay.
- Classified orders by delivery performance.
- Validated delivery chronology.
- Investigated missing reviews and order items.
- Inspected sample records and checked data quality.
- Confirmed one row per order in the final view.

KEY FINDINGS:

1. CUSTOMER REVIEWS
- 98,410 review records.
- 98,167 unique reviewed orders.
- 243 orders had multiple reviews.
- 74 orders had different review scores.
- 1,274 orders had no reviews.

2. ORDER ITEMS
- 775 orders had no associated order items.
- 603 were unavailable orders.
- 164 were canceled orders.

3. DELIVERY PERFORMANCE
- On time or early: 88,644 (89.14%).
- Late: 7,826 (7.87%).
- Not delivered: 2,963 (2.98%).
- Missing delivery information: 8 (0.01%).
- Late delivery rate among classified delivered
  orders: 8.11%.

4. DELIVERY CHRONOLOGY
- Valid chronology: 96,281.
- Invalid chronology: 188.
- Missing chronology information: 9.
- Not applicable: 2,963.

5. FINAL ANALYTICAL VIEW
- Total rows: 99,441.
- Unique orders: 99,441.
- Duplicate rows: 0.

ANALYTICAL DECISIONS:
- Preserve original records.
- Use average review score per order.
- Exclude missing reviews from satisfaction analysis.
- Exclude orders without items from freight and
  product category analysis.
- Exclude invalid chronology from relevant
  delivery performance calculations.
- Use separate eligible populations for each
  research question.

RESEARCH QUESTION STATUS:

RQ1: Does delivery performance relate to
customer satisfaction?
Status: Prepared, not yet tested.

RQ2: Is longer delivery time associated with
lower customer satisfaction?
Status: Prepared, not yet tested.

RQ3: Are higher freight costs associated with
lower customer satisfaction?
Status: Prepared, not yet tested.

RQ4: Does customer satisfaction differ across
product categories?
Status: Prepared, not yet tested.

CONCLUSION:
The order-level analytical view has been created
and passed the completed validation checks.

This dataset provides the foundation for the
customer satisfaction analysis.

No research hypotheses have been confirmed or
rejected at this stage.

NEXT STEP:
SCRIPT 03 - DELIVERY ANALYSIS
Investigate RQ1 and RQ2 using descriptive analysis,
comparisons and statistical tests.

=====================================================
STATUS: COMPLETED
=====================================================
*/

