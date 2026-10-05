SALESTORM – HLD Explanation
1. Overview
SALESTORM is a high-scale flash-sale e-commerce platform designed to handle normal traffic of around 10,000 requests per second and sudden flash-sale traffic that can reach up to 500,000 requests per second.
The main challenge is:
- 10,000 users may try to purchase at the same time.
- Only 100 units may be available.
- The system must never oversell.
- Duplicate requests must not create duplicate reservations or orders.
- Payment failures must not leave stock permanently blocked.
- Payment success must not be lost even if the Order Service is temporarily unavailable.
- The architecture must be scalable, reliable, secure, and observable.
2. Main Architecture
The high-level flow is:
Customer
→ CDN
→ WAF
→ Load Balancer
→ API Gateway
→ Application Services
→ Inventory Reservation
→ Payment
→ Message Broker
→ Order
→ Fulfilment
→ Shipment
→ Notification
Supporting infrastructure:
- Redis Cache
- SQL Databases
- Kafka/RabbitMQ
- Kubernetes
- Monitoring
- Logging
- Distributed Tracing
- Alerting
- CI/CD
- Auto Scaling
3. Users
Users access SALESTORM through a web application or mobile application.
During a flash sale, thousands of users may send requests at nearly the same time.
Example:
10,000 users
→ 10,000 purchase requests
→ only 100 products available
Therefore, the backend must control concurrency instead of trusting the number shown in the UI.
4. CDN
CDN means Content Delivery Network.
It is mainly used for static and read-heavy content such as:
- Product images
- CSS
- JavaScript
- Static web content
The CDN reduces the number of requests reaching the backend servers.
It also improves response time for users.
Important:
CDN is not responsible for inventory consistency.
5. WAF
WAF means Web Application Firewall.
It protects the application from common web attacks and malicious traffic.
Examples:
- SQL injection
- Cross-site scripting
- Malicious HTTP requests
- Suspicious traffic patterns
The WAF provides the first security layer before traffic reaches the application.
6. Load Balancer
The Load Balancer distributes incoming traffic across multiple application instances.
Example:
10,000 requests
→ Load Balancer
→ Server 1
→ Server 2
→ Server 3
→ Server N
This allows horizontal scaling.
If one instance fails, traffic can be redirected to healthy instances.
7. API Gateway
The API Gateway is the main entry point for backend APIs.
Responsibilities:
- Request routing
- Authentication
- Authorization
- Rate limiting
- Request validation
- API versioning
- Traffic control
Example:
/products → Product Service
/cart → Cart Service
/checkout → Checkout Service
/orders → Order Service
/payments → Payment Service
8. Rate Limiter
Rate limiting protects the backend during flash-sale traffic.
Example:
A single customer should not be allowed to send thousands of requests per second.
Rate limiting can help prevent:
- Request flooding
- Bot abuse
- Accidental repeated requests
- Backend overload
For flash sales, rate limiting is especially important.
9. Identity Provider
The Identity Provider handles authentication.
Possible technologies:
- OAuth 2.0
- OpenID Connect
- JWT
The user authenticates once and receives an access token.
The API Gateway can validate the token before forwarding the request.
10. Product Service
The Product Service manages product information.
Responsibilities:
- Product details
- Product name
- Product description
- Product category
- Product price
- Product availability information
Product data can be cached in Redis because product information is mostly read-heavy.
The Product Service should not be responsible for authoritative inventory reservation.
11. Cart Service
The Cart Service manages the customer's shopping cart.
Responsibilities:
- Add product
- Remove product
- Update quantity
- View cart
- Calculate cart contents
Redis can be used for fast cart access.
The cart does not guarantee stock.
Stock must be validated again during checkout.
12. Inventory Service
The Inventory Service is the most critical service in the SALESTORM architecture.
Its main responsibility is to prevent overselling.
Important components:
- Inventory Controller
- Inventory Service
- Stock Validator
- Reservation Manager
- Concurrency Manager
- Inventory Repository
- Reservation Expiry Worker
The Inventory Database is the authoritative source of inventory.
13. Atomic Inventory Reservation
The system uses an atomic conditional database update.
Example:
UPDATE inventory
SET available_quantity = available_quantity - 1,
    reserved_quantity = reserved_quantity + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE product_id = ?
