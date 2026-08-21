select *
from {{ ref('fct_order_economics') }}
where round(estimated_contribution_margin, 2) != round(order_revenue - order_supply_cost, 2)