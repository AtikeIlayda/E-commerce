
-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 01: DATA VALIDATION
-- SCHEMA: s_atikesanli
-- =====================================================

-- 1. Check row counts of all relevant tables


SELECT 'olist_orders' AS table_name, COUNT(*) AS total_rows
FROM s_atikesanli.olist_orders

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM s_atikesanli.olist_order_reviews

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM s_atikesanli.olist_order_items

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM s_atikesanli.olist_products

UNION ALL

SELECT 'olist_customers', COUNT(*)
FROM s_atikesanli.olist_customers

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM s_atikesanli.olist_sellers

UNION ALL

SELECT 'olist_mql', COUNT(*)
FROM s_atikesanli.olist_mql

UNION ALL

SELECT 'olist_closed_deals', COUNT(*)
FROM s_atikesanli.olist_closed_deals;


-- Step 2: Check duplicate order IDs

SELECT
    order_id,
    COUNT(*) AS occurrences

FROM s_atikesanli.olist_orders

GROUP BY order_id

HAVING COUNT(*) > 1;


-- Step 3: Check multiple reviews per order

SELECT
    order_id,
    COUNT(*) AS review_records

FROM s_atikesanli.olist_order_reviews

GROUP BY order_id

HAVING COUNT(*) > 1

ORDER BY review_records DESC;


-- Step 4: Count orders with multiple reviews

SELECT

    COUNT(*) AS orders_with_multiple_reviews,

    SUM(review_records) AS total_review_records_in_these_orders

FROM (

    SELECT
        order_id,
        COUNT(*) AS review_records

    FROM s_atikesanli.olist_order_reviews

    GROUP BY order_id

    HAVING COUNT(*) > 1

) AS duplicate_reviews;


-- Step 4: Examine orders with multiple reviews

SELECT

    r.order_id,

    COUNT(*) AS number_of_reviews,

    STRING_AGG(
        r.review_score::text,
        ', '
        ORDER BY r.review_creation_date
    ) AS review_scores,

    MIN(r.review_creation_date) AS first_review_date,

    MAX(r.review_creation_date) AS last_review_date

FROM s_atikesanli.olist_order_reviews r

GROUP BY r.order_id

HAVING COUNT(*) > 1

ORDER BY r.order_id

LIMIT 20;


-- Step 5: Identify orders with different review scores

SELECT

    COUNT(*) AS orders_with_different_scores

FROM (

    SELECT

        order_id

    FROM s_atikesanli.olist_order_reviews

    GROUP BY order_id

    HAVING COUNT(DISTINCT review_score) > 1

) AS different_reviews;


/*
DATA VALIDATION - FINDINGS

1. Table sizes:
   - Orders: 99,441
   - Order items: 112,650
   - Reviews: 98,410
   - Customers: 99,441
   - Products: 32,951
   - Sellers: 3,095
   - Marketing qualified leads: 8,000
   - Closed deals: 842

2. Orders:
   - No duplicate order IDs found.

3. Customer reviews:
   - 243 orders have multiple review records.
   - 486 review records belong to these orders.
   - 169 orders have identical review scores.
   - 74 orders have different review scores.

4. Analytical decision:
   - Original review records will be preserved.
   - Average review score per order will be used
     for the main customer satisfaction analysis.
   - Multiple reviews will not be automatically deleted.

NEXT STEP:
Check missing purchase, actual delivery,
and estimated delivery dates.
*/


-- Step 6: Check missing order and delivery dates

SELECT

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_dates,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders

FROM s_atikesanli.olist_orders;


/*
5. DELIVERY DATE VALIDATION

- Total orders: 99,441
- Missing purchase dates: 0
- Missing actual delivery dates: 0
- Missing estimated delivery dates: 0
- Delivered orders: 96,478
- Non-delivered orders: 2,963

Analytical decision:
- Use delivered orders for delivery duration
  and delivery delay calculations.
- Exclude non-delivered orders from delivery
  performance KPIs.
*/


-- Step 7: Distribution of order statuses

SELECT

    order_status,

    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM s_atikesanli.olist_orders),
        2
    ) AS percentage

FROM s_atikesanli.olist_orders

GROUP BY order_status

ORDER BY total_orders DESC;


