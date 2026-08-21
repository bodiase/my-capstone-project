with 

locations as (

    select

        ----------  ids
        location_id,

        ---------- text
        location_name
    
    from {{ ref('stg_ecom__locations') }}

 ),

order_economics as (

    select

        ----------  ids
        location_id,

        ---------- numerics
        COUNT(order_id) as order_count,
        SUM(order_revenue) as total_revenue,
        SUM(order_supply_cost) as total_supply_cost,
        SUM(estimated_contribution_margin) as total_estimated_contribution_margin,
        round(AVG(estimated_contribution_margin), 2) as avg_margin_per_order
        
    from {{ ref('fct_order_economics') }}

    group by 1

),

joined as (

    select
        
        order_economics.location_id,
        locations.location_name,
        order_economics.order_count,
        order_economics.total_revenue,
        order_economics.total_supply_cost,
        order_economics.total_estimated_contribution_margin,
        order_economics.avg_margin_per_order,
        (total_estimated_contribution_margin / NULLIF(total_revenue, 0)) * 100 as avg_margin_pct

    from order_economics

    left join locations
        on order_economics.location_id = locations.location_id

)

select * from joined