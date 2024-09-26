-- Payout settings per order type and country
CREATE TABLE sb_payout_setting_order_type (
    id INT NOT NULL AUTO_INCREMENT,
    order_type varchar(128),
	PRIMARY KEY (id)
);

-- Default values
INSERT INTO sb_payout_setting_order_type (order_type)
VALUES ('retail'), ('wholesale');

-- Payout settings per order type and country
-- The country_id is NULL for the default values
-- Only one record per order_type_id and country_id
CREATE TABLE sb_payout_setting (
    id INT NOT NULL AUTO_INCREMENT,
    order_type_id INT NOT NULL, -- sb_payout_setting_order_type.id
    country_id INT DEFAULT NULL,
    price_per_order DECIMAL(15,4) DEFAULT 0.0000,
    price_per_unit DECIMAL(15,4) DEFAULT 0.0000,
    currency_id INT DEFAULT 3,
    PRIMARY KEY (id),
    FOREIGN KEY (order_type_id) REFERENCES sb_payout_setting_order_type(id),
    UNIQUE (order_type_id, country_id)
);

-- Default values
INSERT INTO sb_payout_setting (order_type_id, country_id)
VALUES (1, NULL), (2, NULL);
