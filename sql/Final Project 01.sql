SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name = 's_atikesanli';

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 's_atikesanli'
ORDER BY table_name;

SELECT
    has_database_privilege(
        current_user,
        current_database(),
        'CREATE'
    ) AS can_create_schema;

SELECT
    has_schema_privilege(
        current_user,
        's_atikesanli',
        'USAGE'
    ) AS can_use_schema,
    has_schema_privilege(
        current_user,
        's_atikesanli',
        'CREATE'
    ) AS can_create_tables;

SELECT COUNT(*)
FROM s_atikesanli.olist_orders;

SELECT *
FROM s_atikesanli.olist_orders
LIMIT 10;

ALTER TABLE s_atikesanli.olist_order_reviews 
ALTER COLUMN review_comment_title TYPE TEXT;

ALTER TABLE s_atikesanli.olist_order_reviews 
ALTER COLUMN review_comment_message TYPE TEXT;

ALTER TABLE s_atikesanli.product_category_translation_cleaned 
RENAME TO olist_product_category_translation;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 's_atikesanli'
AND table_name = 'olist_order_reviews';

SELECT COUNT(*) AS total_rows
FROM s_atikesanli.olist_order_reviews;

SELECT *
FROM s_atikesanli.olist_order_reviews
LIMIT 10;

SELECT
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 's_atikesanli'
AND table_name = 'olist_order_reviews'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_rows,
    COUNT(review_id) AS reviews_with_id,
    COUNT(review_comment_message) AS reviews_with_message,
    MAX(LENGTH(review_comment_message)) AS longest_message
FROM s_atikesanli.olist_order_reviews;

SELECT
    review_id,
    LENGTH(review_comment_message) AS message_length,
    review_comment_message
FROM s_atikesanli.olist_order_reviews
ORDER BY message_length DESC
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(*) - COUNT(DISTINCT review_id) AS possible_duplicates
FROM s_atikesanli.olist_order_reviews;

SELECT review_id, COUNT(*) AS occurrences
FROM s_atikesanli.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT order_id) AS different_orders
FROM s_atikesanli.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM s_atikesanli.olist_order_reviews;

TRUNCATE TABLE s_atikesanli.olist_order_reviews;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_reviews
FROM s_atikesanli.olist_order_reviews;

SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT order_id) AS different_orders
FROM s_atikesanli.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM s_atikesanli.olist_order_reviews;

SELECT
    review_id,
    COUNT(*) AS occurrences
FROM s_atikesanli.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS number_of_reviews
FROM s_atikesanli.olist_order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY number_of_reviews DESC;

SELECT *
FROM s_atikesanli.olist_order_reviews
WHERE order_id IN (
    SELECT order_id
    FROM s_atikesanli.olist_order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS duplicate_review_ids
FROM s_atikesanli.olist_order_reviews;

SELECT *
FROM s_atikesanli.olist_order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM s_atikesanli.olist_order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id;

SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT (
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    )) AS different_versions
FROM s_atikesanli.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

SELECT *
FROM s_atikesanli.olist_order_reviews
WHERE review_id = '39b4603793c1c7f5f36d809b4a218664';

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS extra_rows
FROM s_atikesanli.olist_order_reviews;

SELECT
    COUNT(*) AS duplicated_review_ids,
    SUM(occurrences) AS rows_with_repeated_ids
FROM (
    SELECT review_id, COUNT(*) AS occurrences
    FROM s_atikesanli.olist_order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT review_id) AS unique_review_ids
FROM s_atikesanli.olist_order_reviews;

SELECT
    occurrences,
    COUNT(*) AS number_of_review_ids
FROM (
    SELECT review_id, COUNT(*) AS occurrences
    FROM s_atikesanli.olist_order_reviews
    GROUP BY review_id
) AS counts
GROUP BY occurrences
ORDER BY occurrences;

CREATE TABLE s_atikesanli.olist_reviews_original_check (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

SELECT COUNT(*)
FROM s_atikesanli.olist_order_reviews;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids
FROM s_atikesanli.olist_order_reviews;