/*
6. ORDER STATUS VALIDATION

Order status distribution:

- Delivered: 96,478 (97.02%)
- Shipped: 1,107 (1.11%)
- Canceled: 625 (0.63%)
- Unavailable: 609 (0.61%)
- Invoiced: 314 (0.32%)
- Processing: 301 (0.30%)
- Created: 5 (0.01%)
- Approved: 2 (0.00%)

Analytical decision:
- Delivered orders will be used for delivery
  performance analysis.
- Non-delivered orders will be excluded from
  delivery duration and on-time delivery KPIs.
- All order statuses will be retained for
  general order volume analysis.
*/


-- Step 8: Check incorrect delivery chronology


-- Step 8: Check incorrect delivery chronology

SELECT

    COUNT(*) FILTER (
        WHERE NULLIF(order_delivered_customer_date, '')::timestamp
              < NULLIF(order_purchase_timestamp, '')::timestamp
    ) AS delivered_before_purchase,

    COUNT(*) FILTER (
        WHERE NULLIF(order_delivered_customer_date, '')::timestamp
              < NULLIF(order_delivered_carrier_date, '')::timestamp
    ) AS delivered_before_carrier,

    COUNT(*) FILTER (
        WHERE NULLIF(order_delivered_carrier_date, '')::timestamp
              < NULLIF(order_purchase_timestamp, '')::timestamp
    ) AS carrier_before_purchase

FROM s_atikesanli.olist_orders

WHERE order_status = 'delivered';


/*
8. DELIVERY CHRONOLOGY VALIDATION

Results:
- Delivered before purchase: 0
- Delivered before carrier: 23
- Carrier before purchase: 165

Findings:
- 23 orders have an invalid delivery sequence.
- 165 orders have an invalid carrier sequence.
- No orders were delivered before purchase.

Analytical decision:
- Preserve all original records.
- Flag chronology issues during transformation.
- Investigate and exclude invalid delivery
  sequences from relevant delivery KPIs.
*/


-- Step 9: Validate existing chronology flags

SELECT

    chronology_issue,

    carrier_before_purchase,

    delivery_before_carrier,

    COUNT(*) AS total_orders

FROM s_atikesanli.olist_orders

GROUP BY

    chronology_issue,
    carrier_before_purchase,
    delivery_before_carrier

ORDER BY total_orders DESC;


/*
9. VALIDATION OF EXISTING CHRONOLOGY FLAGS

Results:
- No chronology issues: 99,252
- Carrier before purchase: 166
- Delivery before carrier: 23
- Total flagged orders: 189

Finding:
- Existing Python-generated chronology flags
  are consistent with SQL validation.

Analytical decision:
- Keep original records unchanged.
- Use chronology flags to identify invalid
  delivery sequences.
- Exclude invalid chronology records from
  relevant delivery performance calculations.
*/


-- Step 10: Check missing review information

SELECT

    COUNT(*) AS total_review_records,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS missing_review_scores,

    COUNT(*) FILTER (
        WHERE review_score < 1 OR review_score > 5
    ) AS invalid_review_scores,

    COUNT(DISTINCT order_id) AS unique_reviewed_orders

FROM s_atikesanli.olist_order_reviews;


/*
10. REVIEW DATA VALIDATION

Results:
- Total review records: 98,410
- Unique reviewed orders: 98,167
- Missing review scores: 0
- Invalid review scores: 0

Findings:
- All review scores are valid (1-5).
- 243 additional review records exist because
  some orders have multiple reviews.

Analytical decision:
- Preserve all original review records.
- Calculate one average review score per order
  for the main customer satisfaction analysis.
*/


-- Step 11: Distribution of customer review scores

SELECT

    review_score,

    COUNT(*) AS total_reviews,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM s_atikesanli.olist_order_reviews),
        2
    ) AS percentage

FROM s_atikesanli.olist_order_reviews

GROUP BY review_score

ORDER BY review_score;


/*
10. CUSTOMER REVIEW SCORE DISTRIBUTION

Results:
- 1 star: 11,282 (11.46%)
- 2 stars: 3,114 (3.16%)
- 3 stars: 8,097 (8.23%)
- 4 stars: 19,007 (19.31%)
- 5 stars: 56,910 (57.83%)

Finding:
- Most review records received 5 stars.
- 14.62% received low ratings (1 or 2 stars).

Business implication:
- Investigate delivery and freight factors
  associated with lower customer satisfaction.
*/


