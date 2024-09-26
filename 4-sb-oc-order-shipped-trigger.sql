CREATE TRIGGER insert_into_sb_summary_on_oc_order_shipped
AFTER UPDATE ON oc_order
FOR EACH ROW
BEGIN
    -- Iteration variables
    DECLARE payment_company_var VARCHAR(60);
    DECLARE order_type_id_var INT;
    DECLARE p_per_order_var DECIMAL(15,4);
    DECLARE p_per_unit_var DECIMAL(15,4);
    DECLARE profit_var DECIMAL(15,4);
    DECLARE expense_type_id_var INT;
    DECLARE quantity_var INT;
    DECLARE order_units_stock_value_var DECIMAL(15,4);
    DECLARE stock_value_var DECIMAL(15,4);
    DECLARE sb_summary_id_var INT;

    -- Check if the order_status_id has changed to 3
    IF NEW.order_status_id = 3 AND OLD.order_status_id != 3 THEN

        SET payment_company_var = NEW.payment_company;

        -- Determine order_type_id based on the oc_order.payment_company
        IF payment_company_var IN ('retail', 'reship_retail') THEN
            SET order_type_id_var = 1; -- sb_payout_setting_order_type.id = 1
        ELSEIF payment_company_var IN ('wholesale', 'reship_wholesale') THEN
            SET order_type_id_var = 2; -- sb_payout_setting_order_type.id = 2
        ELSE
            SET order_type_id_var = NULL;
        END IF;

        -- Get the quantity of the products in the order
        SELECT COALESCE(SUM(quantity), 0)
        INTO quantity_var
        FROM oc_order_product
        WHERE order_id = NEW.order_id;

        -- Perform the SELECT query to get price_per_order dynamically based on order_type
        -- 'retail' with 'reship_retail', as well as 'wholesale' with 'reship_wholesale' are treated the same
        IF order_type_id_var IN (1, 2) THEN
            SELECT price_per_order, price_per_unit
            INTO p_per_order_var, p_per_unit_var
            FROM (
                (SELECT *
                FROM sb_payout_setting 
                WHERE order_type_id = order_type_id_var -- sb_payout_setting_order_type.id (retail = 1 or wholesale = 2)
                AND country_id = NEW.shipping_country_id 
                LIMIT 1)
                UNION ALL
                (SELECT * 
                FROM sb_payout_setting 
                WHERE order_type_id = order_type_id_var -- sb_payout_setting_order_type.id (retail = 1 or wholesale = 2)
                AND country_id <=> NULL 
                LIMIT 1)
            ) as result
            LIMIT 1;

            -- Set profit per order
            SET profit_var = p_per_order_var  + (quantity_var * p_per_unit_var);
        ELSE
            -- Set profit to 0 for 'reship_rms' orders and any other not handled cases
            SET profit_var = 0;
        END IF;

        -- Calculate order value using warehouse prices
        SELECT COALESCE(SUM(op.quantity * oc.cost), 0)
        INTO order_units_stock_value_var
        FROM oc_order_product AS op
        LEFT JOIN oc_product_cost AS oc
        ON op.product_id = oc.product_id
        WHERE op.order_id = NEW.order_id;

        SET profit_var = profit_var + order_units_stock_value_var;
        SET stock_value_var = 0 - order_units_stock_value_var;

        -- Determine the expense_type_id (sb_expense_type.id) based on the length of the order_id
        IF LENGTH(NEW.order_id) >= 6 THEN
            SET expense_type_id_var = 8; -- company order expense_type_id 8 (or sb_expense_type.id = 8)
        ELSE
            SET expense_type_id_var = 9; -- warehouse order expense_type_id 9 (or sb_expense_type.id = 9)
            SET profit_var = 0; -- Set profit to 0 for warehouse orders
            SET payment_company_var = 'warehouse_order'; -- Set payment_company to 'warehouse_order' for warehouse orders
        END IF;

        IF payment_company_var = 'reship_rms' THEN
            SET profit_var = 0; -- Set profit to 0 for reship due to warehouse mistake
        END IF;

        -- Check if order already exists in sb_summary_order_type
        SELECT sb_summary_id
        INTO sb_summary_id_var
        FROM sb_summary_order_type
        WHERE order_id = NEW.order_id;

        IF sb_summary_id_var > 0 THEN
            UPDATE sb_summary
            SET 
                expense_type_id = expense_type_id_var,
                stock_value = stock_value_var,
                profit = profit_var,
                text_comment = ''
            WHERE id = sb_summary_id_var;
        ELSE
            INSERT INTO sb_summary (expense_type_id, order_number, date_added, stock_value, profit)
            VALUES (expense_type_id_var, NEW.order_id, NEW.date_added, stock_value_var, profit_var);
            
            SELECT LAST_INSERT_ID() 
            INTO sb_summary_id_var;
        END IF;

        IF payment_company_var NOT IN ('retail', 'reship_retail', 'wholesale', 'reship_wholesale', 'reship_rms', 'warehouse_order') THEN
            UPDATE sb_summary
            SET 
                text_comment = 'ERROR: missing payment_company',
                stock_value = 0,
                profit = 0
            WHERE id = sb_summary_id_var;

            SET payment_company_var = 'ERROR';
        END IF;

        IF payment_company_var = 'reship_rms' THEN
            UPDATE sb_summary
            SET text_comment = 'Reship due to warehouse oversight'
            WHERE id = sb_summary_id_var;
        END IF;

        -- Upsert into sb_summary_order_type
        INSERT INTO sb_summary_order_type (order_id, order_type, sb_summary_id, country_id)
        VALUES (NEW.order_id, payment_company_var, sb_summary_id_var, NEW.shipping_country_id)
        ON DUPLICATE KEY UPDATE
            order_type = VALUES(order_type),
            sb_summary_id = VALUES(sb_summary_id),
            country_id = VALUES(country_id);
    END IF;
END;
