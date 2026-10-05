# SALESTORM – AI Usage Note

## 1. Purpose

AI-assisted tools were used as supporting tools during the SALESTORM system
design and validation process.

AI was used to help with:

- Drafting and reviewing documentation
- Generating initial validation-test structures
- Checking edge cases
- Explaining concurrency and idempotency scenarios
- Organizing architecture and database documentation
- Supporting simulation development

---

## 2. AI Was Not Used as a Replacement for Architecture

The core architecture and engineering decisions remain team decisions.

The team defined and reviewed:

- Service boundaries
- Inventory consistency strategy
- Optimistic Concurrency Control
- Reservation lifecycle
- Payment and order lifecycle
- Idempotency requirements
- Synchronous vs asynchronous interactions
- Database entities and relationships
- Failure scenarios
- Scalability considerations
- Security and observability requirements

AI-generated suggestions were reviewed and adapted to the SALESTORM
requirements.

---

## 3. AI-Assisted Validation

The following validation prototypes were created with AI assistance:

```text
concurrency_simulation.py
idempotency_test.py
reservation_expiry_test.py
```

They validate:

### Concurrency

```text
10,000 concurrent purchase requests
100 available units
```

Expected invariant:

```text
Successful reservations <= 100
```

### Idempotency

Repeated requests with the same idempotency key should result in only one
business operation.

### Reservation expiry

Expired reservations should release temporarily reserved inventory.

---

## 4. Human Review

The team reviewed the generated code and validation logic to ensure that it
matched the intended SALESTORM design.

The simulations are treated as supporting evidence rather than proof of
production performance.

---

## 5. Transparency

AI assistance was used for productivity and validation, but AI did not
replace the team's responsibility for:

- Requirements analysis
- Architecture decisions
- Concurrency reasoning
- Database design
- Trade-off analysis
- Security decisions
- Reliability strategy
- Final presentation and explanation

The team must be able to explain and defend every major design decision.

---

## 6. Summary

AI was used as an engineering assistant for documentation, code scaffolding,
validation ideas, and review.

The final SALESTORM architecture, critical concurrency approach, database
design, reliability strategy, and trade-offs were reviewed and owned by the
team.
