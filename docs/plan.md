# Plan

## Question
Which Jaffle Shop stores and products generate the strongest estimated contribution margins, and does the proportion of perishable-supply-sourced items in an order correlate with different margins?

## Business objective
Identify where the business is leaking margin — which stores underperform on profitability despite comparable order volume, and whether perishable-ingredient sourcing is a meaningful cost driver worth addressing through pricing, sourcing, or menu-mix decisions.

## Scope (v1)
In v1, we will answer exactly two questions:
1. Which stores generate the highest and lowest average estimated contribution margin per order?
2. Do orders with a higher share of perishable-supply-sourced items show a different average margin than orders with a lower share?

## Inputs
We will use the minimum set of raw sources required to answer the v1 questions, referenced via dbt `source()` declarations.

### Required
- `raw_orders` — order grain, subtotal, store linkage
- `raw_items` — bridges orders to products at line-item grain
- `raw_products` — selling price and SKU per product
- `raw_supplies` — cost and perishability per supply component, linked to products via SKU (grain: one row per supply-per-product combination)
- `raw_stores` — store dimension (name, tax rate, open date)

### Explicitly out of scope
- `raw_customers` — not relevant to a store/product margin question; no customer-level analysis in v1

## Metric definitions
- **Revenue**: `raw_products.price`, the per-unit selling price
- **Supply cost**: `raw_supplies.cost`, summed across all supply rows sharing a product's SKU (confirmed necessary — a single product draws cost from multiple supply components, not one)
- **Estimated contribution margin**: revenue − summed supply cost, at the item level, rolled up to order and store. This is deliberately *not* called "profit" — it excludes labor, overhead, rent, and tax. Tax is a pass-through and is excluded from the calculation entirely.
- **Perishable item**: an order item is treated as perishable-sourced if *any* of its associated supply rows has `is_perishable_supply = true`. (Alternative definitions — e.g. majority-perishable — were considered and rejected for v1 in favor of simplicity and interpretability.)
- **Perishable item share**: count of perishable items in an order ÷ total items in the order (item-count basis, not cost-weighted — see Next-loop ideas below).

## Output models

### Intermediate models

**`int_item_costs`**
Grain: one row per order item.
Joins `stg_order_items` → `stg_products` → `stg_supplies` (cost summed by product). Computes item-level revenue, item-level cost, and an `is_perishable_item` flag.

**`int_order_line_aggregates`**
Grain: one row per order.
Aggregates `int_item_costs` up to order grain: total revenue, total cost, item count, perishable item count.

### Final marts

**`fct_order_economics`**
Grain: one row per order.
Contains: `order_id`, `location_id`, `order_date`, `item_count`, `order_revenue`, `order_supply_cost`, `estimated_contribution_margin`, `estimated_contribution_margin_pct`, `perishable_item_count`, `perishable_item_share`.
This is the primary, independently queryable fact table — not an intermediate step — since it's the correct grain for direct analysis of individual orders (including subquestion 2, answered by querying this table directly rather than building a separate model for it).

**`agg_store_economics`**
Grain: one row per store.
Contains: `location_id`, `location_name`, `order_count`, `total_revenue`, `total_supply_cost`, `total_estimated_contribution_margin`, `avg_margin_per_order`, `avg_margin_pct`.
Answers subquestion 1 directly.

## Acceptance criteria (definition of done)
- `dbt build` passes for all new models and their tests.
- `estimated_contribution_margin` is never a value that would imply cost exceeding revenue by an implausible margin (flagged via singular test, threshold to be set during Test phase based on observed data).
- Store-level margin figures differ meaningfully across stores, and the difference can be explained by drilling into `fct_order_economics`.
- `perishable_item_share` and margin show either a clear relationship or a clear absence of one — both are valid, reportable findings.
- Every model has a description; every key/join column has appropriate tests (uniqueness, not-null, referential integrity).

## Assumptions & edge cases
- `raw_products.price` is treated as constant across all historical orders — no price-history table exists in this schema.
- Supply cost is a flat per-unit cost regardless of which product uses it (confirmed directly from the data — e.g. one supply component costs the same across every product it appears in).
- Contribution margin excludes labor, overhead, and rent by necessity — the schema doesn't include these, so the metric is an intentional proxy, not GAAP profit.
- If we discover missing product/supply links, duplicated items, or orders with zero items, we will document the issue and its handling rather than silently dropping rows.

## Next-loop ideas (explicitly out of scope for v1)
- Cost-weighted perishable share (perishable-sourced revenue ÷ total order revenue) as a more economically precise alternative to the count-based share used here.
- Store-level perishable-share overlay in `agg_store_economics`, if Analyze-phase findings suggest it's a meaningful angle.
- Product-type-level margin breakdown (jaffle vs. beverage), not just store-level.