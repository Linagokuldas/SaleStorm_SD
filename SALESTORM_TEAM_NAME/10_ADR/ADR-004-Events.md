ADR-004: Use Asynchronous Events for Non-Critical Operations

Status: Accepted

1. Context

The system contains operations that do not need to complete before returning the main transaction response.

Examples:

- Notifications
- Shipment updates
- Order events
- Audit/event processing

During flash-sale traffic, performing all operations synchronously can increase latency and overload services.

2. Decision

Use asynchronous events and a message queue for non-critical downstream operations.

Example:

Order Service
     ↓
Order Confirmed Event
     ↓
Message Queue
     ↓
Notification Service
Shipment Service
Audit Processing

3. Synchronous Operations

Critical operations remain synchronous when immediate consistency or response is required.

Examples:

- Inventory reservation
- Payment processing
- Critical order state updates

4. Asynchronous Operations

The following can be processed asynchronously:

- Notifications
- Shipment events
- Audit processing
- Non-critical downstream updates

5. Alternatives Considered

Option 1: Fully Synchronous Communication

Advantages:

- Simple request flow
- Immediate response from downstream services

Disadvantages:

- Higher latency
- Strong coupling
- Failure in one service can affect the entire request
- Poor scalability during traffic spikes

Option 2: Asynchronous Events

Advantages:

- Better scalability
- Loose coupling
- Failure isolation
- Queue can absorb traffic spikes

Disadvantages:

- Eventual consistency
- More complex failure handling
- Requires retry and Dead Letter Queue handling

6. Rationale

Asynchronous events are selected for non-critical operations to reduce synchronous workload and improve scalability during flash-sale traffic.

Critical inventory and payment consistency operations remain protected by transactional and idempotent mechanisms.

7. Reliability

Events should support:

- Retry
- Idempotent consumers
- Dead Letter Queue
- Monitoring
- Reconciliation where required

8. Consequences

Positive:

- Better scalability
- Lower synchronous latency
- Failure isolation
- Loose coupling

Negative:

- Eventual consistency for asynchronous operations
- Additional infrastructure complexity
- Requires event monitoring and recovery mechanisms