ADR-005: Use Caching for Read-Heavy Data

Status: Accepted

1. Context

Flash-sale traffic can generate a very large number of read requests.

Examples:

- Product details
- Product information
- Sale information
- Category information

Sending every read request directly to the database can create unnecessary database load.

2. Decision

Use a caching layer for frequently accessed and relatively stable data.

Suitable cached data includes:

- Product details
- Category information
- Sale/deal information
- Other read-heavy data

Critical inventory reservation decisions should use the authoritative inventory data source rather than relying on stale cache values.

3. Cache Flow

Client
  ↓
API Gateway
  ↓
Cache
  ↓
Database

If data exists in cache:

Client
  ↓
Cache
  ↓
Response

If data is not in cache:

Client
  ↓
Cache
  ↓
Database
  ↓
Cache
  ↓
Response

4. Alternatives Considered

Option 1: No Cache

Advantages:

- Simple architecture
- Always reads from the database

Disadvantages:

- High database load
- Higher latency
- Poor performance during traffic spikes

Option 2: Caching

Advantages:

- Reduces database reads
- Improves response time
- Supports high read traffic
- Helps absorb flash-sale traffic

Disadvantages:

- Cache invalidation complexity
- Possible stale data
- Additional infrastructure

5. Rationale

Caching is selected for read-heavy and relatively stable data.

Inventory reservation is not dependent on cached stock values because inventory correctness is more important than read performance.

6. Cache Invalidation

Cache entries should be invalidated or refreshed when the underlying data changes.

Examples:

- Product update
- Sale update
- Category update

7. Consequences

Positive:

- Reduced database load
- Faster read responses
- Better scalability
- Improved performance during traffic spikes

Negative:

- Additional infrastructure
- Cache invalidation complexity
- Possible stale data for non-critical read operations

8. Related Decisions

- ADR-001: SQL Database
- ADR-002: Inventory Concurrency Control
- Capacity Analysis
- Scalability Design