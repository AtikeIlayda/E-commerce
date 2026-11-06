

-- =====================================================
-- PROJECT: Olist E-Commerce Analysis
-- SCRIPT 05: MARKETING FUNNEL ANALYSIS
-- SCHEMA: s_atikesanli
-- RESEARCH QUESTION: RQ5
-- =====================================================


-- STEP 1: Overall qualified lead conversion
-- RQ5: How effectively do potential sellers
-- progress through the marketing funnel?

SELECT

    COUNT(DISTINCT m.mql_id) AS total_qualified_leads,

    COUNT(DISTINCT cd.mql_id) AS converted_leads,

    COUNT(DISTINCT m.mql_id)
        - COUNT(DISTINCT cd.mql_id)
        AS non_converted_leads,

    ROUND(
        100.0 * COUNT(DISTINCT cd.mql_id)
        / NULLIF(COUNT(DISTINCT m.mql_id), 0),
        2
    ) AS lead_conversion_rate

FROM s_atikesanli.olist_mql m

LEFT JOIN s_atikesanli.olist_closed_deals cd
    ON m.mql_id = cd.mql_id;


-- STEP 2: Conversion by lead origin
-- Identify which lead origins have higher
-- conversion rates.

SELECT

    COALESCE(m.origin, 'Unknown') AS lead_origin,

    COUNT(DISTINCT m.mql_id) AS total_leads,

    COUNT(DISTINCT cd.mql_id) AS converted_leads,

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


-- STEP 3: Monthly qualified lead conversion
-- Analyze lead volume and conversion performance
-- over time.

SELECT

    DATE_TRUNC(
        'month',
        m.first_contact_date
    )::date AS lead_month,

    COUNT(DISTINCT m.mql_id) AS total_leads,

    COUNT(DISTINCT cd.mql_id) AS converted_leads,

    ROUND(
        100.0 * COUNT(DISTINCT cd.mql_id)
        / NULLIF(COUNT(DISTINCT m.mql_id), 0),
        2
    ) AS conversion_rate

FROM s_atikesanli.olist_mql m

LEFT JOIN s_atikesanli.olist_closed_deals cd
    ON m.mql_id = cd.mql_id

GROUP BY 1

ORDER BY 1;


-- STEP 4: Distribution of acquired sellers
-- by business segment.

SELECT

    COALESCE(
        business_segment,
        'Unknown'
    ) AS business_segment,

    COUNT(DISTINCT mql_id) AS converted_leads,

    COUNT(DISTINCT seller_id) AS acquired_sellers,

    ROUND(
        100.0 * COUNT(DISTINCT seller_id)
        / NULLIF(
            SUM(COUNT(DISTINCT seller_id)) OVER (),
            0
        ),
        2
    ) AS percentage_of_acquired_sellers

FROM s_atikesanli.olist_closed_deals

GROUP BY business_segment

ORDER BY acquired_sellers DESC;




-- =====================================================
-- END OF MARKETING FUNNEL ANALYSIS
-- =====================================================


/*
=====================================================
SCRIPT 05: MARKETING FUNNEL ANALYSIS
RESULTS AND FINDINGS
=====================================================

1. OVERALL MARKETING FUNNEL

- Total qualified leads: 8,000
- Converted leads: 842
- Non-converted leads: 7,158
- Overall conversion rate: 10.53%

Finding:
- Approximately 10.53% of qualified leads
  converted into closed deals.


2. CONVERSION BY LEAD ORIGIN

- Unknown: 16.65%
- Paid search: 12.30%
- Organic search: 11.80%
- Direct traffic: 11.22%
- Referral: 8.45%
- Social: 5.56%
- Display: 5.08%
- Other publicities: 4.62%
- Email: 3.04%
- Other: 2.67%

Finding:
- Organic search generated the highest number
  of converted leads (271).
- Unknown origin had the highest conversion
  rate (16.65%).
- Social generated considerable lead volume
  but had a relatively low conversion rate.


3. MONTHLY CONVERSION PERFORMANCE

- Conversion performance increased substantially
  during 2018 compared with 2017.
- February 2018 had the highest conversion
  rate (14.49%).
- April 2018 had the highest number of
  converted leads (183).
- May 2018 conversion rate declined to 9.98%.

Finding:
- Marketing funnel performance varied over time.
- Further investigation is needed to explain
  the changes in conversion performance.


4. ACQUIRED SELLERS BY BUSINESS SEGMENT

- Home decor: 105 sellers (12.47%).
- Health and beauty: 93 sellers (11.05%).
- Car accessories: 77 sellers (9.14%).
- Household utilities: 71 sellers (8.43%).
- Construction tools and house garden:
  69 sellers (8.19%).

Finding:
- Home decor contributed the largest number
  of acquired sellers.


5. RESEARCH QUESTION 5

Research question:
How effectively do potential sellers progress
through the Olist marketing funnel?

Conclusion:
- Overall lead conversion rate was 10.53%.
- Conversion performance differed across
  lead origins.
- Conversion performance also varied over time.
- Acquired sellers were distributed across
  different business segments.


6. HYPOTHESIS EVALUATION

Hypothesis:
Conversion performance differs across available
lead origins and business segments.

- Lead origin: Supported descriptively.
- Business segment: Conversion differences
  cannot currently be established because
  business_segment is only available for
  converted leads in the current data model.

Limitation:
- No statistical significance tests performed.
- Unknown lead origins may affect interpretation.
- Business segment conversion cannot be calculated
  without segment information for non-converted leads.

=====================================================
END OF SCRIPT 05
=====================================================
*/

