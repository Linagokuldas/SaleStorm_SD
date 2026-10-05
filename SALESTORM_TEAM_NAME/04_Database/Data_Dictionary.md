# SALESTORM – Data Dictionary

## 1. Overview

This document defines the tables, columns, data types, constraints, and business meaning of the SALESTORM database.

**Database:** PostgreSQL  
**Purpose:** High-concurrency flash-sale e-commerce system  
**Key database concerns:** inventory consistency, temporary reservations, payment idempotency, order lifecycle, and scalability.

---

# 2. CUSTOMER

Stores customer account information.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| customer_id | UUID | PK, Default UUID | Unique identifier for the customer |
| first_name | VARCHAR(100) | NOT NULL | Customer first name |
| last_name | VARCHAR(100) | NULL | Customer last name |
| email | VARCHAR(255) | NOT NULL, UNIQUE | Customer email address |
| phone | VARCHAR(20) | UNIQUE | Customer phone number |
| password_hash | TEXT | NOT NULL | Hashed customer password |
| status | VARCHAR(20) | NOT NULL | Account status: ACTIVE, INACTIVE, BLOCKED |
| created_at | TIMESTAMP | NOT NULL | Account creation timestamp |
| updated_at | TIMESTAMP | NOT NULL | Last account update timestamp |

---

# 3. CATEGORY

Stores product categories and optional parent-child category relationships.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| category_id | UUID | PK | Unique category identifier |
| name | VARCHAR(150) | NOT NULL, UNIQUE | Category name |
| description | TEXT | NULL | Category description |
| parent_category_id | UUID | FK, NULL | Parent category for hierarchical categories |
| is_active | BOOLEAN | NOT NULL | Indicates whether category is active |
| created_at | TIMESTAMP | NOT NULL | Category creation timestamp |
| updated_at | TIMESTAMP | NOT NULL | Last update timestamp |

**Relationship:** A category can contain many products and can have child categories.

---

# 4. PRODUCT

Stores products available for sale.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| product_id | UUID | PK | Unique product identifier |
| category_id | UUID | FK, NULL | Category associated with the product |
| sku | VARCHAR(100) | NOT NULL, UNIQUE | Stock Keeping Unit |
| name | VARCHAR(255) | NOT NULL | Product name |
| description | TEXT | NULL | Product description |
| price | NUMERIC(12,2) | NOT NULL | Regular product price |
| currency | CHAR(3) | NOT NULL | Currency code, default INR |
| is_active | BOOLEAN | NOT NULL | Indicates whether product is available |
| created_at | TIMESTAMP | NOT NULL | Product creation timestamp |
| updated_at | TIMESTAMP | NOT NULL | Last update timestamp |

---

# 5. INVENTORY

Stores the current stock position for each product.

This is the **critical table for flash-sale concurrency**.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| inventory_id | UUID | PK | Unique inventory record identifier |
| product_id | UUID | FK, UNIQUE | Product associated with this inventory record |
| available_quantity | INT | NOT NULL, >= 0 | Units currently available for reservation |
| reserved_quantity | INT | NOT NULL, >= 0 | Units temporarily reserved |
| sold_quantity | INT | NOT NULL, >= 0 | Units successfully sold |
| version | BIGINT | NOT NULL | Version used for Optimistic Concurrency Control |
| updated_at | TIMESTAMP | NOT NULL | Last inventory update timestamp |

### Critical fields

**available_quantity**  
Number of units that can currently be reserved.

**reserved_quantity**  
Number of units temporarily held for customers during checkout/payment.

**sold_quantity**  
Number of units whose purchase has been successfully confirmed.

**version**  
Used for **Optimistic Concurrency Control (OCC)**. The reservation update succeeds only when the expected version matches the current version.

---

# 6. CART

Stores customer shopping carts.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| cart_id | UUID | PK | Unique cart identifier |
| customer_id | UUID | FK | Customer who owns the cart |
| status | VARCHAR(20) | NOT NULL | ACTIVE, CHECKED_OUT, or ABANDONED |
| created_at | TIMESTAMP | NOT NULL | Cart creation timestamp |
| updated_at | TIMESTAMP | NOT NULL | Last cart update timestamp |

---

# 7. CART_ITEM

