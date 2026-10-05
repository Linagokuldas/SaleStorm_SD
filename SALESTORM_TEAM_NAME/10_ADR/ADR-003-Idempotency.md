ADR-003: Idempotency for Duplicate Requests

Status: Accepted

1. Context

During a flash sale, the same request may be sent multiple times because of:

- User retries
- Network failures
- Client retries
- Timeout responses
- Duplicate API requests

The system must prevent duplicate reservations, payments, and orders.

2. Decision

Use an idempotency key for operations that must not be processed more than once.

Important operations include:

- Inventory reservation
- Payment processing
- Order creation where applicable

The request contains an idempotency key.

The service checks whether the key has already been processed.

If the key already exists, the existing result is returned instead of performing the operation again.

3. Example

First request:

idempotencyKey = ABC123

Payment is processed successfully.

A duplicate request arrives with:

idempotencyKey = ABC123

The system detects the existing request and returns the existing payment result.

A second payment is not created.

4. Alternatives Considered

Option 1: Idempotency Key

Advantages:

- Prevents duplicate processing
- Works well with retries
- Simple to identify repeated requests

Disadvantages:

- Idempotency records must be stored
- Keys need appropriate expiration/retention policies

Option 2: Client-side duplicate prevention only

Advantages:

- Simple server implementation

Disadvantages:

- Cannot protect against network retries
- Cannot protect against malicious or external duplicate requests
- Not reliable for distributed systems

5. Rationale

Idempotency is handled on the server because duplicate requests can occur even when the client behaves correctly.

6. Consequences

Positive:

- Prevents duplicate payments
- Prevents duplicate reservations
- Makes retries safer
- Improves reliability

Negative:

- Requires idempotency key storage
- Requires additional lookup during request processing

7. Related Components

- PaymentService
- InventoryService
- OrderService
- PaymentRepository
- InventoryRepository