"""
SALESTORM - Reservation Expiry Validation

Purpose:
Validate that an unpaid/expired reservation releases its reserved stock.

Business flow:
    AVAILABLE
        ↓
    RESERVED
        ↓
    TIMEOUT
        ↓
    RELEASED
        ↓
    AVAILABLE

This prototype uses a short TTL to make the behavior easy to test.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from time import sleep


@dataclass
class Reservation:
    reservation_id: str
    quantity: int
    status: str
    expires_at: datetime


class Inventory:
    def __init__(self, stock: int):
        self.available_quantity = stock
        self.reserved_quantity = 0

    def reserve(self, quantity: int):
        if self.available_quantity < quantity:
            raise ValueError("Insufficient stock")

        self.available_quantity -= quantity
        self.reserved_quantity += quantity

    def release(self, quantity: int):
        self.reserved_quantity -= quantity
        self.available_quantity += quantity


def expire_reservation(inventory: Inventory, reservation: Reservation):
    now = datetime.now()

    if reservation.status in {"RESERVED", "PAYMENT_PENDING"}:
        if now >= reservation.expires_at:
            inventory.release(reservation.quantity)
            reservation.status = "TIMEOUT"
            return True

    return False


def run_test():
    initial_stock = 100
    inventory = Inventory(initial_stock)

    reservation = Reservation(
        reservation_id="RES-001",
        quantity=10,
        status="RESERVED",
        expires_at=datetime.now() + timedelta(seconds=0.1),
    )

    inventory.reserve(reservation.quantity)

    print("=" * 60)
    print("SALESTORM - RESERVATION EXPIRY TEST")
    print("=" * 60)
    print(f"Initial available stock : {initial_stock}")
    print(f"Reserved quantity       : {inventory.reserved_quantity}")
    print(f"Reservation status      : {reservation.status}")

    sleep(0.2)

    expired = expire_reservation(inventory, reservation)

    print(f"Reservation expired     : {expired}")
    print(f"Final available stock   : {inventory.available_quantity}")
    print(f"Final reserved stock    : {inventory.reserved_quantity}")
    print(f"Final reservation state : {reservation.status}")
    print("-" * 60)

    assert expired is True, "Reservation did not expire!"
    assert reservation.status == "TIMEOUT", "Incorrect expiry state!"
    assert inventory.available_quantity == initial_stock, (
        "Released stock was not returned to available inventory!"
    )
    assert inventory.reserved_quantity == 0, (
        "Reserved quantity was not released!"
    )

    print("RESULT: PASS - Expired reservation released stock correctly.")


if __name__ == "__main__":
    run_test()