AND available_quantity >= 1;
If the affected rows are:
1 → reservation successful
0 → stock unavailable
This is the key mechanism for preventing overselling.
For example:
Stock = 100
10,000 users try to purchase.
Only 100 successful reservation operations can reduce the available stock from 100 to 0.
Therefore:
Successful reservations <= 100
Overselling = 0
14. Reservation
A reservation temporarily holds inventory for a customer.
Example:
Customer reserves a product.
Status:
AVAILABLE
→ RESERVED
→ PAYMENT_PENDING
→ CONFIRMED
→ SOLD
If payment fails:
RESERVED
→ PAYMENT_FAILED
→ RELEASED
If the customer does not complete payment before the reservation expires:
RESERVED
→ TIMEOUT
→ RELEASED
A reservation may have a TTL such as 10 minutes.
The exact TTL is a business decision.
15. Idempotency
Idempotency prevents duplicate operations.
Example:
A customer clicks the Pay button twice.
Without idempotency:
Request 1 → Reservation 1
Request 2 → Reservation 2
This can create duplicate business operations.
With idempotency:
Client sends:
Idempotency-Key: abc-123
The system stores the key and result.
If the same request arrives again:
abc-123
→ Existing result returned
No second reservation or payment is created.
Critical APIs should support idempotency keys.
Examples:
- POST /reservations
- POST /checkout
- POST /payments
16. Payment Service
The Payment Service handles payment processing.
Main responsibilities:
- Create payment
- Call payment provider
- Store transaction status
- Check payment status
- Handle timeout
- Retry safely
- Reconcile uncertain transactions
Payment states:
PENDING
SUCCESS
FAILED
UNKNOWN
REFUNDED
17. Payment Gateway
SALESTORM can integrate with an external payment provider.
Examples:
- Razorpay
- Stripe
- Other supported payment providers
The Payment Service should use an adapter so that the core business logic does not depend directly on a particular payment provider.
Example:
Payment Service
→ Payment Gateway Adapter
→ Payment Provider
18. Payment Timeout
Payment timeout is a critical failure scenario.
Suppose:
Customer pays successfully.
The payment gateway does not respond.
The system should NOT immediately assume:
PAYMENT FAILED
Instead:
PENDING
→ Status Check
→ Gateway Query
→ SUCCESS / FAILED
If the final state cannot immediately be determined, the payment can remain UNKNOWN/PENDING and be reconciled later.
This prevents accidental duplicate payments or incorrect order cancellation.
19. Message Broker
SALESTORM uses a durable message broker such as:
- Kafka
- RabbitMQ
The broker is used for asynchronous communication.
Example events:
- ReservationCreated
- ReservationReleased
- PaymentSucceeded
- PaymentFailed
- OrderCreated
- OrderConfirmed
- ShipmentCreated
- OrderDelivered
The message broker provides decoupling and durability.
20. Why Message Broker?
Consider this scenario:
Payment succeeds.
Payment Service publishes:
PaymentSucceeded
But the Order Service is down for 30 seconds.
If the system uses only a direct synchronous call, the payment success notification may be lost or the checkout flow may fail.
With a durable broker:
Payment Service
→ PaymentSucceeded Event
→ Message Broker
→ Order Service
If Order Service is unavailable, the event remains in the broker.
When Order Service recovers, it consumes the event.
Therefore, the business event is not lost.
21. At-Least-Once Delivery
Distributed messaging systems commonly use at-least-once delivery.
This means an event may occasionally be delivered more than once.
Therefore, consumers must be idempotent.
Example:
Event:
PaymentSucceeded
event_id = EVT123
Order Service receives EVT123.
It checks whether EVT123 has already been processed.
If yes:
Ignore duplicate event.
If no:
Process event and store EVT123 as processed.
This prevents duplicate orders.
22. Order Service
The Order Service manages the order lifecycle.
Responsibilities:
- Create order
- Validate order
- Confirm order
- Cancel order
- Update order status
- Publish order events
Order lifecycle:
CREATED
→ PAYMENT_PENDING
→ CONFIRMED
→ PROCESSING
→ SHIPPED
→ OUT_FOR_DELIVERY
→ DELIVERED
Failure states:
PAYMENT_FAILED
CANCELLED
The Order Service consumes payment events and creates/confirms orders.
23. Notification Service
Notification Service handles:
- Email
- SMS
- Push notifications
Examples:
- Order confirmed
- Payment successful
- Payment failed
- Order shipped
- Order delivered
Notifications should be asynchronous.
A notification failure should not cancel a successful order.
Example:
Order Confirmed
→ Message Broker
→ Notification Service
→ Email/SMS Provider
24. Fulfilment Service
The Fulfilment Service handles post-order processing.
Responsibilities:
- Prepare shipment
- Create shipment
- Track shipment
- Update delivery status
Flow:
Order Confirmed
→ Fulfilment
→ Shipping Provider
→ Shipment Created
→ Tracking
→ Delivery
25. Redis Cache
Redis is used for fast access to frequently requested data.
Possible uses:
- Product information
- Categories
- Cart data
- Session information
- Rate-limiting counters
Important:
Redis should NOT be the final authoritative source for critical inventory consistency.
The SQL Inventory Database remains the source of truth.
26. Database Layer
SQL databases are used for critical transactional data.
Possible database:
- PostgreSQL
- MySQL
Typical databases/tables:
Product DB
- Products
- Categories
Inventory DB
- Inventory
- Reservations
Order DB
- Orders
- Order Items
Payment DB
- Payments
- Transactions
Fulfilment DB
- Shipments
- Tracking
27. Database Design Principle
Critical business data should have strong consistency.
Inventory, payment, reservation, and order state are more important than serving stale data.
Therefore:
Cache → performance
SQL → correctness
Message Broker → asynchronous durability
28. Kubernetes
Kubernetes manages containerized application services.
Each service can have multiple replicas.
Example:
Inventory Service
Pod 1
Pod 2
Pod 3
Pod N
If traffic increases, Kubernetes can increase the number of pods.
If a pod fails, Kubernetes can restart it or replace it.
29. Horizontal Scaling
Stateless application services can scale horizontally.
Example:
1 Inventory API instance
→ 10 instances
→ 50 instances
However, scaling application instances alone does not solve inventory contention.
The inventory consistency boundary must still be protected by the authoritative database.
30. Auto Scaling
Auto scaling increases or decreases resources according to workload.
Scaling signals can include:
- CPU utilization
- Request rate
- Latency
- Queue backlog
- Memory usage
During a flash sale:
Traffic increases
→ More pods
→ More consumers
→ Increased processing capacity
31. Monitoring
Monitoring tracks system health.
Important metrics:
- Requests per second
- CPU utilization
- Memory
- Database connections
- API latency
- Error rate
- Payment success rate
- Reservation success rate
- Queue backlog
- Inventory inconsistencies
32. Logging
Logs help developers understand failures.
Each request should include identifiers such as:
request_id
trace_id
customer_id
reservation_id
order_id
payment_id
timestamp
status
This makes troubleshooting easier.
33. Distributed Tracing
Distributed tracing follows one request across multiple services.
Example:
Customer Checkout
→ Checkout Service
→ Inventory Service
→ Payment Service
→ Message Broker
→ Order Service
A trace ID allows developers to see where latency or failure occurred.
Tools can include:
- OpenTelemetry
- Jaeger
- AWS X-Ray
34. Security
Security controls include:
- HTTPS/TLS
- OAuth/JWT authentication
- Role-based authorization
- WAF
- Rate limiting
- Input validation
- Secrets management
- Audit logging
- Payment tokenization
Raw card information should not be stored in the application database.
35. Reliability
The system should tolerate failures.
Important mechanisms:
Retry
Use retry for temporary failures.
Retries should use:
- Exponential backoff
- Jitter
- Retry limits
Circuit Breaker
If an external service repeatedly fails, stop sending requests temporarily.
This protects the rest of the system.
Dead Letter Queue
Messages that repeatedly fail can be moved to a DLQ for investigation.
Reconciliation
Periodic jobs compare internal state with external payment/shipping provider state.
36. Important Failure Scenarios
Scenario 1: 10,000 users buy 100 products
Atomic inventory update ensures:
Successful reservations <= 100
Overselling = 0
Scenario 2: Duplicate request
Idempotency key ensures:
Same request
→ Same business result
→ No duplicate reservation
Scenario 3: Payment fails
Payment Failed
→ Reservation Released
→ Stock Available Again
Scenario 4: Payment timeout
Payment Pending/Unknown
→ Status Check
→ Reconciliation
Do not blindly create another payment.
Scenario 5: Order Service unavailable
Payment Success
→ PaymentSucceeded Event
→ Durable Broker
→ Order Service Recovery
→ Event Consumed
→ Order Created
Scenario 6: Duplicate event
Same event_id
→ Idempotent Consumer
→ Duplicate ignored
37. Scalability Strategy
SALESTORM handles high traffic using multiple techniques:
1. CDN for static content.
2. Redis for frequently accessed data.
3. Load Balancer for traffic distribution.
4. Stateless services for horizontal scaling.
5. Kubernetes for container orchestration.
6. Auto Scaling for dynamic workloads.
7. Message Broker for asynchronous processing.
8. Database connection pooling.
9. Read replicas for read-heavy workloads where appropriate.
10. Rate limiting to control abusive traffic.
38. Reliability Strategy
The architecture follows:
Strong consistency for critical state
+
Asynchronous processing for downstream workflows
+
Idempotency for duplicate requests/events
+
Retries for transient failures
+
Circuit breakers for unstable dependencies
+
DLQ for failed messages
+
Reconciliation for uncertain external states
39. Design Patterns
Strategy Pattern
Used for payment strategies.
Example:
PaymentStrategy
├── RazorpayPayment
├── StripePayment
└── OtherPayment
Factory Pattern
Creates the correct payment provider.
Adapter Pattern
Connects external providers to internal interfaces.
Example:
PaymentGatewayAdapter
→ Razorpay
→ Stripe
State Pattern
Manages order states.
Repository Pattern
Separates business logic from database access.
Observer / Event-Driven Pattern
Services react to events from the message broker.
Facade Pattern
Checkout Orchestrator provides a simple interface for a complex checkout workflow.
Circuit Breaker Pattern
Protects the system from failing external services.
40. SOLID Principles
Single Responsibility Principle
Each service has a focused responsibility.
Example:
Inventory Service → inventory
Payment Service → payment
Order Service → orders
Notification Service → notifications
Open/Closed Principle
New payment providers can be added without changing the core payment logic.
Liskov Substitution Principle
Different payment providers should follow the same payment interface.
Interface Segregation Principle
Use small focused interfaces.
Example:
PaymentProcessor
RefundProcessor
PaymentStatusChecker
Dependency Inversion Principle
Business logic depends on interfaces instead of concrete external providers.
41. Key Architectural Trade-offs
SQL vs NoSQL
SQL is preferred for critical inventory, reservation, payment, and order state because strong consistency and transactions are important.
Redis vs SQL
Redis provides speed.
SQL provides authoritative transactional state.
Synchronous vs Asynchronous
Use synchronous calls when the customer needs an immediate result.
Use asynchronous events for downstream operations.
Availability vs Consistency
For inventory, consistency is more important than accepting a potentially incorrect purchase.
If the authoritative inventory database is unavailable, fail closed rather than guessing stock.
42. Most Important Jury Questions
Q1. How do you prevent overselling?
Answer:
We use an atomic conditional update in the authoritative inventory database:
UPDATE inventory
SET available_quantity = available_quantity - 1
WHERE product_id = ?
AND available_quantity >= 1;
Only successful database updates create reservations, so successful reservations can never exceed available stock.
Q2. Why not use Redis for inventory?
Redis can be used for fast reads, but critical inventory correctness should be maintained in a transactional source of truth.
Q3. What happens if Payment succeeds but Order Service is down?
PaymentSucceeded is persisted/published to a durable message broker. The event remains available until Order Service recovers and consumes it.
Q4. How do you prevent duplicate orders?
We use idempotency keys for requests and event_id-based idempotency for event consumers.
Q5. What happens when payment times out?
The payment is treated as PENDING/UNKNOWN. The system checks the gateway status and reconciles the transaction instead of blindly creating another payment.
43. Complete Purchase Flow
Customer
   ↓