Stores products added to a cart.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| cart_item_id | UUID | PK | Unique cart item identifier |
| cart_id | UUID | FK | Cart containing the item |
| product_id | UUID | FK | Product added to the cart |
| quantity | INT | NOT NULL, > 0 | Quantity requested |
| unit_price | NUMERIC(12,2) | NOT NULL | Product price at the time of adding |
| added_at | TIMESTAMP | NOT NULL | Time item was added |
| updated_at | TIMESTAMP | NOT NULL | Last item update |

**Unique rule:** One product can appear only once in a particular cart.

---

# 8. INVENTORY_RESERVATION

Stores temporary inventory reservations during checkout.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| reservation_id | UUID | PK | Unique reservation identifier |
| inventory_id | UUID | FK | Inventory being reserved |
| customer_id | UUID | FK | Customer making the reservation |
| cart_id | UUID | FK, NULL | Related shopping cart |
| quantity | INT | NOT NULL, > 0 | Number of units reserved |
| status | VARCHAR(30) | NOT NULL | Current reservation state |
| idempotency_key | VARCHAR(255) | NOT NULL, UNIQUE | Prevents duplicate reservation requests |
| expires_at | TIMESTAMP | NOT NULL | Reservation expiration time |
| created_at | TIMESTAMP | NOT NULL | Reservation creation time |
| updated_at | TIMESTAMP | NOT NULL | Last reservation update |

### Reservation statuses

- `RESERVED`
- `PAYMENT_PENDING`
- `CONFIRMED`
- `PAYMENT_FAILED`
- `TIMEOUT`
- `RELEASED`

### Important fields

**idempotency_key**  
Ensures that retrying the same request does not create another reservation.

**expires_at**  
Defines when temporary inventory must be released if payment is not completed.

---

# 9. SALE

Stores flash-sale/deal information.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| sale_id | UUID | PK | Unique sale identifier |
| name | VARCHAR(255) | NOT NULL | Sale name |
| description | TEXT | NULL | Sale description |
| starts_at | TIMESTAMP | NOT NULL | Sale start time |
| ends_at | TIMESTAMP | NOT NULL | Sale end time |
| status | VARCHAR(20) | NOT NULL | SCHEDULED, ACTIVE, ENDED, or CANCELLED |
| created_at | TIMESTAMP | NOT NULL | Sale creation time |

---

# 10. PRODUCT_SALE

Maps products to sales and stores sale-specific pricing.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| product_sale_id | UUID | PK | Unique mapping identifier |
| sale_id | UUID | FK | Related sale |
| product_id | UUID | FK | Product included in sale |
| sale_price | NUMERIC(12,2) | NOT NULL | Product price during sale |
| max_quantity_per_customer | INT | NULL | Maximum quantity one customer can purchase |

**Unique rule:** A product can occur only once within the same sale.

---

# 11. COUPON

Stores discount coupon information.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| coupon_id | UUID | PK | Unique coupon identifier |
| code | VARCHAR(100) | NOT NULL, UNIQUE | Coupon code |
| discount_type | VARCHAR(20) | NOT NULL | PERCENTAGE or FIXED |
| discount_value | NUMERIC(12,2) | NOT NULL | Discount amount/value |
| minimum_order_value | NUMERIC(12,2) | NOT NULL | Minimum order value required |
| usage_limit | INT | NULL | Maximum allowed coupon usage |
| used_count | INT | NOT NULL | Number of times coupon has been used |
| starts_at | TIMESTAMP | NOT NULL | Coupon activation time |
| expires_at | TIMESTAMP | NOT NULL | Coupon expiry time |
| is_active | BOOLEAN | NOT NULL | Indicates whether coupon is active |

---

# 12. CUSTOMER_ORDER

Stores customer orders.

`customer_order` is used instead of `order` because `ORDER` is a SQL keyword.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| order_id | UUID | PK | Unique order identifier |
| customer_id | UUID | FK | Customer who placed the order |
| reservation_id | UUID | FK, UNIQUE | Reservation associated with the order |
| subtotal | NUMERIC(12,2) | NOT NULL | Total before discounts, tax and shipping |
| discount_amount | NUMERIC(12,2) | NOT NULL | Total discount applied |
| tax_amount | NUMERIC(12,2) | NOT NULL | Tax amount |
| shipping_amount | NUMERIC(12,2) | NOT NULL | Shipping charge |
| total_amount | NUMERIC(12,2) | NOT NULL | Final order amount |
| currency | CHAR(3) | NOT NULL | Currency code |
| status | VARCHAR(30) | NOT NULL | Current order lifecycle state |
| created_at | TIMESTAMP | NOT NULL | Order creation time |
| updated_at | TIMESTAMP | NOT NULL | Last order update |

