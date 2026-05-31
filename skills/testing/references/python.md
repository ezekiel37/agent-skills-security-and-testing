# Testing Patterns - Python

Examples use **pytest**. Works the same for Django, FastAPI, and Flask apps.
Set up with [uv](https://docs.astral.sh/uv/): `uv add --dev pytest hypothesis freezegun`.

---

## Structure: Arrange-Act-Assert

```python
def test_calculate_total_applies_tax():
    total = calculate_total(subtotal_cents=10000, tax_rate=0.1)
    assert total == 11000   # work in integer cents
```

## Cover the three lenses

```python
import pytest

def test_create_user_with_valid_input(db):              # works
    user = create_user(username="ada", email="a@x.com", password="Str0ng!pass")
    assert user.id is not None

def test_create_user_rejects_short_username(db):        # fails gracefully
    with pytest.raises(ValueError, match="username"):
        create_user(username="ab", email="a@x.com", password="Str0ng!pass")

def test_create_user_ignores_is_admin(db):              # can't be abused
    user = create_user(username="ada", email="a@x.com", password="Str0ng!pass", is_admin=True)
    assert user.is_admin is False
```

## Edge cases and boundaries with parametrize

```python
@pytest.mark.parametrize("username", [
    "",                       # empty
    "   ",                    # whitespace only
    "ab",                     # too short
    "a" * 50,                 # too long
    "\U0001F600\U0001F1EF\U0001F1F5",  # multi-byte / emoji
    "'; DROP TABLE users;--", # injection-ish
])
def test_invalid_usernames_rejected(username):
    with pytest.raises(ValueError):
        validate_username(username)

@pytest.mark.parametrize("length,valid", [(8, False), (9, True), (10, True)])
def test_password_length_boundary(length, valid):
    pwd = ("Aa1!" + "x" * length)[:length]
    assert is_valid_password(pwd) is valid
```

## Deterministic time

```python
from freezegun import freeze_time

def test_token_expires_after_15_minutes():
    with freeze_time("2026-01-01 00:00:00"):
        token = issue_token()
    with freeze_time("2026-01-01 00:16:00"):
        assert is_expired(token) is True
```

## Mocking the network / failure paths

```python
from unittest.mock import patch
import pytest, requests

def test_handles_500_from_payment_api():
    with patch("billing.requests.post") as post:
        post.return_value.status_code = 500
        with pytest.raises(PaymentError):
            charge(order)

def test_times_out_slow_dependency():
    with patch("billing.requests.post", side_effect=requests.Timeout):
        with pytest.raises(PaymentError, match="timeout"):
            charge(order)
```

## API contract: status AND shape (FastAPI TestClient)

```python
from fastapi.testclient import TestClient

client = TestClient(app)

def test_bad_signup_returns_422_with_fields():
    res = client.post("/api/signup", json={"username": "ab"})
    assert res.status_code == 422                 # status
    assert "detail" in res.json()                 # shape

def test_401_vs_403():
    assert client.get("/api/admin").status_code == 401                      # no token
    assert client.get("/api/admin", headers=user_auth).status_code == 403   # not admin
```

## Authorization / IDOR

```python
def test_cannot_read_another_users_order(client, user_a_auth, user_b_order):
    res = client.get(f"/api/orders/{user_b_order.id}", headers=user_a_auth)
    assert res.status_code == 404      # ownership enforced
```

## Idempotency

```python
def test_charge_is_idempotent(db, order):
    charge(order, idempotency_key="idem-123")
    charge(order, idempotency_key="idem-123")
    assert count_charges(order.id) == 1
```

## Regression test (write it before fixing)

```python
# Bug #482: negative quantity credited the user. This test failed before the fix.
def test_rejects_negative_quantity_regression_482(client, auth):
    res = client.post("/api/cart", json={"product_id": "p1", "qty": -5}, headers=auth)
    assert res.status_code == 422
```

## Isolated DB state per test (fixtures)

```python
@pytest.fixture
def db():
    conn = create_test_db()          # fresh schema
    yield conn
    conn.rollback()                  # isolate: no test leaks into another
    conn.close()
```

## Property-based testing (Hypothesis) finds edge cases automatically

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_add_money_is_commutative(a, b):
    assert add_money(a, b) == add_money(b, a)

@given(st.text())
def test_validate_username_never_crashes(s):
    # should raise ValueError or return, never an unexpected error
    try:
        validate_username(s)
    except ValueError:
        pass
```
