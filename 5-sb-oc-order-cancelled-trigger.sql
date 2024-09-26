CREATE TRIGGER insert_into_sb_summary_on_oc_order_cancelled
AFTER UPDATE ON oc_order
FOR EACH ROW
BEGIN
    -- Iteration variables
    DECLARE sb_summary_id_var INT;

    -- Check if the order_status_id has changed to 7
    IF NEW.order_status_id = 7 AND OLD.order_status_id != 7 THEN

        SELECT sb_summary_id
        INTO sb_summary_id_var
        FROM sb_summary_order_type
        WHERE order_id = NEW.order_id;

        IF sb_summary_id_var > 0 THEN
            UPDATE sb_summary
            SET stock_value = 0.0000,
                profit = 0.0000,
                text_comment = 'Order cancelled'
            WHERE id = sb_summary_id_var;
        END IF;
    END IF;
END;