### Order statuses

- `CREATED`
- `PAYMENT_PENDING`
- `CONFIRMED`
- `PROCESSING`
- `SHIPPED`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `CANCELLED`

---

# 13. ORDER_ITEM

Stores products belonging to an order.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| order_item_id | UUID | PK | Unique order item identifier |
| order_id | UUID | FK | Parent order |
| product_id | UUID | FK | Purchased product |
| quantity | INT | NOT NULL, > 0 | Purchased quantity |
| unit_price | NUMERIC(12,2) | NOT NULL | Price per unit at purchase |
| subtotal | NUMERIC(12,2) | NOT NULL | Quantity × unit price |

---

# 14. PAYMENT

Stores payment transaction information.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| payment_id | UUID | PK | Unique payment identifier |
| order_id | UUID | FK | Order associated with payment |
| payment_method | VARCHAR(30) | NOT NULL | UPI, CARD, NET_BANKING, or WALLET |
| status | VARCHAR(20) | NOT NULL | Current payment state |
| amount | NUMERIC(12,2) | NOT NULL | Payment amount |
| currency | CHAR(3) | NOT NULL | Currency code |
| transaction_reference | VARCHAR(255) | UNIQUE | External payment transaction reference |
| idempotency_key | VARCHAR(255) | NOT NULL, UNIQUE | Prevents duplicate payment processing |
| initiated_at | TIMESTAMP | NOT NULL | Payment initiation time |
| completed_at | TIMESTAMP | NULL | Payment completion time |
| updated_at | TIMESTAMP | NOT NULL | Last payment update |

### Payment statuses

- `INITIATED`
- `PROCESSING`
- `SUCCESS`
- `FAILED`
- `TIMEOUT`
- `REFUNDED`

### Important field

**idempotency_key**  
Ensures that a retry of the same payment request does not charge the customer twice.

---

# 15. ORDER_COUPON

Associates coupons with orders.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| order_coupon_id | UUID | PK | Unique mapping identifier |
| order_id | UUID | FK | Order receiving the discount |
| coupon_id | UUID | FK | Applied coupon |
| discount_amount | NUMERIC(12,2) | NOT NULL | Discount given to the order |

**Unique rule:** The same coupon cannot be attached to the same order more than once.

---

# 16. SHIPMENT

Stores order shipment and delivery tracking information.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| shipment_id | UUID | PK | Unique shipment identifier |
| order_id | UUID | FK, UNIQUE | Order being shipped |
| carrier | VARCHAR(100) | NULL | Delivery/shipping carrier |
| tracking_number | VARCHAR(255) | UNIQUE | Shipment tracking number |
| status | VARCHAR(30) | NOT NULL | Current shipment state |
| shipping_address | TEXT | NOT NULL | Delivery address |
| shipped_at | TIMESTAMP | NULL | Shipment dispatch time |
| delivered_at | TIMESTAMP | NULL | Delivery completion time |
| updated_at | TIMESTAMP | NOT NULL | Last shipment update |

### Shipment statuses

- `CREATED`
- `SHIPPED`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `FAILED`
- `RETURNED`

---

# 17. NOTIFICATION

Stores customer notification records.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| notification_id | UUID | PK | Unique notification identifier |
| customer_id | UUID | FK | Customer receiving notification |
| order_id | UUID | FK, NULL | Related order |
| type | VARCHAR(50) | NOT NULL | Notification type |
| channel | VARCHAR(20) | NOT NULL | EMAIL, SMS, or PUSH |
| status | VARCHAR(20) | NOT NULL | PENDING, SENT, or FAILED |
| message | TEXT | NOT NULL | Notification content |
| sent_at | TIMESTAMP | NULL | Time notification was sent |
| created_at | TIMESTAMP | NOT NULL | Notification creation time |

---

# 18. Primary Key and Foreign Key Summary

## Primary Keys

Each table has a UUID primary key:

