# SALESTORM – Database Design

## 1. Purpose

The SALESTORM database is designed for a high-scale e-commerce flash-sale system where a large number of customers may attempt to purchase a very limited quantity of products at the same time.

The database design focuses on:

- Preventing inventory overselling
- Supporting temporary inventory reservations
- Preventing duplicate reservation and payment processing
- Maintaining order and payment consistency
- Supporting failure recovery
- Providing clear relationships between customers, products, inventory, reservations, orders, payments, and shipments
- Supporting horizontal application scaling

---

# 2. Database Technology

**Database:** PostgreSQL

PostgreSQL is selected for the core transactional database because SALESTORM requires strong consistency for critical operations such as:

- Inventory reservation
- Reservation release
- Order creation
- Payment state persistence
- Inventory confirmation

The database is used as the system of record for transactional business data.

---

# 3. High-Level Database Structure

The main database domains are:

```text
Customer Management
        ↓
Product & Category
        ↓
Cart
        ↓
Inventory
        ↓
Inventory Reservation
        ↓
Order
        ↓
Payment
        ↓
Shipment
        ↓
Notification
```

Additional promotional entities support flash-sale business requirements:

```text
SALE
  ↓
PRODUCT_SALE

COUPON
  ↓
ORDER_COUPON
```

---

# 4. Core Entities

The database contains the following major entities:

| Entity | Purpose |
|---|---|
| CUSTOMER | Stores customer account information |
| CATEGORY | Organizes products |
| PRODUCT | Stores products available for purchase |
| INVENTORY | Maintains stock quantities |
| CART | Stores customer shopping carts |
| CART_ITEM | Stores products inside carts |
| INVENTORY_RESERVATION | Temporarily holds inventory during checkout |
| SALE | Defines flash sales/deals |
| PRODUCT_SALE | Associates products with a sale |
| COUPON | Stores discount information |
| CUSTOMER_ORDER | Stores confirmed/customer orders |
| ORDER_ITEM | Stores products purchased in an order |
| PAYMENT | Stores payment transactions |
| ORDER_COUPON | Associates coupons with orders |
| SHIPMENT | Stores shipment and tracking information |
| NOTIFICATION | Stores customer notification records |

---

# 5. Customer and Product Design

## 5.1 CUSTOMER

The `customer` table is the root entity for customer-related operations.

A customer can:

- Own carts
- Create inventory reservations
- Place orders
- Receive notifications

Important constraints:

- `email` is unique
- `phone` is unique
- `status` controls account state

Relationship:

```text
CUSTOMER 1 ───────── M CART
CUSTOMER 1 ───────── M INVENTORY_RESERVATION
CUSTOMER 1 ───────── M CUSTOMER_ORDER
CUSTOMER 1 ───────── M NOTIFICATION
```

---

## 5.2 CATEGORY

Categories organize products.

Categories support hierarchical structures using:

```text
parent_category_id
```

Example:

```text
Electronics
    ├── Mobiles
    ├── Laptops
    └── Accessories
```

Relationship:

```text
CATEGORY 1 ───────── M PRODUCT
CATEGORY 1 ───────── M CATEGORY
```

---

## 5.3 PRODUCT

The `product` table contains the catalog information.

Each product has:

- SKU
- Name
- Description
- Price
- Currency
- Category
- Active status

The product is referenced by cart items, order items, inventory, and flash-sale mappings.

---

# 6. Inventory Design

Inventory is the most critical database component for the SALESTORM system.

The inventory record contains:

```text
available_quantity
reserved_quantity
sold_quantity
version
```

These values represent the current stock state.

Conceptually:

```text
Total Tracked Stock
        =
available_quantity
+
reserved_quantity
+
sold_quantity
```

Example:

```text
Initial stock = 100

available_quantity = 100
reserved_quantity = 0
sold_quantity = 0
```

After 10 successful reservations:

```text
available_quantity = 90
reserved_quantity = 10
sold_quantity = 0
```

After 8 reservations are successfully converted to sales:

```text
available_quantity = 90
reserved_quantity = 2
sold_quantity = 8
```

---

# 7. Inventory Concurrency Control

