Failure Scenarios

1. Overview

The SALESTORM system must handle multiple failure scenarios while maintaining inventory and order consistency.

The following scenarios are considered.

2. Payment Failure

Scenario:

Customer reserves stock but payment fails.

Flow:

Reservation
  ↓
Payment Failed
  ↓
Release Reservation
  ↓
Stock Available Again

Expected behavior:

- Payment status becomes FAILED.
- Reserved stock is released.
- Available quantity is restored.
- Customer receives payment failure response.

3. Payment Timeout

Scenario:

Payment gateway does not respond within the configured timeout.

Flow:

Payment Request
  ↓
Timeout
  ↓
Payment Pending
  ↓
Retry / Reconciliation

Expected behavior:

- Do not immediately assume payment failure.
- Check payment status when required.
- Retry safely using idempotency.
- Reconcile the final payment status.

4. Duplicate Payment Request

Scenario:

Customer sends the same payment request multiple times.

Expected behavior:

- Check idempotency key.
- Detect existing payment.
- Return the existing payment result.
- Do not create another payment.

5. Payment Success but Order Service Failure

Scenario:

Payment succeeds but Order Service becomes unavailable.

Flow:

Payment Success
  ↓
Order Service Failure
  ↓
Event / Retry
  ↓
Reconciliation
  ↓
Order Confirmation

Expected behavior:

- Payment record remains successful.
- The order is not silently lost.
- Retry or reconciliation completes the order workflow.

6. Reservation Timeout

Scenario:

Customer reserves stock but does not complete payment before expiry.

Flow:

RESERVED
  ↓
TIMEOUT
  ↓
RELEASED
  ↓
AVAILABLE

Expected behavior:

- Reservation becomes expired.
- Reserved quantity is released.
- Available stock is restored.

7. Inventory Becomes Zero

Scenario:

Multiple customers attempt to purchase the final available item.

Expected behavior:

- Concurrency control ensures only valid requests reserve stock.
- Once stock reaches zero, subsequent requests are rejected.
- Overselling must not occur.

8. Duplicate Reservation Request

Scenario:

Customer sends the same reservation request multiple times.

Expected behavior:

- Idempotency key is checked.
- Existing reservation is returned when appropriate.
- Duplicate reservation is not created.

9. Database Failure

Scenario:

Database becomes temporarily unavailable.

Expected behavior:

- Database timeout is applied.
- Transient operations may be retried.
- Errors are logged.
- Customer receives a safe failure response.
- Critical inventory state must not be partially updated.

10. Payment Gateway Failure

Scenario:

External payment gateway becomes unavailable.

Expected behavior:

- Timeout and retry policies are applied.
- Circuit breaker can prevent repeated calls.
- Payment should not be incorrectly marked as successful.
- Reconciliation can be used when payment status is uncertain.

11. Traffic Spike

Scenario:

Traffic increases significantly during the flash sale.

Expected behavior:

- Load balancer distributes requests.
- Application services scale horizontally.
- Cache handles read-heavy traffic.
- Queue absorbs asynchronous workloads.
- Rate limiting protects services.

12. Summary

The failure handling strategy focuses on:

- Preventing overselling
- Preventing duplicate payments
- Releasing expired reservations
- Recovering from service failures
- Handling payment uncertainty
- Protecting the database
- Maintaining order consistency