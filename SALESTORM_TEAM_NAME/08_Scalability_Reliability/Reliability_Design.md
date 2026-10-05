Reliability Design

1. Overview

The system must continue operating safely even when individual services, databases, payment gateways, or network components fail.

The reliability design focuses on:

- Timeouts
- Retries
- Circuit breakers
- Idempotency
- Reservation expiry
- Compensation
- Reconciliation
- Dead Letter Queues
- Monitoring and alerting

2. Timeout

Every external service call should have a defined timeout.

Examples:

- Payment gateway timeout
- Database timeout
- Service-to-service timeout

A timeout prevents a request from waiting indefinitely.

3. Retry

Transient failures can be retried using controlled retry policies.

Retries should use:

- Limited retry attempts
- Exponential backoff
- Jitter

Retries should not be used blindly for every operation.

4. Circuit Breaker

A circuit breaker protects the system when an external dependency repeatedly fails.

States:

CLOSED
→ OPEN
→ HALF_OPEN
→ CLOSED

When failures exceed a threshold, the circuit opens and temporarily stops requests.

5. Idempotency

Idempotency prevents duplicate processing when the same request is received multiple times.

Important operations:

- Payment
- Reservation
- Order creation

An idempotency key is used to identify duplicate requests.

6. Reservation Expiry

Inventory reservations are temporary.

If payment is not completed before the reservation expires:

RESERVED
→ TIMEOUT
→ RELEASED
→ AVAILABLE

This ensures that unused inventory is returned to the available stock.

7. Compensation

If one operation succeeds but a dependent operation fails, a compensating action can restore consistency.

Example:

Payment succeeds
       ↓
Order Service fails
       ↓
Retry / Event / Reconciliation
       ↓
Order confirmed

If required, compensation can be used to reverse or correct the completed operation.

8. Reconciliation

A reconciliation process compares related system records and identifies inconsistencies.

Example:

Payment Gateway:
SUCCESS

Order Service:
NOT CONFIRMED

The reconciliation process identifies this mismatch and triggers recovery.

9. Dead Letter Queue

Messages that cannot be processed successfully after retries can be moved to a Dead Letter Queue.

Flow:

Message
  ↓
Consumer
  ↓
Failure
  ↓
Retry
  ↓
Failure
  ↓
Dead Letter Queue

This prevents repeatedly failing messages from blocking normal processing.

10. Graceful Degradation

Non-critical features should be allowed to degrade without affecting critical purchase operations.

For example:

Notification failure should not make a successful payment fail.

The order and inventory lifecycle should remain the priority.

11. Reliability Monitoring

Important metrics include:

- Request error rate
- Payment failure rate
- Inventory reservation failures
- Queue depth
- Service latency
- Database latency
- Circuit breaker state
- Reservation expiry count

12. Summary

The reliability design uses:

- Timeouts
- Retries
- Circuit breakers
- Idempotency
- Reservation expiry
- Compensation
- Reconciliation
- Dead Letter Queues
- Monitoring

These mechanisms help the system recover safely from failures.