The flash-sale scenario can have thousands of concurrent requests trying to purchase the same limited stock.

For example:

```text
Available stock = 100
Concurrent purchase requests = 10,000
```

The database must ensure:

```text
Successful reservations <= 100
```

and never:

```text
Successful reservations > 100
```

## Optimistic Concurrency Control

SALESTORM uses the `version` column in the inventory table for Optimistic Concurrency Control (OCC).

The application reads the current inventory version.

Example:

```text
version = 25
available_quantity = 10
```

The reservation update includes the expected version:

```sql
UPDATE inventory
SET available_quantity = available_quantity - :quantity,
    reserved_quantity = reserved_quantity + :quantity,
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE inventory_id = :inventory_id
  AND available_quantity >= :quantity
  AND version = :current_version;
```

If one row is updated:

```text
Reservation SUCCESS
```

If zero rows are updated:

```text
Another request changed the inventory
OR
Stock is unavailable
```

The application can retry or reject the reservation.

---

# 8. Why Optimistic Concurrency Control?

Flash-sale traffic can generate a very high number of simultaneous requests.

OCC avoids holding long database locks while requests wait.

The application checks whether the inventory row changed before committing the reservation.

Main advantages:

- Prevents lost updates
- Prevents overselling
- Supports concurrent requests
- Reduces unnecessary long-running locks
- Works well with horizontally scaled application services

---

# 9. Inventory Reservation Design

`inventory_reservation` represents temporary ownership of stock.

A reservation contains:

```text
reservation_id
inventory_id
customer_id
cart_id
quantity
status
idempotency_key
expires_at
```

The reservation prevents the stock from being immediately available to another customer while the current customer completes payment.

---

# 10. Reservation Lifecycle

The reservation lifecycle is:

```text
AVAILABLE
    ↓
RESERVED
    ↓
PAYMENT_PENDING
    ↓
CONFIRMED
    ↓
SOLD
```

Failure paths:

```text
RESERVED
    ↓
PAYMENT_FAILED
    ↓
RELEASED
```

and:

```text
RESERVED
    ↓
TIMEOUT
    ↓
RELEASED
```

When a reservation is released, the reserved quantity becomes available again.

Conceptually:

```text
available_quantity += released_quantity
reserved_quantity  -= released_quantity
```

---

# 11. Reservation Expiry

The `expires_at` field defines how long a reservation can remain active.

Example:

```text
Reservation created
        ↓
expires_at = current time + reservation window
        ↓
Customer completes payment?
       / \
     YES  NO
      ↓    ↓
 CONFIRM  EXPIRE
          ↓
       RELEASE
```

An index is created on reservation expiry to efficiently find reservations that need to be processed.

---

# 12. Idempotency Design

SALESTORM uses idempotency keys for critical operations.

Two important places are:

```text
INVENTORY_RESERVATION.idempotency_key
PAYMENT.idempotency_key
```

## Why?

A client may retry a request because of:

- Network timeout
- Client retry
- Gateway timeout
- Temporary service failure

Without idempotency:

```text
Request 1 → Reservation created
Request 2 → Another reservation created
```

With idempotency:

```text
Request 1 → Reservation created
Request 2 → Existing result returned
```

This prevents duplicate business operations.

---

# 13. Cart Design

The cart is separated into:

```text
CART
CART_ITEM
```

A cart belongs to a customer.

A cart contains multiple cart items.

Relationship:

```text
CUSTOMER
   ↓
 CART
   ↓
CART_ITEM
   ↓
PRODUCT
```

The cart does not permanently own inventory.

Inventory is reserved during the checkout/reservation process.

---

# 14. Order Design

The database uses:

```text
customer_order
order_item
```

instead of a table named `order`.

This avoids conflict with the SQL `ORDER` keyword.

An order stores:

- Customer
- Reservation
- Amount information
- Currency
- Order status
- Creation/update timestamps

An order can contain multiple order items.

Relationship:

```text
CUSTOMER
    ↓
CUSTOMER_ORDER
    ↓
ORDER_ITEM
    ↓
PRODUCT
```

---

# 15. Order Lifecycle

The order lifecycle is:

