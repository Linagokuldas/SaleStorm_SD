# SALESTORM – AI-Assisted Validation Results

## 1. Purpose

The `11_AI_Assisted_Validation` folder contains small validation prototypes for
the three most important correctness concerns in the SALESTORM design:

1. High-concurrency inventory reservation
2. Idempotent reservation requests
3. Reservation expiry and stock release

These simulations are intended to support the architecture and design
reasoning. They are **not production implementations** of the SALESTORM
services.

---

## 2. Validation Scenario

The main flash-sale scenario is:

```text
Available stock       = 100 units
Concurrent requests   = 10,000
```

The critical invariant is:

```text
Successful reservations <= 100
```

The system must never oversell the available inventory.

---

## 3. Concurrency Simulation

### File

```text
concurrency_simulation.py
```

### What it validates

The simulation creates 10,000 purchase requests competing for 100 units.

The inventory model tracks:

```text
available_quantity
reserved_quantity
version
```

The test asserts:

```text
successful reservations <= initial stock
available stock >= 0
available + reserved = initial stock
```

### Expected result

```text
Initial stock          : 100
Concurrent requests    : 10000
Successful reservations: 100
Rejected requests      : 9900
Final available stock  : 0
Final reserved stock   : 100

RESULT: PASS - No overselling detected.
```

The exact execution time can vary depending on the machine.

### Architectural relevance

The prototype represents the atomic inventory operation used by the design.
The production database design uses the `version` field for Optimistic
Concurrency Control (OCC).

---

## 4. Idempotency Test

### File

```text
idempotency_test.py
```

### What it validates

The same reservation request is submitted repeatedly using the same:

```text
idempotency_key
```

The test simulates 100 repeated requests.

Expected behavior:

```text
100 repeated requests
        ↓
1 actual reservation
        ↓
99 duplicate/retry requests return the same result
```

### Expected result

```text
Total repeated requests : 100
Actual reservations     : 1
Unique reservation IDs  : 1
Returned status         : RESERVED

RESULT: PASS - Duplicate request did not create duplicate reservation.
```

### Architectural relevance

The production database contains:

```text
inventory_reservation.idempotency_key UNIQUE
payment.idempotency_key UNIQUE
```

The application and database together provide protection against duplicate
business operations caused by retries.

---

## 5. Reservation Expiry Test

### File

```text
reservation_expiry_test.py
```

### What it validates

A reservation temporarily holds stock.

If payment does not complete before `expires_at`, the reservation should
expire and the stock should become available again.

The test follows:

```text
AVAILABLE
    ↓
RESERVED
    ↓
TIMEOUT
    ↓
RELEASED
    ↓
AVAILABLE
```

### Expected result

```text
Initial available stock : 100
Reserved quantity       : 10
Reservation status      : RESERVED

Reservation expired     : True
Final available stock   : 100
Final reserved stock    : 0
Final reservation state : TIMEOUT

RESULT: PASS - Expired reservation released stock correctly.
```

---

## 6. Validation Summary

| Validation | Scenario | Expected Invariant | Result |
|---|---|---|---|
| Concurrency | 10,000 requests / 100 units | No overselling | PASS |
| Idempotency | 100 duplicate requests | Only one reservation | PASS |
| Reservation expiry | 10 reserved units expire | Stock is released | PASS |

---

## 7. What These Tests Prove

These prototypes provide evidence for three design decisions:

### Inventory consistency

The system must make the stock reservation operation atomic and
concurrency-safe.

### Idempotency

Retrying the same request must not create another reservation or payment.

### Reservation expiry

Stock temporarily held by an incomplete checkout must eventually return to
available inventory.

---

## 8. Limitations

These are lightweight validation simulations.

They do **not** fully simulate:

- A real PostgreSQL database
- Multiple application servers
- Redis
- Message queues
- Payment gateway behavior
- Network partitions
- Database failover
- Distributed transactions
- Production-level 500,000 requests/second traffic

Therefore, the results should be presented as **architecture validation
evidence**, not as production performance benchmarks.

---

## 9. Recommended Jury Explanation

If asked why AI-assisted validation was used:

> "We used small simulations to validate the critical invariants of our
> architecture—no inventory overselling, idempotent retries, and reservation
> expiry. The simulations support our design decisions, while the actual
> concurrency strategy, database model, failure handling, and trade-offs were
> designed by the team."

