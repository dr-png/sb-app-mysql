SELECT
    oc_o.order_id,
    oc_o.date_added,
    oc_os.name AS order_status,
    oc_o.shipping_country,
    oc_o.shipping_country_id,
    sb_s_ot.order_type,
    oc_o.shipping_method,
    COALESCE(SUM(oc_op.quantity), 0) AS product_count,
    ABS(sb_s.stock_value) as product_cost,
    -- profit per unit
    CASE 
        WHEN sb_s_ot.order_type IN ('retail', 'reship_retail') THEN
            COALESCE(sb_ps_country_retail.price_per_unit, sb_ps_default_retail.price_per_unit, 0) * COALESCE(SUM(oc_op.quantity), 0)
        WHEN sb_s_ot.order_type IN ('wholesale', 'reship_wholesale') THEN
            COALESCE(sb_ps_country_wholesale.price_per_unit, sb_ps_default_wholesale.price_per_unit, 0) * COALESCE(SUM(oc_op.quantity), 0)
        ELSE 0
    END AS profit_per_unit,
    -- profit per order
    CASE
        WHEN sb_s_ot.order_type IN ('retail', 'reship_retail') THEN
            COALESCE(sb_ps_country_retail.price_per_order, sb_ps_default_retail.price_per_order, 0)
        WHEN sb_s_ot.order_type IN ('wholesale', 'reship_wholesale') THEN
            COALESCE(sb_ps_country_wholesale.price_per_order, sb_ps_default_wholesale.price_per_order, 0)
        ELSE 0
    END AS profit_per_order,
    -- total value
    CASE
        WHEN sb_s_ot.order_type IN ('retail', 'reship_retail', 'wholesale', 'reship_wholesale') THEN
            (
                CASE 
                    WHEN sb_s_ot.order_type IN ('retail', 'reship_retail') THEN
                        COALESCE(sb_ps_country_retail.price_per_order, sb_ps_default_retail.price_per_order, 0)
                    WHEN sb_s_ot.order_type IN ('wholesale', 'reship_wholesale') THEN
                        COALESCE(sb_ps_country_wholesale.price_per_order, sb_ps_default_wholesale.price_per_order, 0)
                    ELSE 0
                END
            ) +
            (
                CASE 
                    WHEN sb_s_ot.order_type IN ('retail', 'reship_retail') THEN
                        COALESCE(sb_ps_country_retail.price_per_unit, sb_ps_default_retail.price_per_unit, 0) * COALESCE(SUM(oc_op.quantity), 0)
                    WHEN sb_s_ot.order_type IN ('wholesale', 'reship_wholesale') THEN
                        COALESCE(sb_ps_country_wholesale.price_per_unit, sb_ps_default_wholesale.price_per_unit, 0) * COALESCE(SUM(oc_op.quantity), 0)
                    ELSE 0
                END
            )
        ELSE 0
    END AS total_value,
    sb_s.profit AS total_revenue
FROM
    oc_order AS oc_o
    LEFT JOIN oc_order_status AS oc_os ON oc_o.order_status_id = oc_os.order_status_id
    AND oc_os.language_id = 1
    LEFT JOIN sb_summary_order_type AS sb_s_ot ON oc_o.order_id = sb_s_ot.order_id
    LEFT JOIN oc_order_product AS oc_op ON oc_o.order_id = oc_op.order_id
    LEFT JOIN sb_summary AS sb_s ON oc_o.order_id = sb_s.order_number
    LEFT JOIN sb_payout_setting AS sb_ps_country_retail 
        ON sb_s_ot.order_type IN ('retail', 'reship_retail')
        AND sb_ps_country_retail.order_type_id = 1
        AND sb_ps_country_retail.country_id = oc_o.shipping_country_id
    LEFT JOIN sb_payout_setting AS sb_ps_default_retail
        ON sb_s_ot.order_type IN ('retail', 'reship_retail')
        AND sb_ps_default_retail.order_type_id = 1
        AND sb_ps_default_retail.country_id <=> NULL
    LEFT JOIN sb_payout_setting AS sb_ps_country_wholesale
        ON sb_s_ot.order_type IN ('wholesale', 'reship_wholesale')
        AND sb_ps_country_wholesale.order_type_id = 2
        AND sb_ps_country_wholesale.country_id = oc_o.shipping_country_id
    LEFT JOIN sb_payout_setting AS sb_ps_default_wholesale
        ON sb_s_ot.order_type IN ('wholesale', 'reship_wholesale')
        AND sb_ps_default_wholesale.order_type_id = 2
        AND sb_ps_default_wholesale.country_id <=> NULL
WHERE
    oc_o.order_status_id = 3
GROUP BY
    oc_o.order_id,
    oc_o.date_added,
    oc_os.name,
    oc_o.shipping_country,
    sb_s_ot.order_type,
    oc_o.shipping_method,
    sb_s.stock_value,
    sb_s.profit,
    sb_ps_country_retail.price_per_unit,
    sb_ps_default_retail.price_per_unit,
    sb_ps_country_wholesale.price_per_unit,
    sb_ps_default_wholesale.price_per_unit,
    sb_ps_country_retail.price_per_order,
    sb_ps_default_retail.price_per_order,
    sb_ps_country_wholesale.price_per_order,
    sb_ps_default_wholesale.price_per_order;
