-- SALESTORM - Database Schema
-- PostgreSQL
-- Purpose: High-concurrency flash-sale e-commerce system
-- Critical design: Inventory uses optimistic concurrency control (OCC)
-- through the version column.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. CUSTOMER
-- ============================================================
CREATE TABLE customer (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. CATEGORY
-- ============================================================
CREATE TABLE category (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id UUID,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES category(category_id)
        ON DELETE SET NULL
);

-- ============================================================
-- 3. PRODUCT
-- ============================================================
CREATE TABLE product (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID,
    sku VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES category(category_id)
        ON DELETE SET NULL
);

-- ============================================================
-- 4. INVENTORY
-- Critical table for flash-sale concurrency
-- ============================================================
CREATE TABLE inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL UNIQUE,
    available_quantity INT NOT NULL DEFAULT 0
        CHECK (available_quantity >= 0),
    reserved_quantity INT NOT NULL DEFAULT 0
        CHECK (reserved_quantity >= 0),
    sold_quantity INT NOT NULL DEFAULT 0
        CHECK (sold_quantity >= 0),
    version BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE CASCADE
);

-- ============================================================
-- 5. CART
-- ============================================================
CREATE TABLE cart (
    cart_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'CHECKED_OUT', 'ABANDONED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE
);