- customer → `customer_id`
- category → `category_id`
- product → `product_id`
- inventory → `inventory_id`
- cart → `cart_id`
- cart_item → `cart_item_id`
- inventory_reservation → `reservation_id`
- sale → `sale_id`
- product_sale → `product_sale_id`
- coupon → `coupon_id`
- customer_order → `order_id`
- order_item → `order_item_id`
- payment → `payment_id`
- order_coupon → `order_coupon_id`
- shipment → `shipment_id`
- notification → `notification_id`

## Important Foreign Keys

```text
CATEGORY → PRODUCT
CUSTOMER → CART
CART → CART_ITEM
PRODUCT → CART_ITEM
PRODUCT → INVENTORY
INVENTORY → INVENTORY_RESERVATION
CUSTOMER → INVENTORY_RESERVATION
CART → INVENTORY_RESERVATION
CUSTOMER → CUSTOMER_ORDER
INVENTORY_RESERVATION → CUSTOMER_ORDER
CUSTOMER_ORDER → ORDER_ITEM
PRODUCT → ORDER_ITEM
CUSTOMER_ORDER → PAYMENT
CUSTOMER_ORDER → ORDER_COUPON
COUPON → ORDER_COUPON
CUSTOMER_ORDER → SHIPMENT
CUSTOMER → NOTIFICATION
CUSTOMER_ORDER → NOTIFICATION
SALE → PRODUCT_SALE
PRODUCT → PRODUCT_SALE
```

---

# 19. SALESTORM Critical Database Fields

These fields are especially important for the high-concurrency flash-sale requirement.

| Field | Table | Purpose |
|---|---|---|
| `available_quantity` | inventory | Prevents selling unavailable stock |
| `reserved_quantity` | inventory | Tracks temporarily held stock |
| `sold_quantity` | inventory | Tracks confirmed sales |
| `version` | inventory | Enables Optimistic Concurrency Control |
| `expires_at` | inventory_reservation | Releases expired reservations |
| `idempotency_key` | inventory_reservation | Prevents duplicate reservations |
| `idempotency_key` | payment | Prevents duplicate payments |
| `transaction_reference` | payment | Identifies external payment transaction |
| `status` | inventory_reservation | Tracks reservation lifecycle |
| `status` | payment | Tracks payment lifecycle |
| `status` | customer_order | Tracks order lifecycle |

---

# 20. Key Business Flow

The database supports the following purchase flow:

```text
CUSTOMER
   ↓
PRODUCT
   ↓
CART
   ↓
INVENTORY CHECK
   ↓
INVENTORY RESERVATION
   ↓
PAYMENT
   ↓
CUSTOMER_ORDER
   ↓
SHIPMENT
   ↓
NOTIFICATION
```

During a flash sale, the critical flow is:

```text
Available Stock
      ↓
Reservation Request
      ↓
Check available_quantity
      ↓
Optimistic Concurrency Control
      ↓
Reserve Stock
      ↓
Payment
      ↓
Confirm Order
      ↓
Convert Reserved Stock → Sold Stock
```

If payment fails or the reservation expires:

```text
RESERVED
   ↓
PAYMENT_FAILED / TIMEOUT
   ↓
RELEASED
   ↓
Return quantity to available stock
```

---

# 21. Concurrency Control

SALESTORM uses **Optimistic Concurrency Control (OCC)** for the critical inventory update.

The `version` column is incremented whenever inventory is successfully updated.

Conceptually:

```sql
UPDATE inventory
SET available_quantity = available_quantity - :quantity,
    reserved_quantity = reserved_quantity + :quantity,
    version = version + 1
WHERE inventory_id = :inventory_id
  AND available_quantity >= :quantity
  AND version = :current_version;
```

If the update affects one row:

```text
Reservation successful
```

If the update affects zero rows:

```text
Stock unavailable OR another transaction changed the inventory.
Retry or reject the request.
```

This prevents multiple concurrent requests from successfully reserving the same limited stock.

---

# 22. Design Summary

The database is designed around four critical principles:

1. **Inventory Consistency**  
   Inventory quantities and the `version` field support concurrency-safe reservation.

2. **Temporary Reservation**  
   Reservations have an `expires_at` timestamp so unavailable stock is not held indefinitely.

3. **Idempotency**  
   Unique idempotency keys prevent duplicate reservation and payment processing.

4. **Order and Payment Lifecycle**  
   Separate status fields allow the system to track payment and order progress and recover from failures.

