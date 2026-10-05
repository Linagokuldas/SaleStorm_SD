"""
SALESTORM - High Concurrency Inventory Simulation

Purpose:
Simulate many concurrent purchase requests competing for limited stock.

Scenario:
- Available stock: 100 units
- Concurrent requests: 10,000
- Each request attempts to reserve 1 unit

The simulation models the important business invariant:
    successful reservations <= available stock

This is a validation prototype for the architecture, not the production
Inventory Service implementation.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
import time


INITIAL_STOCK = 100
REQUEST_COUNT = 10_000
WORKERS = 200


class SimulatedInventory:
    """Thread-safe simulation of an inventory row."""

    def __init__(self, stock: int):
        self.available_quantity = stock
        self.reserved_quantity = 0
        self.version = 0
        self._lock = Lock()

    def reserve(self, quantity: int = 1) -> bool:
        """
        Simulate an atomic inventory reservation.

        The lock represents the atomic database update in this prototype.
        A production implementation can use the inventory version field
        for optimistic concurrency control.
        """
        with self._lock:
            if self.available_quantity < quantity:
                return False

            current_version = self.version

            # Simulate a small processing delay between read and update.
            time.sleep(0.00001)

            # The critical update is performed atomically.
            if self.version != current_version:
                return False

            self.available_quantity -= quantity
            self.reserved_quantity += quantity
            self.version += 1
            return True


def purchase_request(inventory: SimulatedInventory) -> bool:
    return inventory.reserve(1)


def run_simulation():
    inventory = SimulatedInventory(INITIAL_STOCK)

    successful = 0
    failed = 0

    start = time.perf_counter()

    with ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = [
            executor.submit(purchase_request, inventory)
            for _ in range(REQUEST_COUNT)
        ]

        for future in as_completed(futures):
            if future.result():
                successful += 1
            else:
                failed += 1

    elapsed = time.perf_counter() - start

    print("=" * 60)
    print("SALESTORM - CONCURRENCY SIMULATION")
    print("=" * 60)
    print(f"Initial stock          : {INITIAL_STOCK}")
    print(f"Concurrent requests    : {REQUEST_COUNT}")
    print(f"Successful reservations: {successful}")
    print(f"Rejected requests      : {failed}")
    print(f"Final available stock  : {inventory.available_quantity}")
    print(f"Final reserved stock   : {inventory.reserved_quantity}")
    print(f"Final version          : {inventory.version}")
    print(f"Execution time         : {elapsed:.4f} seconds")
    print("-" * 60)

    assert successful <= INITIAL_STOCK, "Overselling detected!"
    assert inventory.available_quantity >= 0, "Negative stock detected!"
    assert (
        inventory.available_quantity + inventory.reserved_quantity
        == INITIAL_STOCK
    ), "Inventory accounting mismatch!"

    print("RESULT: PASS - No overselling detected.")


if __name__ == "__main__":
    run_simulation()