-- ============================================================
-- 6. CART ITEM
-- ============================================================
CREATE TABLE cart_item (
    cart_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_item_cart
        FOREIGN KEY (cart_id)
        REFERENCES cart(cart_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_cart_item_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_cart_product UNIQUE (cart_id, product_id)
);

-- ============================================================
-- 7. INVENTORY RESERVATION
-- Temporary stock reservation with expiry
-- ============================================================
CREATE TABLE inventory_reservation (
    reservation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    cart_id UUID,
    quantity INT NOT NULL CHECK (quantity > 0),

    status VARCHAR(30) NOT NULL DEFAULT 'RESERVED'
        CHECK (
            status IN (
                'RESERVED',
                'PAYMENT_PENDING',
                'CONFIRMED',
                'PAYMENT_FAILED',
                'TIMEOUT',
                'RELEASED'
            )
        ),

    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservation_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES inventory(inventory_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservation_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservation_cart
        FOREIGN KEY (cart_id)
        REFERENCES cart(cart_id)
        ON DELETE SET NULL
);

-- ============================================================
-- 8. SALE / DEAL
-- ============================================================
CREATE TABLE sale (
    sale_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED'
        CHECK (status IN ('SCHEDULED', 'ACTIVE', 'ENDED', 'CANCELLED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_sale_time
        CHECK (ends_at > starts_at)
);

-- ============================================================
-- 9. PRODUCT SALE
-- ============================================================
CREATE TABLE product_sale (
    product_sale_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL,
    product_id UUID NOT NULL,
    sale_price NUMERIC(12,2) NOT NULL CHECK (sale_price >= 0),
    max_quantity_per_customer INT
        CHECK (max_quantity_per_customer IS NULL OR max_quantity_per_customer > 0),

    CONSTRAINT fk_product_sale_sale
        FOREIGN KEY (sale_id)
        REFERENCES sale(sale_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_product_sale_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_sale_product UNIQUE (sale_id, product_id)
);

-- ============================================================
-- 10. COUPON
-- ============================================================
CREATE TABLE coupon (
    coupon_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    discount_type VARCHAR(20) NOT NULL
        CHECK (discount_type IN ('PERCENTAGE', 'FIXED')),
    discount_value NUMERIC(12,2) NOT NULL CHECK (discount_value >= 0),
    minimum_order_value NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (minimum_order_value >= 0),
    usage_limit INT CHECK (usage_limit IS NULL OR usage_limit > 0),
    used_count INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    starts_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_coupon_time
        CHECK (expires_at > starts_at)
);

-- ============================================================
-- 11. ORDER
-- "customer_order" is used instead of "order" because ORDER
-- is a SQL keyword.
-- ============================================================
CREATE TABLE customer_order (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    reservation_id UUID UNIQUE,
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (discount_amount >= 0),
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (tax_amount >= 0),
    shipping_amount NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (shipping_amount >= 0),
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    status VARCHAR(30) NOT NULL DEFAULT 'CREATED'
        CHECK (
            status IN (
                'CREATED',
                'PAYMENT_PENDING',
                'CONFIRMED',
                'PROCESSING',
                'SHIPPED',
                'OUT_FOR_DELIVERY',
                'DELIVERED',
                'CANCELLED'
            )
        ),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_order_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES inventory_reservation(reservation_id)
        ON DELETE SET NULL
);

-- ============================================================
-- 12. ORDER ITEM
-- ============================================================
CREATE TABLE order_item (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_item_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 13. PAYMENT
-- Idempotency prevents duplicate payment processing
-- ============================================================
CREATE TABLE payment (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    payment_method VARCHAR(30) NOT NULL
        CHECK (payment_method IN ('UPI', 'CARD', 'NET_BANKING', 'WALLET')),
    status VARCHAR(20) NOT NULL DEFAULT 'INITIATED'
        CHECK (
            status IN (
                'INITIATED',
                'PROCESSING',
                'SUCCESS',
                'FAILED',
                'TIMEOUT',
                'REFUNDED'
            )
        ),
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    transaction_reference VARCHAR(255) UNIQUE,
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    initiated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 14. ORDER COUPON
-- ============================================================
CREATE TABLE order_coupon (
    order_coupon_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    coupon_id UUID NOT NULL,
    discount_amount NUMERIC(12,2) NOT NULL
        CHECK (discount_amount >= 0),

    CONSTRAINT fk_order_coupon_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_coupon_coupon
        FOREIGN KEY (coupon_id)
        REFERENCES coupon(coupon_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_order_coupon UNIQUE (order_id, coupon_id)
);

-- ============================================================
-- 15. SHIPMENT
-- ============================================================
CREATE TABLE shipment (
    shipment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE,
    carrier VARCHAR(100),
    tracking_number VARCHAR(255) UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED'
        CHECK (
            status IN (
                'CREATED',
                'SHIPPED',
                'OUT_FOR_DELIVERY',
                'DELIVERED',
                'FAILED',
                'RETURNED'
            )
        ),
    shipping_address TEXT NOT NULL,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_shipment_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 16. NOTIFICATION
-- ============================================================
CREATE TABLE notification (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    order_id UUID,
    type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL
        CHECK (channel IN ('EMAIL', 'SMS', 'PUSH')),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
    message TEXT NOT NULL,
    sent_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notification_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_notification_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE SET NULL
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_product_category
    ON product(category_id);

CREATE INDEX idx_cart_customer
    ON cart(customer_id);

CREATE INDEX idx_cart_item_product
    ON cart_item(product_id);

CREATE INDEX idx_reservation_inventory
    ON inventory_reservation(inventory_id);

CREATE INDEX idx_reservation_customer
    ON inventory_reservation(customer_id);

CREATE INDEX idx_reservation_expiry
    ON inventory_reservation(expires_at)
    WHERE status IN ('RESERVED', 'PAYMENT_PENDING');

CREATE INDEX idx_reservation_status
    ON inventory_reservation(status);

CREATE INDEX idx_order_customer
    ON customer_order(customer_id);

CREATE INDEX idx_order_status
    ON customer_order(status);

CREATE INDEX idx_order_item_product
    ON order_item(product_id);

CREATE INDEX idx_payment_order
    ON payment(order_id);

CREATE INDEX idx_payment_status
    ON payment(status);

CREATE INDEX idx_product_sale_product
    ON product_sale(product_id);

CREATE INDEX idx_sale_status_time
    ON sale(status, starts_at, ends_at);

CREATE INDEX idx_notification_customer
    ON notification(customer_id);

CREATE INDEX idx_notification_status
    ON notification(status);

-- ============================================================
-- CRITICAL CONCURRENCY OPERATION
-- ============================================================
-- Example: reserve 1 unit safely using Optimistic Concurrency Control.
--
-- The application first reads the current version.
-- It then performs this conditional UPDATE.
-- If affected rows = 1 -> reservation succeeded.
-- If affected rows = 0 -> another transaction changed the row
-- or stock is unavailable; retry or reject the reservation.
--
-- Example:
--
-- UPDATE inventory
-- SET available_quantity = available_quantity - 1,
--     reserved_quantity = reserved_quantity + 1,
--     version = version + 1,
--     updated_at = CURRENT_TIMESTAMP
-- WHERE inventory_id = :inventory_id
--   AND available_quantity >= 1
--   AND version = :current_version;

-- ============================================================
-- INVENTORY BUSINESS RULE
-- ============================================================
-- available_quantity + reserved_quantity + sold_quantity
-- represents the total tracked stock.
--
-- Reservation lifecycle:
-- AVAILABLE -> RESERVED -> PAYMENT_PENDING -> CONFIRMED -> SOLD
--
-- Failure paths:
-- RESERVED -> PAYMENT_FAILED -> RELEASED
-- RESERVED -> TIMEOUT -> RELEASED
-- ============================================================
