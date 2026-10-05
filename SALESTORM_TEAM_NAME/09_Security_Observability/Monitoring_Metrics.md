Monitoring Metrics

1. Overview

Monitoring metrics are used to measure system performance, reliability, inventory consistency, payment behavior, and infrastructure health.

2. Traffic Metrics

Important traffic metrics:

- Requests per second
- Concurrent users
- Requests by API
- Requests by service
- Traffic growth rate

The system should be monitored against normal traffic of approximately 10,000 requests/second and flash-sale traffic up to 500,000 requests/second.

3. API Metrics

Monitor:

- API request count
- API response time
- API error rate
- HTTP status codes
- Timeout count

Important APIs include:

- Product APIs
- Cart APIs
- Reservation APIs
- Checkout APIs
- Payment APIs
- Order APIs

4. Inventory Metrics

Monitor:

- Available quantity
- Reserved quantity
- Sold quantity
- Reservation success count
- Reservation failure count
- Reservation expiry count
- Inventory update conflicts

The most important inventory metric is the prevention of overselling.

5. Payment Metrics

Monitor:

- Payment requests
- Successful payments
- Failed payments
- Payment timeouts
- Payment retries
- Duplicate payment requests
- Payment gateway latency

Payment success and failure rates should be monitored continuously during a flash sale.

6. Order Metrics

Monitor:

- Orders created
- Orders confirmed
- Orders failed
- Orders cancelled
- Orders by state
- Order processing latency

7. Database Metrics

Monitor:

- Database CPU
- Database connections
- Query latency
- Query error rate
- Database availability
- Connection pool usage

8. Queue Metrics

Monitor:

- Queue depth
- Message processing rate
- Message failure count
- Retry count
- Dead Letter Queue messages
- Consumer processing latency

9. Infrastructure Metrics

Monitor:

- CPU utilization
- Memory utilization
- Network usage
- Instance health
- Load balancer traffic
- Service instance count

10. Reliability Metrics

Important reliability metrics:

- Error rate
- Timeout rate
- Retry count
- Circuit breaker state
- Service availability
- Dependency failure rate

11. Alert Conditions

Alerts can be configured for:

- High API error rate
- High API latency
- Payment gateway failure
- Database unavailability
- High queue depth
- High reservation failure rate
- Inventory inconsistency
- Service instance failure

12. Dashboard

A flash-sale monitoring dashboard should provide visibility into:

Traffic
↓
API Health
↓
Inventory
↓
Payment
↓
Orders
↓
Database
↓
Queues

This allows the team to quickly identify bottlenecks and failures.

13. Summary

Monitoring focuses on:

- Traffic
- API performance
- Inventory
- Payment
- Orders
- Database
- Queues
- Infrastructure
- Reliability