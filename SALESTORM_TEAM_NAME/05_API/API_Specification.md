API Specification

1. Overview

The SALESTORM system exposes REST APIs for product discovery, inventory reservation, checkout, payment, and order management.

The APIs are designed to support:

- High concurrent traffic
- Inventory consistency
- Idempotent operations
- Reliable payment processing
- Order lifecycle management

2. API Design Principles

The APIs follow these principles:

- REST-style resource endpoints
- JSON request and response format
- HTTPS communication
- Authentication for protected APIs
- Input validation
- Idempotency for retryable operations
- Appropriate HTTP status codes
- Request and response correlation using request IDs

3. Product APIs

GET /api/products

Purpose:
Retrieve available products.

Response:

{
  "products": [
    {
      "productId": "P1001",
      "name": "Product A",
      "price": 999.00
    }
  ]
}

GET /api/products/{productId}

Purpose:
Retrieve details of a specific product.

4. Inventory APIs

GET /api/inventory/{productId}

Purpose:
Check inventory information for a product.

POST /api/inventory/reservations

Purpose:
Reserve inventory for a customer.

Request:

{
  "productId": "P1001",
  "customerId": "C1001",
  "quantity": 1,
  "idempotencyKey": "RES-12345"
}

Response:

{
  "reservationId": "R1001",
  "productId": "P1001",
  "quantity": 1,
  "status": "RESERVED",
  "expiresAt": "timestamp"
}

DELETE /api/inventory/reservations/{reservationId}

Purpose:
Release an active inventory reservation.

5. Checkout APIs

POST /api/checkout

Purpose:
Initiate the checkout process.

Request:

{
  "customerId": "C1001",
  "reservationId": "R1001"
}

Response:

{
  "checkoutId": "CH1001",
  "status": "PAYMENT_PENDING"
}

6. Payment APIs

POST /api/payments

Purpose:
Initiate payment for an order.

Request:

{
  "orderId": "O1001",
  "amount": 999.00,
  "idempotencyKey": "PAY-12345"
}

Response:

{
  "paymentId": "P1001",
  "status": "PENDING"
}

GET /api/payments/{paymentId}

Purpose:
Retrieve payment status.

7. Order APIs

POST /api/orders

Purpose:
Create an order.

Request:

{
  "customerId": "C1001",
  "reservationId": "R1001"
}

Response:

{
  "orderId": "O1001",
  "status": "PAYMENT_PENDING"
}

GET /api/orders/{orderId}

Purpose:
Retrieve order details and current status.

GET /api/customers/{customerId}/orders

Purpose:
Retrieve orders belonging to a customer.

POST /api/orders/{orderId}/cancel

Purpose:
Cancel an order when cancellation is allowed.

8. Common HTTP Status Codes

200 OK
Successful request.

201 Created
Resource successfully created.

400 Bad Request
Invalid request data.

401 Unauthorized
Authentication required or invalid.

403 Forbidden
User does not have permission.

404 Not Found
Requested resource does not exist.

409 Conflict
Conflict such as inventory or idempotency conflict.

429 Too Many Requests
Rate limit exceeded.

500 Internal Server Error
Unexpected server error.

502 Bad Gateway
External service or gateway failure.

503 Service Unavailable
Service temporarily unavailable.

504 Gateway Timeout
Upstream service timeout.

9. Error Response

A standard error response is used:

{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Requested quantity is not available",
    "requestId": "REQ-12345"
  }
}

10. Idempotency

The following APIs should support idempotency:

- POST /api/inventory/reservations
- POST /api/payments
- POST /api/orders

The client sends an idempotency key.

If the same key is received again, the system returns the existing result instead of performing the operation again.

11. Security

Protected APIs require:

- Authentication
- Authorization
- HTTPS
- Input validation
- Rate limiting

12. Request Correlation

A request ID should be used for tracing requests across services.

Example:

X-Request-Id: REQ-12345

The request ID can be included in logs, traces, and error responses.

13. Summary

The API design provides endpoints for:

- Product discovery
- Inventory checking
- Inventory reservation
- Checkout
- Payment
- Order management

The design focuses on consistency, idempotency, security, and reliable processing during flash-sale traffic.