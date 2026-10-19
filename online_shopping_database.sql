-- ============================================================================
-- COSC 4110 - Database Concepts
-- Final Examination Database Project
-- Project: Online Shopping Management System
-- Student: Farkhadova Charoskhon
-- DBMS: MySQL 8.0+ / MySQL 8.4
-- ============================================================================

DROP DATABASE IF EXISTS online_shopping_db;
CREATE DATABASE online_shopping_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE online_shopping_db;

-- ============================================================================
-- 1. TABLE CREATION
-- ============================================================================

CREATE TABLE customers (
    customer_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name         VARCHAR(50) NOT NULL,
    last_name          VARCHAR(50) NOT NULL,
    email              VARCHAR(120) NOT NULL,
    phone              VARCHAR(25),
    password_hash      VARCHAR(255) NOT NULL,
    customer_status    ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customers_email UNIQUE (email)
) ENGINE = InnoDB;

CREATE TABLE addresses (
    address_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id        INT UNSIGNED NOT NULL,
    address_type       ENUM('HOME', 'WORK', 'OTHER') NOT NULL DEFAULT 'HOME',
    address_line1      VARCHAR(150) NOT NULL,
    address_line2      VARCHAR(150),
    city               VARCHAR(80) NOT NULL,
    region             VARCHAR(80),
    postal_code        VARCHAR(20),
    country            VARCHAR(80) NOT NULL DEFAULT 'Uzbekistan',
    is_default         BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE categories (
    category_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT UNSIGNED,
    category_name      VARCHAR(80) NOT NULL,
    description        VARCHAR(255),
    CONSTRAINT uq_categories_name UNIQUE (category_name),
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;

CREATE TABLE suppliers (
    supplier_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_name       VARCHAR(120) NOT NULL,
    contact_name       VARCHAR(100),
    email              VARCHAR(120),
    phone              VARCHAR(25),
    CONSTRAINT uq_suppliers_company UNIQUE (company_name),
    CONSTRAINT uq_suppliers_email UNIQUE (email)
) ENGINE = InnoDB;

CREATE TABLE products (
    product_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id        INT UNSIGNED NOT NULL,
    supplier_id        INT UNSIGNED NOT NULL,
    sku                 VARCHAR(40) NOT NULL,
    product_name        VARCHAR(150) NOT NULL,
    description         TEXT,
    unit_price          DECIMAL(10,2) UNSIGNED NOT NULL,
    cost_price          DECIMAL(10,2) UNSIGNED NOT NULL,
    reorder_level       INT UNSIGNED NOT NULL DEFAULT 5,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT chk_products_price CHECK (unit_price > 0),
    CONSTRAINT chk_products_cost CHECK (cost_price > 0),
    CONSTRAINT chk_products_margin CHECK (unit_price >= cost_price),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE inventory (
    product_id          INT UNSIGNED PRIMARY KEY,
    quantity_in_stock   INT UNSIGNED NOT NULL DEFAULT 0,
    quantity_reserved   INT UNSIGNED NOT NULL DEFAULT 0,
    last_updated        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_inventory_reserved
        CHECK (quantity_reserved <= quantity_in_stock),
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE coupons (
    coupon_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coupon_code         VARCHAR(30) NOT NULL,
    discount_type       ENUM('PERCENT', 'FIXED') NOT NULL,
    discount_value      DECIMAL(10,2) UNSIGNED NOT NULL,
    minimum_order       DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    usage_limit         INT UNSIGNED,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_coupons_code UNIQUE (coupon_code),
    CONSTRAINT chk_coupons_value CHECK (discount_value > 0),
    CONSTRAINT chk_coupons_percent
        CHECK (discount_type <> 'PERCENT' OR discount_value <= 100),
    CONSTRAINT chk_coupons_dates CHECK (end_date >= start_date)
) ENGINE = InnoDB;

CREATE TABLE orders (
    order_id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT UNSIGNED NOT NULL,
    shipping_address_id INT UNSIGNED NOT NULL,
    billing_address_id  INT UNSIGNED NOT NULL,
    order_date          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status        ENUM(
                            'PENDING', 'PAID', 'PROCESSING',
                            'SHIPPED', 'DELIVERED', 'CANCELLED'
                        ) NOT NULL DEFAULT 'PENDING',
    subtotal            DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0.00,
    shipping_fee        DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    tax_amount          DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0.00,
    notes               VARCHAR(255),
    CONSTRAINT chk_orders_total
        CHECK (total_amount = subtotal + shipping_fee + tax_amount - discount_amount),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_shipping_address
        FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_billing_address
        FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE order_items (
    order_item_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id            INT UNSIGNED NOT NULL,
    product_id          INT UNSIGNED NOT NULL,
    quantity            INT UNSIGNED NOT NULL,
    unit_price          DECIMAL(10,2) UNSIGNED,
    discount_amount     DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    CONSTRAINT uq_order_items_product UNIQUE (order_id, product_id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price CHECK (unit_price > 0),
    CONSTRAINT chk_order_items_discount
        CHECK (discount_amount <= quantity * unit_price),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE order_coupons (
    order_id            INT UNSIGNED NOT NULL,
    coupon_id           INT UNSIGNED NOT NULL,
    applied_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT fk_order_coupons_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_coupons_coupon
        FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE payments (
    payment_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id            INT UNSIGNED NOT NULL,
    payment_date        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount              DECIMAL(12,2) UNSIGNED NOT NULL,
    payment_method      ENUM('CARD', 'CASH', 'BANK_TRANSFER', 'E_WALLET') NOT NULL,
    payment_status      ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED') NOT NULL,
    transaction_reference VARCHAR(100),
    CONSTRAINT uq_payments_reference UNIQUE (transaction_reference),
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE shipments (
    shipment_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id            INT UNSIGNED NOT NULL,
    carrier_name        VARCHAR(100) NOT NULL,
    tracking_number     VARCHAR(100) NOT NULL,
    shipped_date        DATETIME,
    delivered_date      DATETIME,
    shipment_status     ENUM('PREPARING', 'IN_TRANSIT', 'DELIVERED', 'RETURNED')
                        NOT NULL DEFAULT 'PREPARING',
    CONSTRAINT uq_shipments_order UNIQUE (order_id),
    CONSTRAINT uq_shipments_tracking UNIQUE (tracking_number),
    CONSTRAINT chk_shipments_dates
        CHECK (delivered_date IS NULL OR shipped_date IS NULL OR delivered_date >= shipped_date),
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE reviews (
    review_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id          INT UNSIGNED NOT NULL,
    customer_id         INT UNSIGNED NOT NULL,
    rating              TINYINT UNSIGNED NOT NULL,
    review_title        VARCHAR(120),
    review_text         VARCHAR(1000),
    review_date         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reviews_customer_product UNIQUE (product_id, customer_id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- Indexes supporting frequent joins, filtering, and sorting.
CREATE INDEX idx_addresses_customer ON addresses(customer_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_supplier ON products(supplier_id);
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order_status ON payments(order_id, payment_status);
CREATE INDEX idx_reviews_product_rating ON reviews(product_id, rating);

-- ============================================================================
-- 2. STORED PROCEDURES
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_recalculate_order_totals(IN p_order_id INT UNSIGNED)
BEGIN
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_discount DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_shipping DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_tax DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_order_date DATE;

    SELECT DATE(order_date)
      INTO v_order_date
      FROM orders
     WHERE order_id = p_order_id;

    SELECT COALESCE(SUM(quantity * unit_price - discount_amount), 0.00)
      INTO v_subtotal
      FROM order_items
     WHERE order_id = p_order_id;

    SELECT COALESCE(SUM(
               CASE
                   WHEN c.is_active = TRUE
                    AND v_order_date BETWEEN c.start_date AND c.end_date
                    AND v_subtotal >= c.minimum_order
                   THEN CASE
                            WHEN c.discount_type = 'PERCENT'
                            THEN v_subtotal * c.discount_value / 100
                            ELSE c.discount_value
                        END
                   ELSE 0
               END
           ), 0.00)
      INTO v_discount
      FROM order_coupons oc
      JOIN coupons c ON c.coupon_id = oc.coupon_id
     WHERE oc.order_id = p_order_id;

    SET v_discount = LEAST(v_discount, v_subtotal);
    SET v_tax = ROUND((v_subtotal - v_discount) * 0.05, 2);

    IF v_subtotal = 0 THEN
        SET v_shipping = 0.00;
    ELSEIF v_subtotal - v_discount >= 100 THEN
        SET v_shipping = 0.00;
    ELSE
        SET v_shipping = 8.50;
    END IF;

    UPDATE orders
       SET subtotal = v_subtotal,
           shipping_fee = v_shipping,
           tax_amount = v_tax,
           discount_amount = v_discount,
           total_amount = v_subtotal + v_shipping + v_tax - v_discount
     WHERE order_id = p_order_id;
END$$

CREATE PROCEDURE sp_create_order(
    IN p_customer_id INT UNSIGNED,
    IN p_shipping_address_id INT UNSIGNED,
    IN p_billing_address_id INT UNSIGNED,
    IN p_notes VARCHAR(255)
)
BEGIN
    DECLARE v_valid_address_count INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_valid_address_count
      FROM addresses
     WHERE customer_id = p_customer_id
       AND address_id IN (p_shipping_address_id, p_billing_address_id);

    IF v_valid_address_count = 0
       OR (p_shipping_address_id <> p_billing_address_id AND v_valid_address_count <> 2) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Shipping and billing addresses must belong to the customer';
    END IF;

    INSERT INTO orders (
        customer_id, shipping_address_id, billing_address_id, notes
    )
    VALUES (
        p_customer_id, p_shipping_address_id, p_billing_address_id, p_notes
    );

    SELECT LAST_INSERT_ID() AS new_order_id;
END$$

CREATE PROCEDURE sp_add_order_item(
    IN p_order_id INT UNSIGNED,
    IN p_product_id INT UNSIGNED,
    IN p_quantity INT UNSIGNED
)
BEGIN
    INSERT INTO order_items (order_id, product_id, quantity)
    VALUES (p_order_id, p_product_id, p_quantity);
END$$

CREATE PROCEDURE sp_cancel_order(
    IN p_order_id INT UNSIGNED,
    IN p_reason VARCHAR(255)
)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT order_status
      INTO v_status
      FROM orders
     WHERE order_id = p_order_id
     FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order does not exist';
    ELSEIF v_status IN ('SHIPPED', 'DELIVERED', 'CANCELLED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This order cannot be cancelled';
    END IF;

    UPDATE orders
       SET order_status = 'CANCELLED',
           notes = CONCAT_WS(' | ', notes, CONCAT('Cancellation reason: ', p_reason))
     WHERE order_id = p_order_id;
END$$

CREATE PROCEDURE sp_customer_order_history(IN p_customer_id INT UNSIGNED)
BEGIN
    SELECT
        o.order_id,
        o.order_date,
        o.order_status,
        COUNT(oi.order_item_id) AS line_items,
        COALESCE(SUM(oi.quantity), 0) AS total_units,
        o.total_amount
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY
        o.order_id, o.order_date, o.order_status, o.total_amount
    ORDER BY o.order_date DESC;
END$$

-- ============================================================================
-- 3. TRIGGERS
-- ============================================================================

CREATE TRIGGER trg_order_items_before_insert
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_available INT DEFAULT -1;
    DECLARE v_active BOOLEAN DEFAULT FALSE;
    DECLARE v_order_status VARCHAR(20);

    SELECT order_status
      INTO v_order_status
      FROM orders
     WHERE order_id = NEW.order_id;

    IF v_order_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items may be added only to pending orders';
    END IF;

    SELECT p.unit_price, p.is_active,
           i.quantity_in_stock - i.quantity_reserved
      INTO v_price, v_active, v_available
      FROM products p
      JOIN inventory i ON i.product_id = p.product_id
     WHERE p.product_id = NEW.product_id;

    IF v_available = -1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product or inventory record does not exist';
    ELSEIF v_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Inactive products cannot be ordered';
    ELSEIF NEW.quantity > v_available THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient available inventory';
    END IF;

    IF NEW.unit_price IS NULL THEN
        SET NEW.unit_price = v_price;
    END IF;
END$$

CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE inventory
       SET quantity_reserved = quantity_reserved + NEW.quantity
     WHERE product_id = NEW.product_id;

    CALL sp_recalculate_order_totals(NEW.order_id);
END$$

CREATE TRIGGER trg_order_items_before_update
BEFORE UPDATE ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_available INT;
    DECLARE v_order_status VARCHAR(20);

    IF NEW.product_id <> OLD.product_id OR NEW.order_id <> OLD.order_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Move an item by deleting it and inserting a new row';
    END IF;

    SELECT order_status
      INTO v_order_status
      FROM orders
     WHERE order_id = OLD.order_id;

    IF v_order_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items may be changed only in pending orders';
    END IF;

    SELECT quantity_in_stock - quantity_reserved + OLD.quantity
      INTO v_available
      FROM inventory
     WHERE product_id = OLD.product_id;

    IF NEW.quantity > v_available THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient available inventory';
    END IF;
END$$

CREATE TRIGGER trg_order_items_after_update
AFTER UPDATE ON order_items
FOR EACH ROW
BEGIN
    UPDATE inventory
       SET quantity_reserved = quantity_reserved - OLD.quantity + NEW.quantity
     WHERE product_id = NEW.product_id;

    CALL sp_recalculate_order_totals(NEW.order_id);
END$$

CREATE TRIGGER trg_order_items_before_delete
BEFORE DELETE ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_order_status VARCHAR(20);

    SELECT order_status
      INTO v_order_status
      FROM orders
     WHERE order_id = OLD.order_id;

    IF v_order_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items may be deleted only from pending orders';
    END IF;
END$$

CREATE TRIGGER trg_order_items_after_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE inventory
       SET quantity_reserved = quantity_reserved - OLD.quantity
     WHERE product_id = OLD.product_id;

    CALL sp_recalculate_order_totals(OLD.order_id);
END$$

CREATE TRIGGER trg_order_coupons_after_insert
AFTER INSERT ON order_coupons
FOR EACH ROW
BEGIN
    CALL sp_recalculate_order_totals(NEW.order_id);
END$$

CREATE TRIGGER trg_order_coupons_after_delete
AFTER DELETE ON order_coupons
FOR EACH ROW
BEGIN
    CALL sp_recalculate_order_totals(OLD.order_id);
END$$

CREATE TRIGGER trg_orders_after_status_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status = 'SHIPPED' AND OLD.order_status <> 'SHIPPED' THEN
        UPDATE inventory i
        JOIN (
            SELECT product_id, SUM(quantity) AS quantity_to_ship
            FROM order_items
            WHERE order_id = NEW.order_id
            GROUP BY product_id
        ) x ON x.product_id = i.product_id
        SET i.quantity_in_stock = i.quantity_in_stock - x.quantity_to_ship,
            i.quantity_reserved = i.quantity_reserved - x.quantity_to_ship;
    ELSEIF NEW.order_status = 'CANCELLED' AND OLD.order_status <> 'CANCELLED' THEN
        UPDATE inventory i
        JOIN (
            SELECT product_id, SUM(quantity) AS quantity_to_release
            FROM order_items
            WHERE order_id = NEW.order_id
            GROUP BY product_id
        ) x ON x.product_id = i.product_id
        SET i.quantity_reserved = i.quantity_reserved - x.quantity_to_release;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- 4. SAMPLE DATA
-- Fictional records for academic demonstration only; no real contact details.
-- ============================================================================

INSERT INTO customers (
    customer_id, first_name, last_name, email, phone, password_hash, customer_status, created_at
) VALUES
    (1, 'Amina',   'Karimova',  'amina.karimova@example.com',   '+000000000101', '$2y$demo_hash_01', 'ACTIVE', '2026-03-02 09:15:00'),
    (2, 'Bekzod',  'Rahimov',   'bekzod.rahimov@example.com',   '+000000000102', '$2y$demo_hash_02', 'ACTIVE', '2026-03-05 11:20:00'),
    (3, 'Malika',  'Usmanova',  'malika.usmanova@example.com',  '+000000000103', '$2y$demo_hash_03', 'ACTIVE', '2026-03-10 16:40:00'),
    (4, 'Timur',   'Saidov',    'timur.saidov@example.com',     '+000000000104', '$2y$demo_hash_04', 'ACTIVE', '2026-03-18 14:10:00'),
    (5, 'Dilnoza', 'Tursunova', 'dilnoza.tursunova@example.com','+000000000105', '$2y$demo_hash_05', 'ACTIVE', '2026-04-01 10:05:00'),
    (6, 'Javohir', 'Aliyev',    'javohir.aliyev@example.com',   '+000000000106', '$2y$demo_hash_06', 'ACTIVE', '2026-04-07 13:25:00'),
    (7, 'Sabina',  'Nazarova',  'sabina.nazarova@example.com',  '+000000000107', '$2y$demo_hash_07', 'ACTIVE', '2026-04-15 18:00:00'),
    (8, 'Rustam',  'Kamilov',   'rustam.kamilov@example.com',   '+000000000108', '$2y$demo_hash_08', 'ACTIVE', '2026-05-03 12:30:00');

INSERT INTO addresses (
    address_id, customer_id, address_type, address_line1, address_line2,
    city, region, postal_code, country, is_default
) VALUES
    (1, 1, 'HOME', '12 Amir Temur Avenue',  'Apartment 18', 'Tashkent', 'Tashkent', '100000', 'Uzbekistan', TRUE),
    (2, 1, 'WORK', '45 Afrosiyob Street',   'Office 203',   'Tashkent', 'Tashkent', '100015', 'Uzbekistan', FALSE),
    (3, 2, 'HOME', '8 Buyuk Ipak Yuli',     'Apartment 7',  'Tashkent', 'Tashkent', '100077', 'Uzbekistan', TRUE),
    (4, 3, 'HOME', '22 Navoi Street',       NULL,           'Samarkand','Samarkand','140100', 'Uzbekistan', TRUE),
    (5, 4, 'HOME', '19 Mustaqillik Street', 'House 4',      'Bukhara',  'Bukhara',  '200100', 'Uzbekistan', TRUE),
    (6, 5, 'HOME', '31 Shota Rustaveli',    'Apartment 12', 'Tashkent', 'Tashkent', '100070', 'Uzbekistan', TRUE),
    (7, 6, 'HOME', '17 Beruniy Street',     NULL,           'Nukus',   'Karakalpakstan','230100','Uzbekistan', TRUE),
    (8, 7, 'HOME', '9 Babur Street',        'Apartment 26', 'Andijan', 'Andijan',  '170100', 'Uzbekistan', TRUE),
    (9, 8, 'HOME', '64 Fergana Road',       'Apartment 3',  'Tashkent', 'Tashkent', '100005', 'Uzbekistan', TRUE),
    (10, 8,'WORK', '7 Oybek Street',        'Business Center','Tashkent','Tashkent','100029','Uzbekistan', FALSE);

INSERT INTO categories (category_id, parent_category_id, category_name, description) VALUES
    (1, NULL, 'Electronics', 'Electronic devices and accessories'),
    (2, 1,    'Computers',   'Laptops, monitors, and computer equipment'),
    (3, 1,    'Mobile Accessories', 'Accessories for smartphones and tablets'),
    (4, NULL, 'Home and Kitchen', 'Products for everyday home use'),
    (5, NULL, 'Books',       'Printed books and learning materials'),
    (6, NULL, 'Gaming',      'Gaming peripherals and accessories'),
    (7, NULL, 'Personal Care','Personal care appliances');

INSERT INTO suppliers (
    supplier_id, company_name, contact_name, email, phone
) VALUES
    (1, 'TechSource Central Asia', 'Aziz Muradov',   'sales@techsource.example.com', '+000000001001'),
    (2, 'HomeLine Distribution',   'Nodira Akbarova','orders@homeline.example.com', '+000000001002'),
    (3, 'BookWorld Supply',        'Kamol Ergashev', 'supply@bookworld.example.com','+000000001003'),
    (4, 'GameGear Imports',        'Diana Lee',      'b2b@gamegear.example.com',    '+000000001004');

INSERT INTO products (
    product_id, category_id, supplier_id, sku, product_name, description,
    unit_price, cost_price, reorder_level, is_active
) VALUES
    (1,  2, 1, 'LAP-001', 'NovaBook Pro 14 Laptop',       '14-inch productivity laptop, 16 GB RAM, 512 GB SSD', 899.99, 690.00, 5, TRUE),
    (2,  2, 1, 'MON-002', 'VisionView 27-inch Monitor',   'QHD IPS monitor with adjustable stand',             279.99, 205.00, 6, TRUE),
    (3,  3, 1, 'CHG-003', 'VoltFast 65W USB-C Charger',   'Compact fast charger with two USB-C ports',          49.99,  28.00,10, TRUE),
    (4,  3, 1, 'PWB-004', 'PocketPower 20000 Power Bank', 'High-capacity power bank with fast charging',         59.99,  36.00, 8, TRUE),
    (5,  4, 2, 'BLD-005', 'KitchenPro Blender',           'Five-speed countertop blender',                       89.50,  55.00, 5, TRUE),
    (6,  4, 2, 'COF-006', 'MorningBrew Coffee Maker',     'Programmable 12-cup coffee maker',                    74.99,  44.00, 5, TRUE),
    (7,  5, 3, 'BOK-007', 'Database Systems Essentials',  'Introduction to relational database concepts',       54.95,  31.00, 6, TRUE),
    (8,  5, 3, 'BOK-008', 'Practical SQL with MySQL',     'Hands-on SQL programming guide',                      46.50,  26.00, 6, TRUE),
    (9,  6, 4, 'MSE-009', 'Phantom RGB Gaming Mouse',     'Lightweight gaming mouse with programmable buttons',  64.99,  39.00, 8, TRUE),
    (10, 6, 4, 'KEY-010', 'Strike TKL Mechanical Keyboard','Tenkeyless mechanical keyboard with RGB lighting',   99.99,  61.00, 7, TRUE),
    (11, 6, 4, 'HDS-011', 'Echo 7.1 Gaming Headset',      'Surround-sound headset with detachable microphone',   79.99,  48.00, 7, TRUE),
    (12, 7, 2, 'HDR-012', 'StyleAir Hair Dryer',          'Ionic hair dryer with three heat levels',             69.99,  41.00, 5, TRUE);

INSERT INTO inventory (
    product_id, quantity_in_stock, quantity_reserved
) VALUES
    (1, 12, 0), (2, 18, 0), (3, 50, 0), (4, 31, 0),
    (5, 14, 0), (6, 16, 0), (7, 22, 0), (8, 19, 0),
    (9, 35, 0), (10, 20, 0), (11, 24, 0), (12, 6, 0);

INSERT INTO coupons (
    coupon_id, coupon_code, discount_type, discount_value, minimum_order,
    start_date, end_date, usage_limit, is_active
) VALUES
    (1, 'WELCOME10', 'PERCENT', 10.00, 50.00,  '2026-01-01', '2026-12-31', 500, TRUE),
    (2, 'TECH25',    'FIXED',   25.00, 250.00, '2026-04-01', '2026-09-30', 200, TRUE),
    (3, 'SUMMER15',  'PERCENT', 15.00, 100.00, '2026-06-01', '2026-08-31', 300, TRUE);

INSERT INTO orders (
    order_id, customer_id, shipping_address_id, billing_address_id,
    order_date, order_status, notes
) VALUES
    (1,  1, 1, 1, '2026-04-12 10:15:00', 'PENDING', 'Call before delivery'),
    (2,  2, 3, 3, '2026-04-28 16:45:00', 'PENDING', NULL),
    (3,  3, 4, 4, '2026-05-09 12:10:00', 'PENDING', 'Deliver after 18:00'),
    (4,  4, 5, 5, '2026-05-21 09:30:00', 'PENDING', NULL),
    (5,  5, 6, 6, '2026-06-03 14:05:00', 'PENDING', NULL),
    (6,  1, 2, 1, '2026-06-17 11:25:00', 'PENDING', 'Ship to work address'),
    (7,  6, 7, 7, '2026-06-29 17:50:00', 'PENDING', NULL),
    (8,  7, 8, 8, '2026-07-05 13:40:00', 'PENDING', NULL),
    (9,  2, 3, 3, '2026-07-14 19:20:00', 'PENDING', 'Gift packaging requested'),
    (10, 3, 4, 4, '2026-07-19 15:00:00', 'PENDING', NULL);

-- Unit prices are automatically copied from products by the BEFORE INSERT trigger.
-- Inventory reservations and order totals are maintained by AFTER INSERT triggers.
INSERT INTO order_items (
    order_item_id, order_id, product_id, quantity, unit_price, discount_amount
) VALUES
    (1,  1, 1,  1, NULL, 0.00),
    (2,  1, 3,  2, NULL, 0.00),
    (3,  2, 2,  1, NULL, 0.00),
    (4,  2, 9,  1, NULL, 5.00),
    (5,  3, 10, 1, NULL, 0.00),
    (6,  3, 11, 1, NULL, 0.00),
    (7,  4, 5,  1, NULL, 0.00),
    (8,  4, 6,  1, NULL, 0.00),
    (9,  5, 7,  1, NULL, 0.00),
    (10, 5, 8,  1, NULL, 0.00),
    (11, 5, 3,  1, NULL, 0.00),
    (12, 6, 2,  2, NULL, 0.00),
    (13, 6, 4,  1, NULL, 0.00),
    (14, 7, 12, 1, NULL, 0.00),
    (15, 7, 4,  2, NULL, 0.00),
    (16, 8, 9,  2, NULL, 0.00),
    (17, 8, 10, 1, NULL,10.00),
    (18, 9, 6,  1, NULL, 0.00),
    (19, 9, 7,  2, NULL, 0.00),
    (20,10, 1,  1, NULL,50.00),
    (21,10,11, 1, NULL, 0.00),
    (22,10, 3,  1, NULL, 0.00);

INSERT INTO order_coupons (order_id, coupon_id) VALUES
    (1, 2),
    (3, 1),
    (6, 3),
    (8, 1);

-- Status changes demonstrate UPDATE operations and activate inventory triggers.
UPDATE orders SET order_status = 'PAID'       WHERE order_id IN (1, 2, 3, 5, 6, 7, 8, 10);
UPDATE orders SET order_status = 'PROCESSING' WHERE order_id IN (1, 2, 3, 5, 6, 8, 10);
UPDATE orders SET order_status = 'SHIPPED'    WHERE order_id IN (1, 2, 3, 6, 8, 10);
UPDATE orders SET order_status = 'DELIVERED'  WHERE order_id IN (1, 2, 6, 8, 10);
CALL sp_cancel_order(4, 'Customer changed the purchase decision');

INSERT INTO payments (
    payment_id, order_id, payment_date, amount, payment_method,
    payment_status, transaction_reference
) VALUES
    (1, 1, '2026-04-12 10:20:00', (SELECT total_amount FROM orders WHERE order_id = 1), 'CARD',          'COMPLETED', 'TXN-20260412-001'),
    (2, 2, '2026-04-28 16:50:00', (SELECT total_amount FROM orders WHERE order_id = 2), 'E_WALLET',      'COMPLETED', 'TXN-20260428-002'),
    (3, 3, '2026-05-09 12:16:00', (SELECT total_amount FROM orders WHERE order_id = 3), 'CARD',          'COMPLETED', 'TXN-20260509-003'),
    (4, 5, '2026-06-03 14:12:00', (SELECT total_amount FROM orders WHERE order_id = 5), 'BANK_TRANSFER', 'COMPLETED', 'TXN-20260603-005'),
    (5, 6, '2026-06-17 11:30:00', (SELECT total_amount FROM orders WHERE order_id = 6), 'CARD',          'COMPLETED', 'TXN-20260617-006'),
    (6, 7, '2026-06-29 18:01:00', (SELECT total_amount FROM orders WHERE order_id = 7), 'E_WALLET',      'COMPLETED', 'TXN-20260629-007'),
    (7, 8, '2026-07-05 13:46:00', (SELECT total_amount FROM orders WHERE order_id = 8), 'CARD',          'COMPLETED', 'TXN-20260705-008'),
    (8,10, '2026-07-19 15:07:00', (SELECT total_amount FROM orders WHERE order_id =10), 'CARD',          'COMPLETED', 'TXN-20260719-010');

INSERT INTO shipments (
    shipment_id, order_id, carrier_name, tracking_number,
    shipped_date, delivered_date, shipment_status
) VALUES
    (1, 1, 'UzPost Express', 'UZP-260412-001', '2026-04-13 09:00:00', '2026-04-15 14:20:00', 'DELIVERED'),
    (2, 2, 'BTS Express',    'BTS-260428-002', '2026-04-29 11:10:00', '2026-05-01 16:40:00', 'DELIVERED'),
    (3, 3, 'UzPost Express', 'UZP-260509-003', '2026-05-10 08:30:00', NULL,                  'IN_TRANSIT'),
    (4, 6, 'Fargo Courier',  'FAR-260617-006', '2026-06-18 10:00:00', '2026-06-19 12:15:00', 'DELIVERED'),
    (5, 8, 'BTS Express',    'BTS-260705-008', '2026-07-06 09:25:00', '2026-07-08 15:05:00', 'DELIVERED'),
    (6,10, 'UzPost Express', 'UZP-260719-010', '2026-07-20 08:50:00', '2026-07-22 17:30:00', 'DELIVERED');

INSERT INTO reviews (
    review_id, product_id, customer_id, rating, review_title, review_text, review_date
) VALUES
    (1, 1,  1, 5, 'Excellent laptop',    'Fast, light, and suitable for university work.', '2026-04-18 20:10:00'),
    (2, 3,  1, 4, 'Useful compact charger','Charges my laptop and phone quickly.',            '2026-04-18 20:15:00'),
    (3, 2,  2, 5, 'Sharp display',       'The QHD panel is clear and the stand is stable.',  '2026-05-04 19:25:00'),
    (4, 9,  2, 4, 'Good gaming mouse',   'Accurate sensor and comfortable shape.',           '2026-05-04 19:30:00'),
    (5, 10, 3, 5, 'Great keyboard',      'Responsive switches and a convenient TKL layout.','2026-05-16 17:05:00'),
    (6, 11, 3, 4, 'Clear sound',         'Good directional audio for games.',                '2026-05-16 17:12:00'),
    (7, 2,  1, 5, 'Ideal second monitor','Easy setup and strong image quality.',              '2026-06-22 21:00:00'),
    (8, 9,  7, 5, 'Perfect for FPS',     'Lightweight and responsive during long sessions.','2026-07-11 18:40:00'),
    (9, 10, 7, 4, 'Solid build',         'Good keyboard, although the software can improve.','2026-07-11 18:45:00'),
    (10,1,  3, 4, 'Strong performance',  'Handles database tools and daily tasks smoothly.','2026-07-24 14:35:00');

-- ============================================================================
-- 5. INSERT, UPDATE, AND DELETE DEMONSTRATION
-- This controlled transaction leaves the final sample dataset unchanged.
-- ============================================================================

START TRANSACTION;

INSERT INTO reviews (
    product_id, customer_id, rating, review_title, review_text
) VALUES (
    12, 8, 3, 'Temporary review', 'Row created for the DML demonstration.'
);

SET @demo_review_id = LAST_INSERT_ID();

UPDATE reviews
   SET rating = 4,
       review_title = 'Temporary updated review'
 WHERE review_id = @demo_review_id;

DELETE FROM reviews
 WHERE review_id = @demo_review_id;

COMMIT;

-- ============================================================================
-- 6. VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    o.order_status,
    COUNT(oi.order_item_id) AS line_items,
    COALESCE(SUM(oi.quantity), 0) AS total_units,
    o.subtotal,
    o.discount_amount,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
    o.order_id, o.order_date, c.first_name, c.last_name, c.email,
    o.order_status, o.subtotal, o.discount_amount,
    o.tax_amount, o.shipping_fee, o.total_amount;

CREATE OR REPLACE VIEW vw_product_sales AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    COALESCE(SUM(
        CASE WHEN o.order_status <> 'CANCELLED' THEN oi.quantity ELSE 0 END
    ), 0) AS units_ordered,
    COALESCE(SUM(
        CASE WHEN o.order_status <> 'CANCELLED'
             THEN oi.quantity * oi.unit_price - oi.discount_amount
             ELSE 0 END
    ), 0.00) AS gross_sales
FROM products p
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id
GROUP BY p.product_id, p.sku, p.product_name, c.category_name;

CREATE OR REPLACE VIEW vw_low_stock_products AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    i.quantity_in_stock,
    i.quantity_reserved,
    i.quantity_in_stock - i.quantity_reserved AS available_quantity,
    p.reorder_level
FROM products p
JOIN inventory i ON i.product_id = p.product_id
WHERE i.quantity_in_stock - i.quantity_reserved <= p.reorder_level;

-- ============================================================================
-- 7. COMPLEX QUERIES
-- Run each query in MySQL Workbench to reproduce the report screenshots.
-- ============================================================================

-- Query 1: Complete order summary from a view.
SELECT
    order_id, order_date, customer_name, order_status,
    total_units, total_amount
FROM vw_order_summary
ORDER BY order_date;

-- Query 2: Top five products by non-cancelled sales revenue.
SELECT
    product_name,
    category_name,
    units_ordered,
    ROUND(gross_sales, 2) AS gross_sales
FROM vw_product_sales
ORDER BY gross_sales DESC
LIMIT 5;

-- Query 3: Monthly revenue, number of orders, and average order value.
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    COUNT(*) AS orders_count,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders
WHERE order_status <> 'CANCELLED'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- Query 4: Category performance using multiple joins and aggregation.
SELECT
    c.category_name,
    COUNT(DISTINCT p.product_id) AS products_count,
    COALESCE(SUM(
        CASE WHEN o.order_status <> 'CANCELLED' THEN oi.quantity ELSE 0 END
    ), 0) AS units_sold,
    ROUND(COALESCE(SUM(
        CASE WHEN o.order_status <> 'CANCELLED'
             THEN oi.quantity * oi.unit_price - oi.discount_amount
             ELSE 0 END
    ), 0), 2) AS sales_value
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id
GROUP BY c.category_id, c.category_name
ORDER BY sales_value DESC;

-- Query 5: Products whose rating is above the overall product-rating average.
SELECT
    p.product_name,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM products p
JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING AVG(r.rating) > (SELECT AVG(rating) FROM reviews)
ORDER BY average_rating DESC, review_count DESC;

-- Query 6: Customer value report with customers who have no orders retained.
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS order_count,
    ROUND(COALESCE(SUM(
        CASE WHEN o.order_status <> 'CANCELLED' THEN o.total_amount ELSE 0 END
    ), 0), 2) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC;

-- Query 7: Inventory status and reorder recommendation.
SELECT
    p.sku,
    p.product_name,
    i.quantity_in_stock,
    i.quantity_reserved,
    i.quantity_in_stock - i.quantity_reserved AS available_quantity,
    p.reorder_level,
    CASE
        WHEN i.quantity_in_stock - i.quantity_reserved <= p.reorder_level
        THEN 'REORDER'
        ELSE 'SUFFICIENT'
    END AS inventory_status
FROM products p
JOIN inventory i ON i.product_id = p.product_id
ORDER BY available_quantity, p.product_name;

-- Query 8: Detailed items for a selected order.
SELECT
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.sku,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    ROUND(oi.quantity * oi.unit_price - oi.discount_amount, 2) AS line_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_id = 10
ORDER BY p.product_name;

-- Stored procedure execution examples:
CALL sp_customer_order_history(1);
-- CALL sp_create_order(8, 9, 9, 'New order created through a procedure');
-- CALL sp_add_order_item(LAST_INSERT_ID(), 12, 1);

-- Metadata checks useful during demonstration:
SHOW TABLES;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW PROCEDURE STATUS WHERE Db = 'online_shopping_db';
SHOW TRIGGERS FROM online_shopping_db;