CDN
   ↓
WAF
   ↓
Load Balancer
   ↓
API Gateway
   ↓
Checkout Service
   ↓
Idempotency Check
   ↓
Inventory Service
   ↓
Atomic Inventory Reservation
   ↓
Reservation Created
   ↓
Payment Service
   ↓
Payment Gateway
   ↓
Payment Success
   ↓
PaymentSucceeded Event
   ↓
Message Broker
   ↓
Order Service
   ↓
Order Confirmed
   ↓
Fulfilment Service
   ↓
Shipping Provider
   ↓
Shipment
   ↓
Notification Service
   ↓
Customer
44. Flash Sale Example
Assume:
Stock = 100
Concurrent Users = 10,000
Payment Success = 95%
Duplicate Requests = 2%
Temporary Order Service Failure = 30 seconds
Expected guarantees:
Successful reservations <= 100
Overselling = 0
Duplicate orders = 0
Failed payments release reservations
Payment success is not lost
Order events survive temporary Order Service downtime
45. Final Architecture Principle
The most important idea in SALESTORM is:
Scale the stateless services horizontally,
but protect the inventory consistency boundary.
The architecture combines:
CDN
+
WAF
+
Load Balancer
+
API Gateway
+
Microservices
+
Atomic Inventory Reservation
+
SQL Transactions
+
Redis Cache
+
Durable Message Broker
+
Idempotency
+
Kubernetes
+
Auto Scaling
+
Observability
+
Security
This design allows SALESTORM to handle flash-sale traffic while maintaining inventory correctness, payment reliability, and a consistent order lifecycle.