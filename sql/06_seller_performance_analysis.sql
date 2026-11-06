

-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 06: SELLER PERFORMANCE ANALYSIS
-- SCHEMA: s_atikesanli
-- RESEARCH QUESTION: RQ6
-- =====================================================


-- STEP 1: CONNECT ACQUIRED SELLERS TO MARKETPLACE SELLERS
-- Check how many acquired sellers can be matched.

SELECT

    COUNT(DISTINCT cd.seller_id) AS total_acquired_sellers,

    COUNT(DISTINCT s.seller_id) AS matched_marketplace_sellers,

    COUNT(DISTINCT cd.seller_id) FILTER (
        WHERE s.seller_id IS NULL
    ) AS unmatched_sellers,

    ROUND(
        100.0 * COUNT(DISTINCT s.seller_id)
        / NULLIF(COUNT(DISTINCT cd.seller_id), 0),
        2
    ) AS matching_rate

FROM s_atikesanli.olist_closed_deals cd

LEFT JOIN s_atikesanli.olist_sellers s
    ON cd.seller_id = s.seller_id;


-- STEP 2: BUILD SELLER-LEVEL PERFORMANCE VIEW
-- Connect acquired sellers with marketplace activity.
-- Aggregate order items before joining reviews to
-- prevent duplicate counting.


CREATE OR REPLACE VIEW
s_atikesanli.mart_acquired_seller_performance AS

WITH seller_order_items AS (

    SELECT

        seller_id,
        order_id,

        SUM(price) AS product_value,

        SUM(freight_value) AS total_freight,

        COUNT(*) AS total_items

    FROM s_atikesanli.olist_order_items

    GROUP BY
        seller_id,
        order_id
),


seller_activity AS (

    SELECT

        seller_id,

        COUNT(DISTINCT order_id) AS total_marketplace_orders,

        SUM(product_value) AS total_product_value,

        SUM(total_items) AS total_items_sold

    FROM seller_order_items

    GROUP BY seller_id
),


seller_delivery_quality AS (

    SELECT

        soi.seller_id,

        COUNT(DISTINCT soi.order_id)
            AS eligible_delivered_orders,

        ROUND(
            AVG(v.average_review_score)::numeric,
            2
        ) AS average_review_score,

        ROUND(
            AVG(soi.total_freight)::numeric,
            2
        ) AS average_freight_per_seller_order,

        ROUND(
            AVG(
                CASE
                    WHEN
                        NULLIF(
                            o.order_delivered_customer_date,
                            ''
                        )::timestamp
                        >
                        NULLIF(
                            o.order_estimated_delivery_date,
                            ''
                        )::timestamp
                    THEN 1.0
                    ELSE 0.0
                END
            )::numeric * 100,
            2
        ) AS late_delivery_rate,

        ROUND(
            AVG(
                EXTRACT(
                    EPOCH FROM (
                        NULLIF(
                            o.order_delivered_customer_date,
                            ''
                        )::timestamp
                        -
                        NULLIF(
                            o.order_purchase_timestamp,
                            ''
                        )::timestamp
                    )
                ) / 86400.0
            )::numeric,
            2
        ) AS average_delivery_days

    FROM seller_order_items soi

    JOIN s_atikesanli.olist_orders o
        ON soi.order_id = o.order_id

    JOIN s_atikesanli.int_order_customer_satisfaction v
        ON soi.order_id = v.order_id

    WHERE v.order_status = 'delivered'

      AND v.chronology_status = 'Valid chronology'

      AND v.average_review_score IS NOT NULL

    GROUP BY soi.seller_id
)


SELECT

    cd.seller_id,

    cd.mql_id,

    cd.business_segment,

    cd.won_date,

    CASE
        WHEN s.seller_id IS NOT NULL
            THEN 'Matched'
        ELSE 'Unmatched'
    END AS seller_matching_status,

    COALESCE(
        sa.total_marketplace_orders,
        0
    ) AS total_marketplace_orders,

    COALESCE(
        sa.total_product_value,
        0
    ) AS total_product_value,

    COALESCE(
        sa.total_items_sold,
        0
    ) AS total_items_sold,

    COALESCE(
        q.eligible_delivered_orders,
        0
    ) AS eligible_delivered_orders,

    q.average_review_score,

    q.average_freight_per_seller_order,

    q.late_delivery_rate,

    q.average_delivery_days

FROM s_atikesanli.olist_closed_deals cd

LEFT JOIN s_atikesanli.olist_sellers s
    ON cd.seller_id = s.seller_id

LEFT JOIN seller_activity sa
    ON cd.seller_id = sa.seller_id

LEFT JOIN seller_delivery_quality q
    ON cd.seller_id = q.seller_id;



-- STEP 3: OVERALL PERFORMANCE OF ACQUIRED SELLERS

SELECT

    COUNT(*) AS total_acquired_sellers,

    COUNT(*) FILTER (
        WHERE seller_matching_status = 'Matched'
    ) AS matched_sellers,

    COUNT(*) FILTER (
        WHERE total_marketplace_orders > 0
    ) AS sellers_with_marketplace_orders,

    SUM(total_marketplace_orders)
        AS total_marketplace_orders,

    ROUND(
        SUM(total_marketplace_orders)::numeric
        / NULLIF(COUNT(*), 0),
        2
    ) AS average_orders_per_acquired_seller,

    ROUND(
        SUM(total_marketplace_orders)::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE seller_matching_status = 'Matched'
            ),
            0
        ),
        2
    ) AS average_orders_per_matched_seller,

    ROUND(
        SUM(total_product_value)::numeric,
        2
    ) AS total_product_value,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_seller_review_score,

    ROUND(
        AVG(late_delivery_rate)::numeric,
        2
    ) AS average_seller_late_delivery_rate,

    ROUND(
        AVG(average_delivery_days)::numeric,
        2
    ) AS average_seller_delivery_days

