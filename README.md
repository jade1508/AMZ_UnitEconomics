# Amazon Unit Economics Dashboard

## The problem

Brand Managers on Amazon need a weekly answer to one question: *"Which SKUs are quietly losing money, and why?"* Sales price alone doesn't tell you that - you need to net out FBA fulfillment fees, referral commission, cost of goods sold (COGS), and VAT, all of which live in different systems and change weekly. Without a single view of this, margin erosion goes unnoticed until it shows up in the P&L weeks later.

## What I built

An ASIN/SKU-level unit economics pipeline, built end-to-end from raw source data to a Looker-ready semantic layer - no data engineering team involved.

**Data sources (pulled and joined via SQL in BigQuery):**
- Amazon Fee Preview Report (`fact_AMZ_FeePreviewReport`) - weekly fulfillment, small-and-light, and commission fees per SKU/marketplace
- COGS data (`fact_cogs`) - weekly cost of goods sold per SKU/marketplace
- VAT rates by country (`vat_rates`) - expanded into a daily calendar per country so every week gets matched to the VAT rate that was actually in effect at that time
- Marketplace mapping table - to align currency and marketplace naming conventions across sources

**Pipeline logic:**
1. Built a `periods` CTE that explodes each country's VAT rate validity window into individual ISO weeks, so historical VAT changes are applied correctly rather than using today's rate retroactively.
2. Joined fee, COGS, and VAT data together on SKU, marketplace, ISO week, and ISO year - with currency validation to prevent silent mismatches.
3. Calculated sales price excluding VAT, then derived **payout** (sales price − fulfillment fee − commission − COGS) and four ratio metrics: fulfillment %, commission %, COGS %, and payout % of sales.
4. Output written to a partitioned, clustered BigQuery table (`AMZ_UnitEconomics`, partitioned by month, clustered by business/brand) to keep the weekly refresh fast at scale.

**Semantic layer (LookML):**
- Built a derived table that deduplicates to the latest snapshot per business/marketplace/SKU (`ROW_NUMBER() OVER (PARTITION BY business, marketplaceName, sku ORDER BY date DESC)`), filtered to exclude SKUs with missing COGS data (bad data shouldn't silently show as 100% margin).
- Added a categorical `payout_filter` dimension bucketing SKUs into <15%, 15–25%, 25–30%, and ≥30% payout bands - so Brand Managers can filter straight to the SKUs that need attention instead of scanning a raw number column every week.

## How it's meant to be used

**Best practice:** Brand Managers / Regional Operations Managers check weekly for any ASIN where payout % falls below 25%.

Payout % only reflects unit economics - full profitability still depends on PPC spend, 3PL costs, discounts, and other deal-related expenses layered on top. So a low payout % isn't automatically a problem if it's an intentional discontinuation or inventory clearance strategy.

When payout % is low outside of an intentional strategy, the framework guides the next step:
1. Check pricing - is there room to increase price given competition/BSR?
2. If price can't move, investigate whether FBA fee % or COGS % can be reduced (repackaging, resourcing) - a longer-term fix.
3. If neither is viable, flag the ASIN for sunset.

## Why this approach

I designed this specifically to avoid two failure modes I kept seeing in ad hoc margin spreadsheets: (1) using today's VAT rate to evaluate last month's sales, which silently misstates margin whenever a VAT rate changes, and (2) SKUs with missing COGS data showing up as artificially high-margin because a null gets treated as zero cost. Both are handled explicitly in the pipeline logic above rather than caught manually after the fact.

## Stack

BigQuery (SQL) for the transformation pipeline → Looker/LookML for the semantic layer and weekly reporting.