-- Step 12: Check missing order item information

SELECT

    COUNT(*) AS total_order_items,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_seller_ids,

    COUNT(*) FILTER (
        WHERE price IS NULL OR price <= 0
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE freight_value IS NULL OR freight_value < 0
    ) AS invalid_freight_values

FROM s_atikesanli.olist_order_items;


/*
11. ORDER ITEMS DATA VALIDATION

Findings:
- No missing order IDs.
- No missing product IDs.
- No missing seller IDs.
- No invalid prices (NULL or <= 0).
- No invalid freight values (NULL or < 0).

Analytical decision:
- Order items can be used for product,
  freight cost and seller analysis.
- Further checks will verify join relationships
  and prevent double-counting.
*/


-- Step 13: Check product category completeness

SELECT

    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_category_names,

    COUNT(DISTINCT product_category_name)
        AS unique_categories

FROM s_atikesanli.olist_products;


/*
12. PRODUCT CATEGORY VALIDATION

Results:
- Total products: 32,951
- Missing category names: 0
- Unique product categories: 74

Finding:
- All products have an assigned category.

Analytical decision:
- Product categories can be used for category-level
  customer satisfaction analysis.
- English translations will be checked separately.
*/


-- Step 14: Check product category translations

SELECT

    COUNT(*) AS total_translation_records,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_portuguese_names,

    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
    ) AS missing_english_names,

    COUNT(DISTINCT product_category_name)
        AS unique_portuguese_categories,

    COUNT(DISTINCT product_category_name_english)
        AS unique_english_categories

FROM s_atikesanli.olist_product_category_translation;



/*
14. PRODUCT CATEGORY TRANSLATION VALIDATION

Results:
- Total translation records: 71
- Missing Portuguese names: 0
- Missing English names: 0

Finding:
- All translation records contain both names.
- The translation table contains 71 categories.

Analytical decision:
- Use English category names in the dashboard.
- Check category matching when joining products
  with the translation table.
*/



-- Step 15: Check product ID matching

SELECT

    COUNT(DISTINCT oi.product_id) AS products_in_order_items,

    COUNT(DISTINCT p.product_id) AS matched_products,

    COUNT(DISTINCT oi.product_id)
        - COUNT(DISTINCT p.product_id) AS unmatched_products

FROM s_atikesanli.olist_order_items oi

LEFT JOIN s_atikesanli.olist_products p
    ON oi.product_id = p.product_id;


/*
15. PRODUCT ID MATCHING VALIDATION

Finding:
- All product IDs in order_items exist
  in the products table.
- Unmatched products: 0.
- Product relationship is fully matched.

Analytical decision:
- Join order_items with products using product_id.
- Use this relationship for product category
  and freight cost analysis.
*/


-- Step 16: Check seller ID matching

SELECT

    COUNT(DISTINCT oi.seller_id)
        AS sellers_in_order_items,

    COUNT(DISTINCT s.seller_id)
        AS matched_sellers,

    COUNT(DISTINCT oi.seller_id) FILTER (
        WHERE s.seller_id IS NULL
    ) AS unmatched_sellers

FROM s_atikesanli.olist_order_items oi

LEFT JOIN s_atikesanli.olist_sellers s
    ON oi.seller_id = s.seller_id;


/*
16. SELLER ID MATCHING VALIDATION

Finding:
- All seller IDs in order_items exist
  in the sellers table.
- No unmatched sellers were identified.

Analytical decision:
- Join order_items with sellers using seller_id.
- Use this relationship for seller-level
  marketplace performance analysis.
*/


-- Step 17: Check order ID matching

SELECT

    COUNT(DISTINCT oi.order_id)
        AS orders_in_order_items,

    COUNT(DISTINCT o.order_id)
        AS matched_orders,

    COUNT(DISTINCT oi.order_id) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_orders

FROM s_atikesanli.olist_order_items oi

LEFT JOIN s_atikesanli.olist_orders o
    ON oi.order_id = o.order_id;


/*
17. ORDER ID MATCHING VALIDATION

Finding:
- All order IDs in order_items exist
  in the orders table.
- No unmatched orders were identified.

Analytical decision:
- Join order_items with orders using order_id.
- Use this relationship for delivery and
  order-level performance analysis.
*/


