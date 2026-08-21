# Jaffle Shop Order Economics: Estimated Contribution Margin & Perishable Cost Analysis
 
**dbt · SQL + Google BigQuery · Git/GitHub**
 
---
 
## Overview
 
This project builds a dbt pipeline on top of the Jaffle Shop sample dataset to answer a specific operational question: where is a food-service business leaking margin, and does the mix of perishable ingredients in an order help explain the difference? Raw order, product, and supply data is transformed through a staging → intermediate → marts architecture into two analysis-ready tables, validated with a layered testing strategy, and queried directly to produce the findings below.
 
## Business Question
 
> Which Jaffle Shop stores and products generate the strongest estimated contribution margins, and does the proportion of an order's supply cost attributable to perishable-supply-sourced components correlate with different margins?
 
**Objective:** identify where the business is leaking margin — which stores and products underperform on profitability, and whether perishable-ingredient sourcing is a meaningful cost driver worth addressing through pricing, sourcing, or menu-mix decisions.
 
**What this analysis actually answers:** the perishable-cost-share question is answered directly, with a strong result. The store-comparison question is supported by a fully built and tested model, but the available order data is concentrated at a single store, so no cross-store comparison is currently possible. The product-ranking question is not yet answered — the underlying data exists in `int_item_costs`, but no product-level rollup or query was produced in this pass. See **Limitations** and **Next Steps**.
 
---
 
## Insights:
 
- **Perishable cost share is strongly associated with lower margin.** Across 686 orders, `perishable_cost_share` and `estimated_contribution_margin_pct` have a correlation of **−0.77**. Orders in the bottom quartile of perishable cost share average **86.4% margin**; orders in the top quartile average **69.7%** — a 17-point gap. This is a real, sizable pattern, not noise from a handful of orders.
- **This is an association, not an isolated causal effect.** Estimated contribution margin is mechanically derived from total supply cost, and perishable cost share is a component of that same cost. It's plausible that perishable-heavy products (e.g. jaffles) simply carry higher total supply costs for reasons beyond perishability itself, in which case product mix — not perishability specifically — may be the more direct driver. This wasn't tested directly (no product-level output was produced), so the finding is stated as a correlation, not a confirmed cause.
- **Store comparison isn't possible with the current data.** `agg_store_economics` is fully built and tested, but all 686 orders in this dataset belong to a single store (Philadelphia). That store shows $6,818 in total revenue, $1,405.72 in total supply cost, and a 79.4% store-level contribution margin — a real number, but not comparable at this timee.
---
 
## Dataset
 
Curated Jaffle Shop sample data (six raw tables: customers, orders, items, products, supplies, stores), loaded via dbt seed into BigQuery. `raw_customers` was scoped out — not relevant to a store/product margin question. Order data in this sample spans September 1–16, 2016 (686 orders).
 
## Tech Stack
 
| Layer | Tool |
|---|---|
| Transformation | dbt (Fusion engine) |
| Warehouse | Google BigQuery |
| Version control | Git / GitHub |
| Testing | dbt schema tests + custom singular tests |
 
## Project Architecture
 
```
seeds (raw CSVs)
  └── staging (stg_ecom__*)          — cleaned, typed, renamed
        └── intermediate
              ├── int_item_costs                — order-item grain
              └── int_order_line_aggregates      — order grain
                    └── marts
                          ├── fct_order_economics    — order grain
                          └── agg_store_economics     — store grain
```
 
### Key models
 
- **`int_item_costs`** — one row per order item. Joins each item to its product's selling price and to that product's supply cost, aggregated from `raw_supplies` (a single product draws cost from multiple supply components, not one).
- **`int_order_line_aggregates`** — one row per order. Rolls item-level economics up to order totals: revenue, supply cost, perishable-sourced cost, item count. Kept as raw sums rather than pre-computed ratios, so later aggregation stays mathematically correct.
- **`fct_order_economics`** — one row per order. The primary, independently queryable fact table: computes estimated contribution margin, margin percentage, and perishable cost share, joined to order date and store.
- **`agg_store_economics`** — one row per store. Aggregates order economics to store grain, using a dollar-weighted margin percentage (total margin ÷ total revenue) rather than an average of per-order percentages, since the two are not interchangeable.
### Key metrics
 
| Metric | Definition |
|---|---|
| Order revenue | Sum of per-unit selling prices across an order's items |
| Order supply cost | Sum of supply component costs across an order's items |
| Estimated contribution margin | Revenue − supply cost. **Not profit** — excludes labor, overhead, rent, and tax, which this dataset doesn't capture |
| Estimated contribution margin % | Margin as a percentage of revenue |
| Perishable supply cost | Portion of supply cost from components flagged perishable |
| Perishable cost share | Perishable supply cost ÷ total supply cost |
 
## Testing & Data Quality
 
- Grain-defining keys (`order_item_id`, `order_id`, `location_id`) tested `unique` + `not_null`.
- Foreign keys used in joins tested `not_null` + `relationships` against their parent table, protecting against silent `NULL`-producing join failures.
- Two singular tests on `fct_order_economics`: a regression guard confirming the margin column matches its own defining formula, and a business invariant confirming supply cost never exceeds revenue.
- Deliberately not tested: purely descriptive columns and values guaranteed correct by construction (e.g. an aggregate's grouping key).
## Limitations
 
- **Single-store data.** All 686 orders in this dataset belong to one of six defined stores. `agg_store_economics` is correct and ready to compare stores the moment order data spans more than one location.
- **Narrow time window.** Order data covers only September 1–16, 2016.
- **No product-level output.** The product half of the original question isn't answered — see Next Steps.
- **Perishability and product mix are entangled.** The strong perishable-cost-share finding may partly reflect product category rather than perishability specifically; this wasn't isolated.
- **Not a full profitability measure.** Estimated contribution margin excludes labor, overhead, rent, and tax by necessity of the source data.
## Next Steps:
 
- Build a lightweight product-level aggregation from `int_item_costs` to rank products by margin, closing the one part of the original question not yet answered.
- Stratify the perishable-cost-share finding by product type to test whether the relationship holds independent of product mix.
- Re-run the store comparison once order data spans more than one location.
## How to Run
 
```bash
dbt seed
dbt build
```
 
Requires a BigQuery connection profile matching the `profile:` value in `dbt_project.yml`. See `docs/plan.md` for the full analytical plan and metric rationale.
 
## Repository Structure
 
```
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── seeds/
├── tests/
├── docs/
│   └── plan.md
└── README.md
```
 
---
 
Built as part of the dbt Analytics Engineering certification pathway.