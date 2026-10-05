ADR-001: Use SQL Database

Status: Accepted

1. Context

The SALESTORM system handles inventory, reservations, payments, and orders.

These operations require:

- Strong consistency
- Transactions
- Relationships between entities
- Constraints
- Reliable updates
- Concurrency control

The core entities include:

- Customer
- Product
- Inventory
- Inventory Reservation
- Cart
- Order
- Order Item
- Payment
- Shipment
- Notification

2. Decision

Use a relational SQL database as the primary database for transactional data.

The database will maintain relationships using primary keys and foreign keys.

Transactions will be used for critical operations such as inventory reservation and order processing.

3. Alternatives Considered

Option 1: SQL Database

Advantages:

- Strong consistency
- ACID transactions
- Foreign key relationships
- Constraints
- Suitable for transactional workloads

Disadvantages:

- Horizontal scaling can be more complex
- High write traffic requires careful optimization

Option 2: NoSQL Database

Advantages:

- Easy horizontal scaling
- High write throughput
- Flexible schema

Disadvantages:

- Complex transactional relationships can be harder to manage
- Strong consistency across multiple entities may require additional design

4. Rationale

SQL is selected because inventory, reservation, payment, and order operations require strong consistency and transactional guarantees.

5. Consequences

Positive:

- Reliable transactional operations
- Strong data integrity
- Clear relationships between entities
- Easier enforcement of constraints

Negative:

- Database scaling requires careful planning
- High traffic requires indexing, connection pooling, caching, and scaling strategies

6. Related Decisions

- ADR-002: Inventory Concurrency Control
- ADR-003: Idempotency
- ADR-005: Caching