-- Step 18: Check customer ID matching

SELECT

    COUNT(DISTINCT o.customer_id)
        AS customers_in_orders,

    COUNT(DISTINCT c.customer_id)
        AS matched_customers,

    COUNT(DISTINCT o.customer_id) FILTER (
        WHERE c.customer_id IS NULL
    ) AS unmatched_customers

FROM s_atikesanli.olist_orders o

LEFT JOIN s_atikesanli.olist_customers c
    ON o.customer_id = c.customer_id;


/*
18. CUSTOMER ID MATCHING VALIDATION

Finding:
- All customer IDs in orders exist
  in the customers table.
- No unmatched customers were identified.

Analytical decision:
- Join orders with customers using customer_id.
- Use this relationship for customer and
  regional analysis.
*/


-- Step 19: Check order and review matching

SELECT

    COUNT(DISTINCT r.order_id)
        AS reviewed_orders,

    COUNT(DISTINCT r.order_id) FILTER (
        WHERE o.order_id IS NOT NULL
    ) AS matched_orders,

    COUNT(DISTINCT r.order_id) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_orders

FROM s_atikesanli.olist_order_reviews r

LEFT JOIN s_atikesanli.olist_orders o
    ON r.order_id = o.order_id;


/*
19. ORDER AND REVIEW MATCHING VALIDATION

Finding:
- All reviewed order IDs exist in orders.
- No unmatched orders were identified.

Analytical decision:
- Join reviews with orders using order_id.
- Use this relationship to analyze delivery
  performance and customer satisfaction.
*/


-- Step 20: Check marketing lead and closed deal matching

SELECT

    COUNT(DISTINCT m.mql_id) AS total_leads,

    COUNT(DISTINCT d.mql_id) AS converted_leads,

    COUNT(DISTINCT d.mql_id) FILTER (
        WHERE m.mql_id IS NULL
    ) AS unmatched_closed_deals

FROM s_atikesanli.olist_mql m

LEFT JOIN s_atikesanli.olist_closed_deals d
    ON m.mql_id = d.mql_id;


/*
20. MARKETING FUNNEL VALIDATION

Results:
- Total marketing qualified leads: 8,000
- Converted leads / closed deals: 842
- Unmatched closed deals: 0
- Lead conversion rate: 10.53%

Finding:
- All closed deals can be matched to an MQL.
- The marketing funnel relationship is valid.

Analytical decision:
- Join olist_mql and olist_closed_deals
  using mql_id.
- Use this relationship to analyze lead
  conversion by origin and business segment.
*/


-- Step 21: Check acquired seller matching

SELECT

    COUNT(DISTINCT d.seller_id)
        AS acquired_sellers,

    COUNT(DISTINCT s.seller_id)
        AS matched_marketplace_sellers,

    COUNT(DISTINCT d.seller_id) FILTER (
        WHERE s.seller_id IS NULL
    ) AS unmatched_sellers

FROM s_atikesanli.olist_closed_deals d

LEFT JOIN s_atikesanli.olist_sellers s
    ON d.seller_id = s.seller_id;


/*
20. ACQUIRED SELLER MATCHING VALIDATION

Results:
- Acquired sellers: 842
- Matched marketplace sellers: 380
- Unmatched sellers: 462
- Matching rate: 45.13%
- Unmatched rate: 54.87%

Finding:
- Only 45.13% of acquired sellers can be
  connected to the marketplace sellers table.

Analytical decision:
- Seller marketplace performance analysis
  will use the 380 matched sellers.
- Results must be interpreted with caution.
- Unmatched sellers will not be assumed
  to have failed or become inactive.
- Report matching coverage in the dashboard.
*/


-- Step 22: Check seller ID uniqueness in closed deals

SELECT

    COUNT(*) AS total_closed_deals,

    COUNT(DISTINCT seller_id) AS unique_seller_ids,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_seller_ids,

    COUNT(DISTINCT mql_id) AS unique_mql_ids

FROM s_atikesanli.olist_closed_deals;


/*
21. CLOSED DEALS UNIQUENESS VALIDATION

Results:
- Total closed deals: 842
- Unique seller IDs: 842
- Missing seller IDs: 0
- Unique MQL IDs: 842

Finding:
- Each closed deal represents a unique seller
  and a unique marketing qualified lead.
- No duplicate seller IDs were identified.

Analytical decision:
- Use seller_id to investigate marketplace
  matching.
- Use mql_id to analyze lead conversion.
*/


