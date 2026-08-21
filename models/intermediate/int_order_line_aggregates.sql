with 

order_line as (

    select

        ----------  ids
        order_id,

        ---------- numerics
        SUM(product_price) as order_revenue,
        SUM(product_cost) as order_supply_cost,
        SUM(perishable_cost) as perishable_supply_cost,
        COUNT(order_item_id) as item_count

    from {{ ref('int_item_costs') }}

    group by 1

)

select * from order_line