"""
SALESTORM - Idempotency Validation

Purpose:
Validate that repeated requests with the same idempotency key do not
create duplicate business operations.

Scenario:
The same reservation request is submitted multiple times because of
a simulated client/network retry.

Expected behavior:
- First request creates the reservation.
- Repeated requests return the original result.
- Only one reservation is created.
"""

from threading import Lock
from concurrent.futures import ThreadPoolExecutor
import uuid


class IdempotencyStore:
    """In-memory stand-in for a database idempotency record."""

    def __init__(self):
        self._records = {}
        self._lock = Lock()

    def execute_once(self, key: str, operation):
        """
        Execute an operation only once for a given idempotency key.

        In the production design, this guarantee should be backed by a
        database UNIQUE constraint on idempotency_key and a transaction.
        """
        with self._lock:
            if key in self._records:
                return self._records[key]

            result = operation()
            self._records[key] = result
            return result


class ReservationService:
    def __init__(self):
        self.reservation_count = 0
        self._lock = Lock()

    def create_reservation(self):
        with self._lock:
            self.reservation_count += 1
            return {
                "reservation_id": str(uuid.uuid4()),
                "status": "RESERVED",
            }


def run_test():
    store = IdempotencyStore()
    service = ReservationService()

    idempotency_key = "reserve-customer-100-product-500-request-001"

    def request():
        return store.execute_once(
            idempotency_key,
            service.create_reservation,
        )

    retry_count = 100

    with ThreadPoolExecutor(max_workers=20) as executor:
        results = list(executor.map(lambda _: request(), range(retry_count)))

    reservation_ids = {result["reservation_id"] for result in results}

    print("=" * 60)
    print("SALESTORM - IDEMPOTENCY TEST")
    print("=" * 60)
    print(f"Total repeated requests : {retry_count}")
    print(f"Actual reservations     : {service.reservation_count}")
    print(f"Unique reservation IDs  : {len(reservation_ids)}")
    print(f"Returned status         : {results[0]['status']}")
    print("-" * 60)

    assert service.reservation_count == 1, "Duplicate reservation detected!"
    assert len(reservation_ids) == 1, "Multiple reservation IDs detected!"

    print("RESULT: PASS - Duplicate request did not create duplicate reservation.")


if __name__ == "__main__":
    run_test()
