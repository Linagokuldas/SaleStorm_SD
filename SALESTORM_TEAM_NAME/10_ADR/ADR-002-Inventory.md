ADR-002: Inventory Concurrency Control

Status: Accepted

1. Context

The flash-sale scenario has:

- 100 available units
- 10,000 concurrent purchase requests

Multiple customers may attempt to reserve the same inventory at the same time.

The system must prevent overselling.

2. Decision

Use optimistic concurrency control using the Inventory version field.

The Inventory entity contains:

- availableQuantity
- reservedQuantity
- soldQuantity
- version

The version is checked when updating inventory.

If the version has changed since the inventory was read, the update is rejected and the request can be retried or failed safely.

3. Example

Initial inventory:

Available Quantity = 1
Version = 5

Request A reads:

Version = 5

Request B also reads:

Version = 5

Request A successfully updates:

Available Quantity = 0
Version = 6

Request B tries to update using Version = 5.

The update fails because the current version is 6.

Therefore, both requests cannot reserve the same final item.

4. Alternatives Considered

Option 1: Optimistic Concurrency Control

Advantages:

- Good for high-concurrency workloads
- Avoids long database locks
- Uses version checking
- Suitable when conflicts are relatively short-lived

Disadvantages:

- Conflicting requests may need retry
- High contention can cause repeated update failures

Option 2: Pessimistic Locking

Advantages:

- Locks the inventory row during the transaction
- Prevents concurrent updates directly

Disadvantages:

- Can increase lock contention
- Can reduce throughput under heavy traffic

5. Rationale

Optimistic concurrency control is selected because the flash-sale workload can generate a very high number of concurrent requests.

The version field provides a simple mechanism to detect conflicting updates.

6. Consequences

Positive:

- Prevents lost updates
- Helps prevent overselling
- Supports concurrent requests
- Reduces long-running locks

Negative:

- Conflicting requests may need retry or rejection
- Very high contention can increase failed update attempts

7. Related Requirements

The design must handle:

- Simultaneous purchase requests
- Last-item contention
- Duplicate reservations
- Reservation expiry
- Inventory consistency