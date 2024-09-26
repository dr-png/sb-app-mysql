-- Expense and order summary table
CREATE TABLE sb_summary (
    id INT NOT NULL AUTO_INCREMENT,
    expense_type_id INT NOT NULL, -- sb_expense_type.id 
    order_number INT DEFAULT NULL,
    date_added DATETIME DEFAULT CURRENT_TIMESTAMP,
    stock_value DECIMAL(15,4) DEFAULT 0.0000,
    profit DECIMAL(15,4) DEFAULT 0.0000,
    currency_id INT DEFAULT 3,
    text_comment TEXT DEFAULT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (expense_type_id) REFERENCES sb_expense_type(id)
);

-- Order type table
-- Helper table for quick lookups of order type
CREATE TABLE sb_summary_order_type (
    id INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    order_type varchar(128), -- comes from oc_order.payment_company (retail, reship_retail, wholesale, reship_wholesale, reship_rms)
    sb_summary_id INT NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX idx_sb_order_id_unique (order_id)
);
