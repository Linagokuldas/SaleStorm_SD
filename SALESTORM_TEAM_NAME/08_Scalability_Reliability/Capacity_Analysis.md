Capacity Analysis

1. Overview

The SALESTORM system must support normal traffic and sudden flash-sale traffic.

The hackathon specifies:

- Normal traffic: approximately 10,000 requests/second
- Flash-sale traffic: up to 500,000 requests/second

The practical scenario also includes:

- 10,000 concurrent users
- 100 available units
- 95% payment success
- 5% payment failure
- 2% duplicate requests
- Order Service unavailable for 30 seconds
- 50x traffic spike

2. Base Flash Sale Scenario

Available stock:

100 units

Concurrent purchase requests:

10,000

The system must guarantee:

Successful purchases <= 100

This means the inventory design must prevent overselling even when thousands of users request the same product simultaneously.

3. Payment Capacity

Assuming 100 successful purchases are possible:

Payment success rate:

95%

Payment failure rate:

5%

For 100 payment attempts:

Expected successful payments:

100 × 0.95 = 95

Expected failed payments:

100 × 0.05 = 5

The exact number of payment requests depends on the overall request distribution and retry behavior.

4. Duplicate Requests

Duplicate request rate:

2%

For 10,000 requests:

10,000 × 0.02 = 200 duplicate requests

These requests must be safely handled using idempotency.

5. Traffic Scaling

Normal traffic:

10,000 requests/second

Flash-sale peak:

500,000 requests/second

Traffic increase:

500,000 / 10,000 = 50x

Therefore, the architecture must be capable of handling approximately a 50x traffic increase at peak.

6. Horizontal Scaling

Application instances should scale horizontally.

Example:

Normal traffic:
- Smaller number of service instances

Flash sale:
- Increased number of service instances

The Load Balancer distributes requests across available instances.

7. Database Capacity

The database should be protected from unnecessary read traffic using:

- Cache
- Connection pooling
- Read replicas where appropriate
- Indexing
- Query optimization

Critical inventory writes require strong consistency and concurrency control.

8. Queue Capacity

Asynchronous operations should use queues.

Examples:

- Notifications
- Order events
- Shipment events
- Background processing

Queue consumers can scale horizontally based on queue depth.

9. Bottleneck Analysis

Potential bottlenecks:

1. Inventory database writes
2. Payment gateway capacity
3. Database connections
4. Queue consumers
5. Network bandwidth
6. API/application instances

The most critical bottleneck is inventory consistency because limited stock must be protected during concurrent requests.

10. Capacity Protection

The system uses:

- Load balancing
- Rate limiting
- Caching
- Horizontal scaling
- Queueing
- Database optimization
- Connection pooling

These mechanisms reduce pressure on critical components.

11. Capacity Assumptions

The following values are taken from the hackathon scenario:

- Normal traffic: 10,000 requests/second
- Peak traffic: 500,000 requests/second
- Available stock: 100 units
- Concurrent users: 10,000
- Payment success: 95%
- Payment failure: 5%
- Duplicate requests: 2%
- Order Service outage: 30 seconds

Infrastructure-specific values such as exact server count, CPU, memory, database size, and queue throughput should be determined through load testing.

12. Load Testing

Tools such as JMeter or Locust can be used to validate:

- Requests per second
- Response latency
- Error rate
- Concurrent users
- Database load
- Queue depth
- Service throughput

13. Summary

The capacity design is based on a 50x traffic increase from normal traffic to flash-sale traffic.

The architecture uses:

- Horizontal scaling
- Load balancing
- Caching
- Queueing
- Database scaling
- Rate limiting
- Load testing

The most important capacity requirement is that high traffic must never compromise inventory correctness or cause overselling.