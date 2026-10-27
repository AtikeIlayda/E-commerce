# From Delivery to Loyalty: Understanding Customer Satisfaction and Marketing Performance in E-Commerce

## 1. Project Overview

### Project Background

Customer satisfaction is essential for building trust, encouraging repeat purchases, and supporting long-term success in e-commerce.

Customers evaluate their shopping experience based on several factors, including delivery speed, shipping costs, product quality, and the reliability of the marketplace.

At the same time, e-commerce marketplaces need to understand how effectively they acquire sellers and how potential sellers progress through the marketing and sales funnel.

This project uses the Brazilian E-Commerce Public Dataset by Olist and the Olist Marketing Funnel Dataset to investigate customer satisfaction and seller acquisition performance.

The project combines two analytical perspectives:

- **Customer Satisfaction Analysis:** Investigating how delivery performance, freight costs, and product categories relate to customer review scores.
- **Marketing Funnel Analysis:** Exploring how potential sellers progress through the acquisition funnel and whether seller acquisition information can be connected to marketplace performance.

The goal is to translate data into actionable business recommendations and communicate the findings through an interactive Tableau dashboard.

## 2. Business Problem

This project addresses two business challenges.

First, e-commerce marketplaces need to provide a reliable customer experience. Late deliveries, long delivery times, and high shipping costs may be associated with lower customer satisfaction.

Second, marketplaces need to acquire sellers effectively. Understanding lead qualification and conversion can help businesses evaluate their seller acquisition process.

The analysis will investigate these questions while distinguishing observed relationships from conclusions that can be supported by the available data.

## 3. Datasets

### 3.1 Brazilian E-Commerce Public Dataset by Olist

Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

This dataset contains information about orders, customers, sellers, products, payments, shipping, and customer reviews.

Relevant tables include:

- `orders` — order dates and delivery information
- `order_reviews` — customer review scores
- `order_items` — products, sellers, prices, and freight costs
- `products` — product categories and characteristics
- `customers` — customer information and locations
- `sellers` — seller information and locations
- `order_payments` — payment types and values
- `product_category_name_translation` — English product category names

### 3.2 Olist Marketing Funnel Dataset

Dataset: https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

This dataset contains information about potential business customers and sellers entering Olist's acquisition process.

The analysis will investigate lead origins, qualification information, business segments, and conversion to closed sales where the available fields support these measures.

**Important distinction:** The marketing funnel primarily concerns seller acquisition. It should not automatically be interpreted as consumer advertising or individual customer purchase conversion.

### 3.3 Data Scope

Before combining the datasets, I will check:

- Observation periods
- Missing values and duplicate records
- Available identifiers and their meanings
- Data completeness
- Whether a reliable connection exists between marketing leads and marketplace sellers

The two datasets will only be connected if the available data supports a reliable relationship.

## 4. Research Questions and Hypotheses

### Part A: Customer Satisfaction

**Research Question 1: Does delivery performance relate to customer satisfaction?**

Hypothesis: Orders delivered after the estimated delivery date have lower average review scores than orders delivered on time or earlier.

**Research Question 2: Is a longer delivery time associated with lower customer satisfaction?**

Hypothesis: Longer delivery times are associated with lower customer review scores.

**Research Question 3: Are higher freight costs associated with lower customer satisfaction?**

Hypothesis: Orders with higher freight costs have lower average customer review scores.

**Research Question 4: Does customer satisfaction differ across product categories?**

Hypothesis: Average customer review scores differ across product categories.

### Part B: Marketing Funnel and Seller Acquisition

**Research Question 5: How effectively do potential sellers progress through the Olist marketing funnel?**

Hypothesis: Conversion performance differs across available lead origins and business segments.

**Research Question 6: Can seller acquisition information be connected to marketplace performance?**

Where a reliable seller-level connection exists, I will explore whether marketplace activity, customer review scores, and delivery performance differ across acquired seller groups.

This analysis will only be performed if the relationship between marketing leads and marketplace sellers is sufficiently complete and reliable.

## 5. Project Objectives

The project aims to:

- Identify factors associated with higher and lower customer review scores.
- Investigate the relationship between delivery delays and customer satisfaction.
- Examine whether longer delivery times are associated with lower review scores.
- Analyze the relationship between freight costs and customer satisfaction.
- Compare customer satisfaction across product categories.
- Explore lead qualification and conversion performance.
- Investigate whether marketing leads can be connected to marketplace sellers.
- Develop evidence-based business recommendations.
- Build an interactive Tableau dashboard.
- Document data quality issues and analytical limitations.

## 6. Project Workflow

The project follows a structured workflow using Python, SQL, dbt, and Tableau.

**Workflow:**

Raw CSV Files → Database / Data Warehouse → SQL Exploration → dbt Transformations and Data Models → Business Analysis → Tableau Dashboard

### Step 1: Data Audit and Initial Exploration — Python

Python will be used to:

- Load and inspect the datasets.
- Check column names and data types.
- Identify missing values and duplicates.
- Review date ranges and unusual values.
- Explore data distributions.
- Assess data quality before analysis.

### Step 2: Data Exploration and Integration — SQL

SQL will be used to:

- Explore the database structure.
- Identify primary and foreign keys.
- Understand relationships between tables.
- Join relevant datasets.
- Calculate initial business metrics.
- Check for duplicate counting and unexpected join results.

### Step 3: Data Transformation and Modeling — dbt + SQL

dbt will organize SQL transformations into reusable and documented data models.

The models will be structured into staging, intermediate, and business-facing layers.

Potential models include:

- `stg_orders`
- `stg_order_items`
- `stg_reviews`
- `fct_orders`
- `fct_delivery_performance`
- `mart_customer_satisfaction`

The final models will support consistent calculations, data validation, and dashboard development.

The marketing funnel will initially be modeled separately unless a reliable relationship to marketplace sellers can be established.

### Step 4: Business Analysis — SQL and Python

The prepared data will be used to investigate the research questions.

The analysis will include:

- Delivery performance and customer reviews
- Delivery duration and customer satisfaction
- Freight costs and review scores
- Product category comparisons
- Marketing funnel conversion
- Seller performance, if a reliable connection exists

Python may be used for additional statistical analysis and visualizations where appropriate.

### Step 5: Dashboard Development — Tableau

Tableau will be used to create an interactive dashboard presenting the most important findings.

The dashboard will include relevant KPIs, charts, filters, comparisons, and explanatory text.

### Step 6: Interpretation and Recommendations

The final step will be to interpret the findings, identify business implications, develop recommendations, and communicate limitations.

## 7. Data Audit and Preparation

Before the main analysis, I will examine:

- Number of rows and columns
- Data types and date formats
- Missing values
- Duplicate records
- Primary and foreign keys
- Observation periods
- Unusual or implausible values
- Join quality between datasets

I will also create relevant analytical variables, including:

- Delivery duration
- Delivery delay
- Delivery status
- Customer review score groups
- Freight cost groups
- Lead qualification and conversion measures, where available

Missing information will not automatically be removed. Its treatment will depend on the analytical question and the reason for the missing value.

## 8. Statistical Analysis

The analysis will begin with descriptive statistics and comparisons.

Depending on data quality and sample size, additional methods may include:

- Comparing review scores between late and on-time deliveries
- Examining correlations between delivery duration and review scores
- Comparing review scores across freight cost groups
- Comparing customer satisfaction across product categories
- Comparing lead conversion rates across acquisition origins
- Using suitable statistical tests where appropriate

Customer review scores are ordinal, and the datasets are observational. The analysis will therefore distinguish associations from causal conclusions.

## 9. Tableau Dashboard Concept

The dashboard will be designed around the project's business questions.

### Dashboard 1: Customer Satisfaction Overview

**Main question:** How satisfied are customers with their shopping experience?

Potential KPIs and visuals:

- Total orders analyzed
- Number of customer reviews
- Average review score
- Late delivery rate
- Average delivery duration
- Distribution of review scores
- Monthly order trends, where appropriate

### Dashboard 2: Delivery Performance

**Main question:** Are delivery delays and longer delivery times associated with lower customer satisfaction?

Potential visuals:

- Review scores by delivery status
- Average delivery duration
- Delivery delay distribution
- Late delivery rate over time
- Comparison of on-time and late deliveries

### Dashboard 3: Freight Costs and Product Categories

