with 

order_items as (

    select

        ----------  ids
        order_item_id,
        order_id,
        product_id

    from {{ ref('stg_ecom__order_items') }}

),

products as (

    select

        ----------  ids
        product_id,

        ---------- text
        product_name,
        product_type,

        ---------- numerics
        product_price,

        ---------- booleans
        is_food_item,
        is_drink_item

    from {{ ref('stg_ecom__products') }}

),

supplies as (

    select

        ----------  id
        product_id,

        ---------- numerics
        SUM(supply_cost) as product_cost,
        SUM(CASE WHEN is_perishable_supply IS TRUE THEN supply_cost ELSE 0 END) as perishable_cost

    from {{ ref('stg_ecom__supplies') }}

    group by 1

),

joined as (

    select

        order_items.*,
        products.product_name,
        products.product_type,
        products.product_price,
        supplies.product_cost,
        supplies.perishable_cost,
        products.is_food_item,
        products.is_drink_item

    from order_items

    left join products
        on order_items.product_id = products.product_id

    left join supplies
        on order_items.product_id = supplies.product_id

)

select * from joined