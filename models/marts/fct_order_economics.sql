with 

orders as (

    select

        ----------  ids
        order_id,
        location_id,

        ---------- timestamps
        order_date

    from {{ ref('stg_ecom__orders') }}

),

order_economics as (

    select

        ----------  ids
        order_id,

        ---------- numerics
        item_count,
        order_revenue,
        order_supply_cost,
        round((order_revenue - order_supply_cost), 2) as estimated_contribution_margin,
        round(((order_revenue - order_supply_cost) / NULLIF(order_revenue,0)) * 100, 2) as estimated_contribution_margin_pct,
        perishable_supply_cost,
        round((perishable_supply_cost / NULLIF(order_supply_cost,0)) * 100, 2) as perishable_cost_share

    from {{ ref('int_order_line_aggregates') }}

),

joined as (

    select
        
        orders.location_id,
        orders.order_date,
        order_economics.*

    from order_economics

    left join orders
        on order_economics.order_id = orders.order_id

)

select * from joined