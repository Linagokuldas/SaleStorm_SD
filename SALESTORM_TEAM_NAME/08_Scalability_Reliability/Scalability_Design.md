Scalability Design

1. Overview

The SALESTORM system must handle normal traffic of approximately 10,000 requests per second and flash-sale traffic that may increase up to 500,000 requests per second.

The architecture uses horizontal scaling, caching, load balancing, asynchronous processing, and database scaling to handle sudden traffic spikes.

2. Load Balancing

A Load Balancer distributes incoming requests across multiple application instances.

Flow:

Users
  ↓
CDN / WAF
  ↓
Load Balancer
  ↓
Multiple API/Application Instances

Benefits:

- Distributes traffic
- Prevents a single server from becoming a bottleneck
- Supports horizontal scaling
- Improves availability

3. Horizontal Scaling

Application services are designed to run as multiple instances.

For example:

Inventory Service:
- Instance 1
- Instance 2
- Instance 3
- Instance N

Additional instances can be added during traffic spikes.

4. Caching

Frequently accessed product and sale information can be cached.

Examples:

- Product details
- Product availability for display
- Sale information
- Category information

Cache reduces repeated database reads and improves response time.

Critical inventory reservation operations should still use the authoritative inventory database for consistency.

5. Asynchronous Processing

A message queue is used for operations that do not need to block the customer request.

Examples:

- Notifications
- Order events
- Shipment updates
- Audit/event processing

Flow:

Service
  ↓
Message Queue
  ↓
Consumer Services

This reduces synchronous workload during traffic spikes.

6. Database Scaling

The database can be scaled using:

- Read replicas for read-heavy operations
- Connection pooling
- Proper indexing
- Query optimization

Inventory writes require strong consistency and concurrency control.

7. CDN

A CDN can serve static and cacheable content closer to users.

Examples:

- Product images
- Static frontend assets
- Public product information

This reduces load on the application servers.

8. Rate Limiting

Rate limiting protects the system from excessive requests.

It can be applied at:

- API Gateway
- Load Balancer
- Application layer

This prevents a small number of clients from overwhelming the system.

9. Flash Sale Scaling

During a flash sale:

Users
  ↓
CDN / WAF
  ↓
Load Balancer
  ↓
API Gateway
  ↓
Auto-scaled Services
  ↓
Cache / Queue / Database

The application layer can scale horizontally based on traffic.

10. Bottleneck Management

Potential bottlenecks include:

- Database writes
- Inventory updates
- Payment gateway
- Network bandwidth
- Queue processing

Monitoring and load testing are used to identify bottlenecks.

11. Scalability Trade-offs

Caching improves performance but may introduce stale data.

Asynchronous processing improves scalability but introduces eventual consistency for non-critical operations.

Read replicas improve read scalability but may have replication lag.

Horizontal scaling improves capacity but increases infrastructure complexity.

12. Summary

The scalability design combines:

- Load balancing
- Horizontal scaling
- CDN
- Caching
- Queueing
- Database scaling
- Rate limiting
- Connection pooling

These mechanisms allow the system to handle sudden flash-sale traffic while protecting critical inventory operations.