FROM s_atikesanli.mart_acquired_seller_performance;


-- STEP 4: SELLER PERFORMANCE BY BUSINESS SEGMENT


SELECT

    COALESCE(
        business_segment,
        'Unknown'
    ) AS business_segment,

    COUNT(*) AS acquired_sellers,

    COUNT(*) FILTER (
        WHERE seller_matching_status = 'Matched'
    ) AS matched_sellers,

    COUNT(*) FILTER (
        WHERE total_marketplace_orders > 0
    ) AS sellers_with_orders,

    SUM(total_marketplace_orders)
        AS total_marketplace_orders,

    ROUND(
        AVG(average_review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        AVG(late_delivery_rate)::numeric,
        2
    ) AS average_late_delivery_rate,

    ROUND(
        AVG(average_delivery_days)::numeric,
        2
    ) AS average_delivery_days

FROM s_atikesanli.mart_acquired_seller_performance

GROUP BY business_segment

ORDER BY acquired_sellers DESC;


-- STEP 5: IDENTIFY SELLERS WITH THE HIGHEST
-- MARKETPLACE ACTIVITY


SELECT

    seller_id,

    business_segment,

    total_marketplace_orders,

    total_product_value,

    eligible_delivered_orders,

    average_review_score,

    late_delivery_rate,

    average_delivery_days

FROM s_atikesanli.mart_acquired_seller_performance

WHERE seller_matching_status = 'Matched'

  AND total_marketplace_orders > 0

ORDER BY total_marketplace_orders DESC

LIMIT 15;


-- STEP 6: IDENTIFY SELLERS WITH THE LOWEST
-- CUSTOMER REVIEW SCORES
-- Minimum 20 eligible delivered orders.


SELECT

    seller_id,

    business_segment,

    total_marketplace_orders,

    eligible_delivered_orders,

    average_review_score,

    late_delivery_rate,

    average_delivery_days

FROM s_atikesanli.mart_acquired_seller_performance

WHERE seller_matching_status = 'Matched'

  AND eligible_delivered_orders >= 20

ORDER BY average_review_score ASC

LIMIT 15;


-- =====================================================
-- END OF SCRIPT 06
-- =====================================================



/*
=====================================================
SCRIPT 06: SELLER PERFORMANCE ANALYSIS
FINAL FINDINGS
=====================================================

1. SELLER MATCHING

- Total acquired sellers: 842
- Matched marketplace sellers: 380
- Unmatched sellers: 462
- Matching coverage: 45.13%

Finding:
Only 45.13% of acquired sellers could be
matched to the marketplace sellers table.

The remaining 54.87% could not be identified
in the marketplace dataset.

2. OVERALL MARKETPLACE PERFORMANCE

- Matched sellers with marketplace orders: 380
- Total marketplace orders: 4,518
- Average orders per acquired seller: 5.37
- Average orders per matched seller: 11.89
- Total product value: 676,852.00
- Average seller review score: 4.34
- Average seller late delivery rate: 6.77%
- Average seller delivery duration: 8.94 days

Finding:
The matched acquired sellers demonstrated
measurable marketplace activity and generally
positive customer review scores.

The average of 11.89 orders per matched seller
provides a more representative measure of
marketplace activity among identifiable sellers.

3. PERFORMANCE BY BUSINESS SEGMENT

- Sports & leisure had an average review score
  of 4.70 and a late delivery rate of 1.62%.
- Health & beauty had an average review score
  of 4.58 and a late delivery rate of 4.87%.
- Home decor had a late delivery rate of 13.78%.
- Performance varied across business segments.

Finding:
Descriptive differences in customer satisfaction
and delivery performance were observed across
business segments.

4. INDIVIDUAL SELLER PERFORMANCE

- The highest-activity seller generated 565
  marketplace orders.
- This seller had an average review score of 4.04.
- Its late delivery rate was 12.25%.
- One seller with at least 20 orders had an
  average review score of 3.59.

Finding:
High marketplace activity does not necessarily
correspond to higher customer satisfaction.

Individual seller performance varied in terms
of marketplace activity, review scores and
delivery reliability.

5. RESEARCH QUESTION 6

Question:
Can seller acquisition information be connected
to marketplace performance?

Conclusion:
Yes. Seller acquisition information could be
connected to marketplace performance for
380 of the 842 acquired sellers.

Hypothesis evaluation:
PARTIALLY SUPPORTED.

Descriptive differences were observed in marketplace
activity, customer review scores and delivery
performance across sellers and business segments.

However, the analysis does not establish causality
or statistical significance.

6. LIMITATIONS

- Only 45.13% of acquired sellers were matched.
- Unmatched sellers cannot automatically be
  considered unsuccessful or inactive.
- The analysis is observational.
- Some business segments have small sample sizes.
- Marketplace activity is measured using
  seller-order counts.
- Total product value does not represent
  seller profit.
- Differences in observation periods may affect
  marketplace activity comparisons.

7. BUSINESS IMPLICATION

Olist could investigate sellers and business
segments with relatively high delivery delays
or lower customer review scores.

Further investigation could help identify
opportunities to improve marketplace performance,
delivery reliability and customer satisfaction.

=====================================================
END OF SCRIPT 06 FINDINGS
=====================================================
*/