```text
CREATED
   ↓
PAYMENT_PENDING
   ↓
CONFIRMED
   ↓
PROCESSING
   ↓
SHIPPED
   ↓
OUT_FOR_DELIVERY
   ↓
DELIVERED
```

A cancellation state is also supported:

```text
CANCELLED
```

The order status allows the system to track the current stage of fulfillment.

---

# 16. Payment Design

Payment data is stored separately from order data.

This allows the payment lifecycle to be tracked independently.

Payment contains:

```text
payment_id
order_id
payment_method
status
amount
currency
transaction_reference
idempotency_key
```

Payment states include:

```text
INITIATED
    ↓
PROCESSING
    ↓
SUCCESS
```

Failure states include:

```text
FAILED
TIMEOUT
```

A completed payment may later reach:

```text
REFUNDED
```

---

# 17. Payment and Order Consistency

Payment processing and order creation may involve different services.

Therefore, the system should not assume that:

```text
Payment SUCCESS
=
Order immediately created
```

A possible failure is:

```text
Payment Service
      ↓
Payment SUCCESS
      ↓
Order Service unavailable
```

The successful payment state is persisted and the event can be published for asynchronous processing.

After Order Service recovery:

```text
Payment Success Event
        ↓
Message Queue
        ↓
Order Service
        ↓
Create/confirm order
```

Retries and idempotency prevent duplicate order creation.

---

# 18. Sale and Product Sale Design

Flash-sale information is separated into:

```text
SALE
PRODUCT_SALE
```

This allows one sale to contain multiple products.

Example:

```text
SALE
"Diwali Flash Sale"
       ↓
PRODUCT_SALE
       ├── Product A
       ├── Product B
       └── Product C
```

`product_sale` stores:

- Sale price
- Maximum quantity per customer

---

# 19. Coupon Design

Coupons are stored independently.

The `coupon` table defines:

- Coupon code
- Discount type
- Discount value
- Minimum order value
- Usage limit
- Validity period
- Active status

`order_coupon` maps a coupon to an order and records the discount applied.

Relationship:

```text
COUPON
   ↓
ORDER_COUPON
   ↓
CUSTOMER_ORDER
```

---

# 20. Shipment Design

Shipment information is separated from the order.

A shipment contains:

- Carrier
- Tracking number
- Shipping address
- Shipment status
- Shipped timestamp
- Delivered timestamp

Relationship:

```text
CUSTOMER_ORDER 1 ───────── 1 SHIPMENT
```

The unique constraint on `order_id` ensures that an order has at most one shipment record in this design.

---

# 21. Notification Design

Notifications are stored separately so that customer communication can be tracked.

Supported channels:

```text
EMAIL
SMS
PUSH
```

Notification states:

```text
PENDING
SENT
FAILED
```

Notifications can be associated with an order.

Example:

```text
Order Confirmed
      ↓
Notification Event
      ↓
Notification Service
      ↓
Email / SMS / Push
```

---

# 22. Referential Integrity

Foreign keys are used to maintain valid relationships.

Examples:

```text
product.category_id
        ↓
category.category_id
```

```text
inventory.product_id
        ↓
product.product_id
```

```text
inventory_reservation.inventory_id
        ↓
inventory.inventory_id
```

```text
payment.order_id
        ↓
customer_order.order_id
```

This prevents invalid references between related records.

---

# 23. Constraints

The database uses constraints for data integrity.

Important constraints include:

### PRIMARY KEY

Uniquely identifies every record.

### FOREIGN KEY

Maintains relationships between tables.

### UNIQUE

Prevents duplicate values.

Examples:

```text
customer.email
product.sku
reservation.idempotency_key
payment.idempotency_key
payment.transaction_reference
```

### CHECK

Validates business values.

Examples:

```text
quantity > 0
price >= 0
available_quantity >= 0
```

---

# 24. Indexing Strategy

Indexes are created on frequently queried fields.

Important indexes include:

```text
product.category_id
cart.customer_id
inventory_reservation.inventory_id
inventory_reservation.customer_id
inventory_reservation.expires_at
inventory_reservation.status
customer_order.customer_id
customer_order.status
payment.order_id
payment.status
notification.customer_id
notification.status
```

The reservation expiry index is particularly important for quickly finding active reservations that have expired.

