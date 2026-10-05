Design Pattern Mapping

1. Overview

Design patterns are used in the LLD to solve recurring design problems and improve maintainability, flexibility, and reliability.

The following patterns are mapped to the SALESTORM system:

- Repository Pattern
- Strategy Pattern
- Factory Pattern
- State Pattern
- Observer Pattern
- Adapter Pattern
- Facade Pattern
- Circuit Breaker Pattern

2. Repository Pattern

Used in:

- InventoryRepository
- PaymentRepository
- OrderRepository

Purpose:

The Repository pattern separates database access from business logic.

Example:

InventoryService
        |
        v
InventoryRepository
        |
        v
Database

Benefits:

- Separates persistence from business logic
- Easier unit testing
- Easier database implementation changes

3. Strategy Pattern

Used for:

Payment processing strategies.

Different payment providers or payment methods can be represented as different strategies.

Example:

PaymentStrategy
       |
       ├── CardPaymentStrategy
       ├── UpiPaymentStrategy
       └── OtherPaymentStrategy

Benefits:

- Supports multiple payment strategies
- Reduces conditional logic
- Easy to add new payment methods

4. Factory Pattern

Used for:

Creating appropriate payment strategy or payment gateway implementation.

Example:

PaymentFactory
       |
       ├── CardPayment
       ├── UpiPayment
       └── OtherPayment

Benefits:

- Centralizes object creation
- Reduces direct dependency on concrete classes
- Makes future extensions easier

5. State Pattern

Used for:

Order and reservation state management.

Order states:

CREATED
→ PAYMENT_PENDING
→ CONFIRMED
→ PROCESSING
→ SHIPPED
→ OUT_FOR_DELIVERY
→ DELIVERED

Reservation states:

AVAILABLE
→ RESERVED
→ PAYMENT_PENDING
→ CONFIRMED
→ SOLD

Benefits:

- Controls valid state transitions
- Prevents invalid lifecycle changes
- Keeps state-related logic organized

6. Observer Pattern

Used for:

Notification and event-based updates.

When an important event occurs, such as:

- Payment successful
- Order confirmed
- Order shipped
- Order delivered

interested components can receive the event asynchronously.

Example:

OrderService
      |
      v
Order Event
      |
      ├── Notification Service
      ├── Shipment Service
      └── Other Subscribers

Benefits:

- Loose coupling
- Supports asynchronous processing
- Easy to add new event consumers

7. Adapter Pattern

Used for:

PaymentGateway integration.

PaymentService communicates with the PaymentGateway interface while the adapter converts application requests into the format expected by an external payment provider.

Example:

PaymentService
      |
      v
PaymentGateway
      |
      v
PaymentGatewayAdapter
      |
      v
External Payment Provider

Benefits:

- Isolates external provider-specific logic
- Reduces coupling
- Makes provider replacement easier

8. Facade Pattern

Used for:

Simplifying complex purchase operations.

A Facade can coordinate multiple services such as:

- Inventory
- Payment
- Order

Example:

PurchaseFacade
      |
      ├── InventoryService
      ├── PaymentService
      └── OrderService

Benefits:

- Provides a simple interface to complex operations
- Reduces interaction complexity for clients

9. Circuit Breaker Pattern

Used for:

External payment gateway and other unreliable external dependencies.

If repeated failures occur, the circuit breaker temporarily stops requests to the failing service.

States:

CLOSED
→ OPEN
→ HALF_OPEN
→ CLOSED

Benefits:

- Prevents cascading failures
- Reduces unnecessary requests to failing services
- Allows the external service time to recover

10. Pattern Summary

Repository Pattern
- Database access abstraction

Strategy Pattern
- Different payment processing strategies

Factory Pattern
- Object creation

State Pattern
- Order and reservation lifecycle

Observer Pattern
- Event-driven notifications

Adapter Pattern
- External payment gateway integration

Facade Pattern
- Simplifies purchase workflow

Circuit Breaker Pattern
- Protects against external service failures

11. Design Benefits

The selected patterns help the system achieve:

- Loose coupling
- Better maintainability
- Extensibility
- Testability
- Failure isolation
- Clear separation of responsibilities
- Easier integration with external systems