-- Step 23: Sample unmatched acquired sellers

SELECT

    d.seller_id,
    d.mql_id,
    d.business_segment,
    d.won_date

FROM s_atikesanli.olist_closed_deals d

LEFT JOIN s_atikesanli.olist_sellers s
    ON d.seller_id = s.seller_id

WHERE s.seller_id IS NULL

ORDER BY d.won_date

LIMIT 20;


/*
22. UNMATCHED SELLER INVESTIGATION

Findings:
- Unmatched sellers have valid seller IDs.
- MQL IDs and business segments are available.
- Won dates are available.
- Sample records are not found in olist_sellers.

Conclusion:
- The reason for unmatched seller IDs is
  not yet established.

Analytical decision:
- Retain all 842 sellers for marketing analysis.
- Use only 380 matched sellers for marketplace
  performance analysis.
- Report the 45.13% matching coverage.
*/


-- Step 24: Acquired sellers by month and matching status

SELECT

    DATE_TRUNC('month', d.won_date)::date AS acquisition_month,

    CASE
        WHEN s.seller_id IS NOT NULL
            THEN 'Matched'
        ELSE 'Unmatched'
    END AS seller_matching_status,

    COUNT(*) AS total_sellers

FROM s_atikesanli.olist_closed_deals d

LEFT JOIN s_atikesanli.olist_sellers s
    ON d.seller_id = s.seller_id

GROUP BY
    DATE_TRUNC('month', d.won_date)::date,
    seller_matching_status

ORDER BY
    acquisition_month,
    seller_matching_status;


/*
24. SELLER MATCHING BY ACQUISITION MONTH

Findings:
- Matching is strongest during early 2018.
- Unmatched sellers increase relative to matched
  sellers from June 2018 onward.
- September-November 2018 have no matched sellers.
- Total matched sellers: 380.
- Total unmatched sellers: 462.

Conclusion:
- Seller matching coverage varies by acquisition
  month.
- Later acquired sellers are underrepresented
  in the marketplace dataset.

Analytical decision:
- Retain all sellers for funnel analysis.
- Use matched sellers only for marketplace
  performance analysis.
- Include matching coverage as a limitation.
*/


-- Step 25: Check marketplace order date range

SELECT

    MIN(order_purchase_timestamp::timestamp)
        AS first_order_date,

    MAX(order_purchase_timestamp::timestamp)
        AS last_order_date,

    COUNT(*) AS total_orders

FROM s_atikesanli.olist_orders

WHERE NULLIF(order_purchase_timestamp, '') IS NOT NULL;



/*
25. MARKETPLACE OBSERVATION PERIOD

Results:
- First order: 2016-09-04
- Last order: 2018-10-17
- Total orders: 99,441

Finding:
- Marketplace order data ends on 2018-10-17.
- Marketing acquisition data extends through
  November 2018.

Analytical limitation:
- Later acquired sellers have limited or no
  observation time in the marketplace dataset.
- Different observation periods may partly
  explain unmatched sellers.

Analytical decision:
- Do not assume unmatched sellers failed.
- Use matched sellers for marketplace analysis.
- Report the dataset coverage limitation.
*/


-- Step 26: Order item distribution

WITH order_item_counts AS (

    SELECT
        order_id,
        COUNT(*) AS item_count

    FROM s_atikesanli.olist_order_items

    GROUP BY order_id

)

SELECT

    COUNT(*) AS total_orders_with_items,

    ROUND(AVG(item_count), 2)
        AS average_items_per_order,

    MAX(item_count) AS maximum_items_per_order,

    COUNT(*) FILTER (
        WHERE item_count > 1
    ) AS orders_with_multiple_items

FROM order_item_counts;


/*
26. ORDER ITEM DISTRIBUTION

Results:
- Orders with items: 98,666
- Average items per order: 1.14
- Maximum items per order: 21
- Orders with multiple items: 9,803

Finding:
- Orders can contain multiple product items.
- An order can contain multiple sellers
  and product categories.

Analytical decision:
- Aggregate order-level information before
  joining reviews.
- Avoid duplicate counting of orders
  and customer reviews.
*/