---

# 25. Database Transaction Boundaries

Critical inventory operations should execute atomically.

For a reservation:

```text
BEGIN
   ↓
Check stock
   ↓
Validate version
   ↓
Decrease available quantity
   ↓
Increase reserved quantity
   ↓
Create reservation
   ↓
COMMIT
```

If an error occurs:

```text
ROLLBACK
```

This ensures that the inventory update and reservation creation do not leave inconsistent data.

---

# 26. Data Consistency Strategy

SALESTORM follows strong consistency for the critical transactional path:

```text
Inventory
Reservation
Payment State
Order State
```

Asynchronous/event-driven processing can be used for operations that do not need to block the critical purchase path:

```text
Notifications
Shipment updates
Analytics
Non-critical downstream processing
```

This keeps the purchase path reliable while allowing the overall system to scale.

---

# 27. Database Relationship Overview

```text
CUSTOMER
   │
   ├────────── CART
   │             │
   │             └──── CART_ITEM ──── PRODUCT
   │
   ├────────── INVENTORY_RESERVATION
   │                    │
   │                    └──── INVENTORY ──── PRODUCT
   │
   ├────────── CUSTOMER_ORDER
   │                    │
   │                    ├──── ORDER_ITEM ──── PRODUCT
   │                    │
   │                    ├──── PAYMENT
   │                    │
   │                    ├──── ORDER_COUPON ──── COUPON
   │                    │
   │                    └──── SHIPMENT
   │
   └────────── NOTIFICATION

CATEGORY ──── PRODUCT

SALE ──── PRODUCT_SALE ──── PRODUCT
```

---

# 28. Critical Flash-Sale Flow

For the main SALESTORM scenario:

```text
10,000 Concurrent Requests
          ↓
      Checkout
          ↓
    Inventory Check
          ↓
   Optimistic Concurrency
          ↓
   Reserve Available Stock
          ↓
      Reservation
          ↓
       Payment
          ↓
   Payment Successful
          ↓
   Confirm Reservation
          ↓
     Create/Confirm Order
          ↓
   Convert Reserved → Sold
```

For 100 available units:

```text
10,000 requests
      ↓
Only valid reservations
      ↓
Maximum 100 units reserved
      ↓
Successful payments
      ↓
Confirmed orders
```

The database must never allow:

```text
sold_quantity > actual available stock
```

or:

```text
successful reservations > available stock
```

---

# 29. Failure Handling

## Payment Failure

```text
Reservation
     ↓
Payment Failed
     ↓
Reservation RELEASED
     ↓
Inventory returned to AVAILABLE
```

## Reservation Timeout

```text
Reservation
     ↓
expires_at reached
     ↓
TIMEOUT
     ↓
RELEASED
     ↓
Inventory returned
```

## Order Service Failure

```text
Payment SUCCESS
      ↓
Order Service unavailable
      ↓
Payment state remains persisted
      ↓
Event / retry
      ↓
Order Service recovers
      ↓
Order created/confirmed
```

This prevents a successful payment from being permanently disconnected from its order.

---

# 30. Design Decisions Summary

| Decision | Design |
|---|---|
| Database | PostgreSQL |
| Inventory consistency | Optimistic Concurrency Control |
| Concurrency field | `inventory.version` |
| Temporary stock | `inventory_reservation` |
| Reservation expiry | `expires_at` |
| Duplicate reservation prevention | Reservation idempotency key |
| Duplicate payment prevention | Payment idempotency key |
| Order table name | `customer_order` |
| Transactional data | Relational database |
| Critical path | Inventory → Reservation → Payment → Order |
| Async processing | Events/message queue for downstream work |
| Data integrity | PK, FK, UNIQUE, CHECK constraints |
| Query performance | Targeted indexes |

---

# 31. Final Design Principle

The most important database principle in SALESTORM is:

> **Inventory must be updated atomically and concurrency-safely before stock can be considered reserved.**

The combination of:

```text
available_quantity
reserved_quantity
sold_quantity
version
reservation expiry
idempotency keys
transactions
```

provides the database foundation required to handle a high-concurrency flash sale without overselling or creating duplicate reservations/payments.
