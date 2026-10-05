Observability Design

1. Overview

Observability helps the team understand the health, performance, and behavior of the system.

The system uses:

- Metrics
- Logs
- Distributed tracing
- Alerts

These mechanisms help identify failures, performance bottlenecks, and abnormal behavior.

2. Metrics

Metrics provide numerical measurements of system behavior.

Important metrics include:

- Request rate
- Response latency
- Error rate
- Inventory reservation rate
- Payment success rate
- Payment failure rate
- Order creation rate
- Queue depth
- Database latency

3. Logging

Services should generate structured logs for important operations.

Examples:

- API requests
- Reservation creation
- Reservation expiry
- Payment processing
- Payment failures
- Order state changes
- Service errors

Logs should contain useful identifiers such as:

- requestId
- orderId
- paymentId
- reservationId

Sensitive information should not be written to logs.

4. Distributed Tracing

Distributed tracing helps follow a request across multiple services.

Example:

Customer
  ↓
API Gateway
  ↓
Inventory Service
  ↓
Payment Service
  ↓
Order Service
  ↓
Notification Service

A trace ID can be used to connect related operations across services.

5. Alerting

Alerts should be generated when important thresholds or abnormal conditions occur.

Examples:

- High error rate
- High payment failure rate
- High API latency
- Database connection failures
- Queue backlog
- Inventory reservation failures
- Payment gateway failures

6. Flash Sale Monitoring

During a flash sale, the following should be closely monitored:

- Requests per second
- Concurrent requests
- Inventory reservation success/failure
- Database load
- Payment gateway response
- Queue depth
- API latency
- Error rate

7. Failure Investigation

When a failure occurs:

1. Check alerts.
2. Identify the affected service.
3. Check logs.
4. Follow the distributed trace.
5. Identify the failed dependency.
6. Apply recovery or mitigation.

8. Observability Goals

The observability system should help answer:

- Is the system healthy?
- Which service is failing?
- Where is latency increasing?
- Are payments succeeding?
- Are inventory reservations failing?
- Is the database overloaded?
- Are queues building up?

9. Summary

The observability design combines:

- Metrics
- Structured logs
- Distributed tracing
- Alerts

This provides visibility into system health and helps the team detect and troubleshoot failures quickly.