Low-Level Design (LLD) Explanation

1. Overview

The Low-Level Design defines the internal structure and responsibilities of the critical modules in the SALESTORM e-commerce system.

The three main modules covered are:

- Inventory
- Payment
- Order

The design includes class diagrams, sequence diagrams, state diagrams, interfaces, repositories, and service responsibilities.


2. Inventory Module

2.1 Purpose

The Inventory module manages product stock and reservations during the flash sale.

The system must prevent overselling when many customers try to purchase limited stock simultaneously.

The Inventory entity maintains:

- inventoryId
- productId
- availableQuantity
- reservedQuantity
- soldQuantity
- version
- updatedAt

The version field is used as part of concurrency control to detect conflicting inventory updates.

The Reservation entity maintains:

- reservationId
- productId
- customerId
- quantity
- status
- expiresAt
- idempotencyKey

These fields support temporary reservations, expiry, release, and duplicate request handling.

2.2 Main Classes

Inventory

Represents the current stock information of a product.

Responsibilities:

- Check stock availability
- Maintain available quantity
- Maintain reserved quantity
- Maintain sold quantity

InventoryService

Contains the main inventory business logic.

Responsibilities:

- Check availability
- Reserve stock
- Release reserved stock
- Confirm reserved stock

Reservation

Represents a temporary stock reservation for a customer.

Responsibilities:

- Create reservation
- Confirm reservation
- Release reservation
- Expire reservation

ReservationService

Manages the reservation lifecycle.

InventoryRepository

Provides an abstraction for database operations related to inventory and reservations.

InventoryController

Receives inventory-related requests and delegates them to the InventoryService.


3. Payment Module

3.1 Purpose

The Payment module manages payment processing and payment status.

The system must handle:

- Successful payment
- Failed payment
- Payment timeout
- Duplicate payment requests
- Payment retries
- Payment status updates

3.2 Main Classes

Payment

Represents a payment associated with an order.

Important attributes include:

- paymentId
- orderId
- amount
- status
- transactionId
- idempotencyKey

PaymentService

Contains payment business logic.

Responsibilities:

- Initiate payment
- Process payment
- Handle successful payment
- Handle failed payment
- Handle timeout
- Manage retries/reconciliation

PaymentController

Receives payment API requests and delegates them to PaymentService.

PaymentGateway

An interface used to communicate with an external payment provider.

PaymentGatewayAdapter

Provides an adapter between the application and the external payment gateway.

PaymentRepository

Provides database access for payment records.


4. Order Module

4.1 Purpose

The Order module manages the complete order lifecycle.

The required order lifecycle is:

CREATED
→ PAYMENT_PENDING
→ CONFIRMED
→ PROCESSING
→ SHIPPED
→ OUT_FOR_DELIVERY
→ DELIVERED

4.2 Main Classes

Order

Represents a customer's order.

Important attributes include:

- orderId
- customerId
- status
- totalAmount
- createdAt
- updatedAt

Responsibilities:

- Create order
- Confirm order
- Cancel order
- Update order status

OrderItem

Represents an individual product inside an order.

Important attributes include:

- orderItemId
- orderId
- productId
- quantity
- unitPrice
- subtotal

Product

Represents the product associated with an order item.

OrderService

Contains order business logic.

Responsibilities:

- Create order
- Confirm order
- Cancel order
- Update order status
- Retrieve order

OrderController

Receives order-related API requests and delegates them to OrderService.

OrderRepository

Provides database access for orders.

OrderStateManager

Manages and validates order state transitions.


5. Reservation Flow

The reservation process follows these steps:

1. Customer sends a stock reservation request.
2. InventoryController receives the request.
3. InventoryController calls InventoryService.
4. InventoryService checks inventory availability.
5. InventoryRepository retrieves the inventory data.
6. If stock is available, a reservation is created.
7. Inventory quantity is updated.
8. Reservation success is returned to the customer.
9. If stock is unavailable, the reservation request is rejected.

