API Examples

1. Get Products

Request:

GET /api/products

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


2. Get Product

Request:

GET /api/products/P1001

Response:

{
  "productId": "P1001",
  "name": "Product A",
  "price": 999.00
}


3. Check Inventory

Request:

GET /api/inventory/P1001

Response:

{
  "productId": "P1001",
  "availableQuantity": 100,
  "reservedQuantity": 0,
  "soldQuantity": 0
}


4. Reserve Inventory

Request:

POST /api/inventory/reservations

Headers:

Idempotency-Key: RES-12345

Body:

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
  "expiresAt": "2026-10-05T12:10:00Z"
}


5. Release Reservation

Request:

DELETE /api/inventory/reservations/R1001

Response:

{
  "reservationId": "R1001",
  "status": "RELEASED"
}


6. Start Checkout

Request:

POST /api/checkout

Body:

{
  "customerId": "C1001",
  "reservationId": "R1001"
}

Response:

{
  "checkoutId": "CH1001",
  "status": "PAYMENT_PENDING"
}


7. Create Payment

Request:

POST /api/payments

Headers:

Idempotency-Key: PAY-12345

Body:

{
  "orderId": "O1001",
  "amount": 999.00
}

Response:

{
  "paymentId": "P1001",
  "orderId": "O1001",
  "amount": 999.00,
  "status": "PENDING"
}


8. Get Payment Status

Request:

GET /api/payments/P1001

Response:

{
  "paymentId": "P1001",
  "status": "SUCCESS",
  "transactionId": "TXN-98765"
}


9. Create Order

Request:

POST /api/orders

Headers:

Idempotency-Key: ORD-12345

Body:

{
  "customerId": "C1001",
  "reservationId": "R1001"
}

Response:

{
  "orderId": "O1001",
  "customerId": "C1001",
  "status": "PAYMENT_PENDING"
}


10. Get Order

Request:

GET /api/orders/O1001

Response:

{
  "orderId": "O1001",
  "customerId": "C1001",
  "status": "CONFIRMED",
  "totalAmount": 999.00
}


11. Get Customer Orders

Request:

GET /api/customers/C1001/orders

Response:

{
  "orders": [
    {
      "orderId": "O1001",
      "status": "CONFIRMED",
      "totalAmount": 999.00
    }
  ]
}


12. Cancel Order

Request:

POST /api/orders/O1001/cancel

Response:

{
  "orderId": "O1001",
  "status": "CANCELLED"
}


13. Insufficient Stock

Request:

POST /api/inventory/reservations

Headers:

Idempotency-Key: RES-67890

Body:

{
  "productId": "P1001",
  "customerId": "C2001",
  "quantity": 1,
  "idempotencyKey": "RES-67890"
}

Response:

{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Requested quantity is not available",
    "requestId": "REQ-12345"
  }
}


14. Duplicate Payment Request

Request:

POST /api/payments

Headers:

Idempotency-Key: PAY-12345

If the same idempotency key was already processed, the existing payment result is returned instead of creating a duplicate payment.

Example response:

{
  "paymentId": "P1001",
  "status": "SUCCESS",
  "transactionId": "TXN-98765"
}


15. Payment Timeout

Example response:

{
  "paymentId": "P1001",
  "status": "PENDING",
  "message": "Payment status is being reconciled"
}


16. Common Error Response

{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid request data",
    "requestId": "REQ-12345"
  }
}