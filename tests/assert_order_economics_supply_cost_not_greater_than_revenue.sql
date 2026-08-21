{{ config(severity='warn') }}

select *
from {{ ref('fct_order_economics') }}
where order_supply_cost > order_revenue