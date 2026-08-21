# Plan
 
## Question
Which Jaffle Shop stores and products generate the strongest estimated contribution margins, and does the proportion of an order's supply cost attributable to perishable-supply-sourced components correlate with different margins?
 
## Business objective
Identify where the business is leaking margin — which stores and products underperform on profitability, and whether perishable-ingredient sourcing is a meaningful cost driver worth addressing through pricing, sourcing, or menu-mix decisions.
 
## Scope (v1)
1. Which stores and products generate the highest and lowest average estimated contribution margin per order?
2. Do orders with a higher share of perishable-supply-sourced costs show a different average margin than orders with a lower share?
## Inputs
- `raw_orders`, `raw_items`, `raw_products`, `raw_supplies`, `raw_stores` — referenced via dbt `source()` declarations.
- `raw_customers` — explicitly out of scope; not relevant to a store/product margin question.
## Metric definitions
- **Revenue**: `raw_products.price`, the per-unit selling price. Each order-item row represents exactly one unit (confirmed — no quantity field exists in the schema).
- **Supply cost**: `raw_supplies.cost`, summed across all supply rows sharing a product's SKU. Necessary because `raw_supplies` is grained one row per supply-per-product combination, not one row per product.
- **Estimated contribution margin**: revenue − summed supply cost. Deliberately not called "profit" — excludes labor, overhead, rent, and tax.
- **Perishable cost share**: perishable-sourced supply cost ÷ total supply cost, at whatever grain reported. Cost-weighted rather than count- or presence-based — an initial boolean formulation ("does the order contain any perishable component") was tested and discarded during Develop because it showed no meaningful variance: nearly all products contain at least one perishable ingredient. Cost varies widely by component (roughly $4–$13 for packaging vs. $13–$234 for ingredients), so cost share is the metric that actually distinguishes orders.
## Model architecture
 
**Staging** (`stg_orders`, `stg_order_items`, `stg_products`, `stg_supplies`, `stg_locations`) — thin, renamed/typed pass-throughs, referenced via `source()`. `stg_customers` intentionally removed (out of scope).
 
**`int_item_costs`** — grain: one row per order item. Joins order items to products (price) and to supplies pre-aggregated to product grain (summed cost, summed perishable-sourced cost).
 
**`int_order_line_aggregates`** — grain: one row per order. Aggregates `int_item_costs` to order grain: total revenue, total supply cost, total perishable-sourced cost, item count. Kept as raw dollar sums, not pre-computed ratios, so downstream aggregation stays mathematically correct.
 
**`fct_order_economics`** — grain: one row per order. Joins `int_order_line_aggregates` to `stg_orders` for store and date context; computes `estimated_contribution_margin`, `estimated_contribution_margin_pct`, and `perishable_cost_share`. The primary, independently queryable fact table — answers subquestion 2 directly via drill-down, no separate model needed.
 
**`agg_store_economics`** — grain: one row per store. Aggregates `fct_order_economics` to store grain: order count, total revenue, total supply cost, total margin, average margin per order (unweighted), and store-level margin percentage (dollar-weighted: total margin ÷ total revenue, not an average of per-order percentages — the two are not interchangeable). Answers subquestion 1, though see Limitations below.
 
## Testing strategy
- Grain-defining keys (`order_item_id`, `order_id`, `location_id` at their respective grains) tested `unique` + `not_null`.
- Foreign keys used in joins (`product_id`, `order_id` where used as a join key, `location_id`) tested `not_null` + `relationships` against their parent table — protects against silent `NULL`-producing join failures that a `LEFT JOIN` wouldn't otherwise surface.
- Two singular tests on `fct_order_economics`: (1) a business-logic invariant — `order_supply_cost` never exceeds `order_revenue`; (2) a regression guard — `estimated_contribution_margin` always equals a fresh recomputation of `order_revenue − order_supply_cost`, protecting against future drift if the model's calculation logic is edited.
- Deliberately not tested: purely descriptive columns (`product_name`, `location_name`) and columns whose correctness is guaranteed by construction (e.g. `order_id` in an aggregate model that can only ever contain values inherited from its own `GROUP BY`).
## Assumptions & limitations
- `raw_products.price` treated as constant across all historical orders — no price-history table exists.
- Supply cost is a flat per-unit cost regardless of which product uses it (confirmed directly from the data).
- Contribution margin excludes labor, overhead, and rent by necessity — an intentional proxy, not GAAP profit.
- **Store comparison data limitation**: `raw_stores`/`stg_locations` defines six stores, but verified directly against `stg_orders` that all 686 orders in this dataset belong to a single store. `agg_store_economics` is fully built, tested, and correct — it would produce a genuine multi-store comparison the moment order data spans more than one location — but with the current seed data, subquestion 1 is answered primarily through the product-level angle (product/product-type margin comparison via `int_item_costs`/`fct_order_economics`) rather than a cross-store comparison, since only one store currently has data to compare.
## Next-loop ideas
- Cross-store margin comparison, once order activity spans more than one store.
- Store-level perishable-cost-share overlay in `agg_store_economics`.
- Product-type-level margin breakdown as a standalone tracked metric rather than an ad-hoc Analyze-phase query.