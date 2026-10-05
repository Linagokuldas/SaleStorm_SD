Audit Logging

1. Overview

Audit logging records important business and security actions performed in the system.

Audit logs help with:

- Security investigation
- Failure investigation
- Business dispute resolution
- Transaction tracking
- Compliance and accountability

2. Events to Audit

Important events include:

Authentication:

- Login attempt
- Successful authentication
- Failed authentication

Inventory:

- Stock reservation
- Reservation release
- Reservation expiry
- Stock confirmation

Payment:

- Payment initiated
- Payment successful
- Payment failed
- Payment timeout
- Payment retry
- Payment status change

Order:

- Order created
- Order confirmed
- Order cancelled
- Order status changed

Administrative:

- Configuration changes
- Administrative actions
- Access to sensitive operations

3. Audit Log Fields

An audit record can contain:

- eventId
- eventType
- timestamp
- actorId
- action
- resourceType
- resourceId
- requestId
- result
- source
- metadata

4. Example

Reservation event:

eventType: INVENTORY_RESERVATION
actorId: customerId
action: RESERVE
resourceType: INVENTORY
resourceId: inventoryId
result: SUCCESS
timestamp: timestamp
requestId: requestId

5. Payment Audit Example

eventType: PAYMENT_STATUS_CHANGED
actorId: customerId
action: PAYMENT_SUCCESS
resourceType: PAYMENT
resourceId: paymentId
result: SUCCESS
timestamp: timestamp

6. Order Audit Example

eventType: ORDER_STATUS_CHANGED
actorId: customerId
action: ORDER_CONFIRMED
resourceType: ORDER
resourceId: orderId
result: SUCCESS
timestamp: timestamp

7. Security of Audit Logs

Audit logs should be:

- Access controlled
- Protected from unauthorized modification
- Stored securely
- Monitored for abnormal activity

Sensitive information such as passwords, secret keys, and unnecessary payment credentials should not be stored in audit logs.

8. Request Correlation

A requestId can be used to connect:

API request
    ↓
Inventory operation
    ↓
Payment operation
    ↓
Order operation

This makes it easier to trace a complete transaction across services.

9. Retention

Audit logs should be retained according to organizational and regulatory requirements.

Retention duration should be finalized based on the deployment environment and applicable requirements.

10. Summary

Audit logging provides a reliable record of important system actions.

It supports:

- Security investigation
- Transaction tracking
- Inventory auditing
- Payment auditing
- Order lifecycle tracking
- Failure investigation