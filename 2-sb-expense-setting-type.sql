-- Types of expenses that can be entered into sb_summary table:
CREATE TABLE sb_expense_type (
    id INT NOT NULL AUTO_INCREMENT,
    expense_type varchar(255),
    access_level ENUM('admin', 'all', 'sync') DEFAULT 'admin',
    PRIMARY KEY (id)
);

-- Default values
INSERT INTO sb_expense_type (expense_type, access_level)
VALUES ('Deposit', 'admin'), ('Withdrawal', 'admin'), ('Replenishment', 'admin'), ('Inventory', 'admin'), ('Correction', 'admin'), ('Company Expense', 'admin'), ('Warehouse Expense', 'all'), ('Company Order', 'sync'), ('Warehouse Order', 'sync');