**Main question:** Are freight costs and product categories associated with customer satisfaction?

Potential visuals:

- Review scores by freight cost group
- Freight cost distribution
- Average review score by product category
- Number of reviews per category
- Categories with comparatively high or low review scores

Sample sizes will be displayed to make comparisons more transparent.

### Dashboard 4: Marketing Funnel

**Main question:** How effectively do potential sellers progress through the acquisition funnel?

Potential visuals:

- Number of leads by origin
- Available funnel-stage counts
- Qualification rates, where clearly defined
- Conversion rates by lead origin
- Conversion rates by business segment
- Lead volume over time

The dashboard will reflect the actual funnel stages available in the dataset.

### Dashboard 5: Seller and Marketplace Performance

This dashboard will only be included if the marketing funnel can be connected to marketplace sellers with acceptable join quality.

Potential visuals:

- Number of identifiable acquired sellers with marketplace activity
- Orders by seller acquisition group
- Average review scores by seller group
- Late delivery rate by seller group
- Sales metrics using a clearly defined calculation

The dashboard will explain the coverage and limitations of the connection.

## 10. Business Recommendations

The final recommendations will depend on the results of the analysis.

Potential areas include:

- Improving delivery reliability if delays are associated with lower review scores.
- Investigating logistics bottlenecks where delivery duration is high.
- Reviewing shipping-cost communication if freight costs are associated with lower satisfaction.
- Investigating product categories with consistently lower review scores.
- Evaluating lead origins based on both lead volume and conversion performance.
- Exploring seller performance differences where a reliable connection exists.

These are potential recommendation areas, not findings that have already been established.

## 11. Limitations

The project has several limitations:

- The datasets are observational and generally cannot establish causality.
- Missing values may affect the analytical sample.
- Customer review scores are ordinal.
- Freight costs may depend on distance, product characteristics, and order composition.
- Orders can contain multiple products and product categories, creating potential double-counting risks.
- The marketing funnel concerns seller acquisition rather than necessarily consumer advertising.
- The two datasets may not be fully joinable.
- Marketing ROI cannot be calculated reliably without suitable cost and return information.
- The datasets may cover different observation periods.
- Results may not generalize to all e-commerce businesses.

These limitations will be considered when interpreting the findings and making recommendations.

## 12. Expected Deliverables

The project will produce:

- **Data Audit:** Data structure, quality checks, missing values, and observation periods.
- **SQL Analysis:** Data integration, business metrics, and analytical datasets.
- **dbt Models:** Reusable transformations, documentation, and data tests.
- **Python Analysis:** Exploratory analysis, statistical comparisons, and supporting visualizations.
- **Tableau Dashboard:** Interactive visualizations addressing the research questions.
- **Business Recommendations:** Practical suggestions supported by the findings.
- **Final Presentation:** Project background, methodology, results, recommendations, and limitations.

## 13. Project Timeline

### Phase 1: Data Understanding

Download datasets, inspect tables, review documentation, and confirm the project scope.

### Phase 2: Data Cleaning and Integration

Check data quality, standardize data types, prepare variables, and verify relationships between tables.

### Phase 3: Exploratory Data Analysis

Explore customer reviews, delivery performance, freight costs, product categories, and marketing funnel data.

### Phase 4: Statistical Analysis

Investigate the research questions and conduct suitable comparisons.

### Phase 5: Data Modeling

Build reusable SQL/dbt models, document definitions, and validate the analytical datasets.

### Phase 6: Tableau Dashboard Development

Define KPIs, create dashboard pages, add filters, and validate the results.

### Phase 7: Interpretation and Presentation

Summarize the findings, develop recommendations, explain limitations, and prepare the final presentation.

## 14. Final Project Positioning

This project combines customer experience analytics with seller acquisition analysis.

The customer satisfaction analysis is the central component because it investigates how delivery performance, freight costs, and product categories relate to customer review scores.

The marketing funnel provides an additional business perspective by examining how potential sellers progress through the acquisition process.

The two analyses will be connected only if the available data supports a reliable relationship.

The objective is to transform data into actionable insights that can support better customer experiences and more effective seller acquisition.

**Final Project Title:**

*From Delivery to Loyalty: Understanding Customer Satisfaction and Marketing Performance in E-Commerce*