Reservation lifecycle:

AVAILABLE
→ RESERVED
→ PAYMENT_PENDING
→ CONFIRMED
→ SOLD

Failure scenarios:

RESERVED
→ PAYMENT_FAILED
→ RELEASED
→ AVAILABLE

RESERVED
→ TIMEOUT
→ RELEASED
→ AVAILABLE


6. Payment Flow

The payment process follows these steps:

1. Customer initiates payment.
2. PaymentController receives the request.
3. PaymentService checks the idempotency key.
4. If the request is a duplicate, the existing payment status is returned.
5. For a new request, a payment record is created.
6. PaymentService communicates with the PaymentGateway.
7. On success, payment status is updated to SUCCESS.
8. Order confirmation is triggered.
9. On failure, payment status is updated to FAILED.
10. On timeout, retry or reconciliation is performed.

This prevents duplicate payment processing and provides safe handling of gateway failures.


7. Order Flow

The order process starts when the customer creates an order.

The order initially enters the CREATED state.

It then moves to:

CREATED
→ PAYMENT_PENDING
→ CONFIRMED
→ PROCESSING
→ SHIPPED
→ OUT_FOR_DELIVERY
→ DELIVERED

Payment success allows the order to proceed towards confirmation.

Payment failure or timeout is handled separately without incorrectly confirming the order.


8. Concurrency and Inventory Consistency

The flash sale scenario may have thousands of simultaneous purchase requests for limited stock.

The Inventory entity contains a version field to support concurrency control.

Example:

Initial:

- Available quantity = 1
- Version = 5

A successful inventory update changes the version:

- Available quantity = 0
- Version = 6

If another request tries to update the inventory using the old version, the update can be rejected because the inventory has already changed.

This helps prevent multiple customers from successfully reserving the same last item.


9. Idempotency

Idempotency is important for both reservation and payment operations.

An idempotencyKey is used to identify repeated requests.

If the same request is received again, the system can detect that it has already been processed instead of creating another reservation or payment.

This prevents:

- Duplicate reservations
- Duplicate payments
- Duplicate processing


10. Repository Pattern

Repository interfaces are used to separate business logic from database access.

Examples:

- InventoryRepository
- PaymentRepository
- OrderRepository

Services interact with repository interfaces instead of directly depending on database implementation details.

This improves maintainability and supports easier testing.


11. Adapter Pattern

The PaymentGatewayAdapter is used to integrate the application with an external payment provider.

The application communicates with the PaymentGateway interface while the adapter handles provider-specific implementation details.

This reduces direct dependency on a particular payment provider.


12. State Management

State transitions are important for both reservation and order processing.

Reservation states:

AVAILABLE
→ RESERVED
→ PAYMENT_PENDING
→ CONFIRMED
→ SOLD

Order states:

CREATED
→ PAYMENT_PENDING
→ CONFIRMED
→ PROCESSING
→ SHIPPED
→ OUT_FOR_DELIVERY
→ DELIVERED

Invalid state transitions should be prevented by the corresponding service/state management logic.


13. Reliability Considerations

The LLD supports the following reliability mechanisms required by the system:

- Idempotency for duplicate requests
- Timeout handling
- Retry and reconciliation for payment timeout
- Reservation expiry
- Stock release after failed payment
- State-based order processing
- Repository abstraction for persistence

These mechanisms help maintain a consistent order and inventory lifecycle during failures.


14. Summary

The LLD divides responsibilities among controllers, services, domain entities, repositories, and external interfaces.

The main principles are:

- Controllers handle incoming requests.
- Services contain business logic.
- Entities represent business data and state.
- Repositories abstract database access.
- Interfaces reduce coupling with external systems.
- State transitions maintain valid business workflows.
- Idempotency prevents duplicate operations.
- Inventory versioning supports concurrency control.

The design focuses on preventing overselling, handling duplicate requests, maintaining payment consistency, and ensuring a reliable order lifecycle during flash-sale traffic.