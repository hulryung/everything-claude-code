---
name: python-patterns
description: Python specific patterns, Django, FastAPI, Flask best practices.
---

# Python Patterns

Language-specific patterns for Python, Django, FastAPI, and Flask.

## Type Hints

### Basic Types
```python
from typing import Optional, List, Dict, Union, Callable

def get_user(user_id: str) -> Optional[User]:
    """Fetch user by ID."""
    pass

def process_items(items: List[str]) -> Dict[str, int]:
    """Process items and return counts."""
    pass

def fetch_data(url: str, callback: Callable[[dict], None]) -> None:
    """Fetch data and call callback."""
    pass
```

### Dataclasses
```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class User:
    id: str
    name: str
    email: str
    created_at: datetime
    is_active: bool = True
```

### Pydantic Models
```python
from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=0, le=150)

class UserResponse(BaseModel):
    id: str
    name: str
    email: str

    class Config:
        from_attributes = True
```

## Immutability Pattern

```python
from dataclasses import dataclass, replace
from typing import FrozenSet

# Using frozen dataclass
@dataclass(frozen=True)
class User:
    id: str
    name: str

# Creating updated copy
updated_user = replace(user, name="New Name")

# Using tuples instead of lists for immutable sequences
items: tuple[str, ...] = ("a", "b", "c")

# Using frozenset for immutable sets
tags: FrozenSet[str] = frozenset({"python", "fastapi"})
```

## Async/Await

```python
import asyncio
from typing import List

# GOOD: Parallel execution
async def fetch_all_data() -> tuple[List[User], List[Product]]:
    users, products = await asyncio.gather(
        fetch_users(),
        fetch_products()
    )
    return users, products

# BAD: Sequential when unnecessary
async def fetch_all_data_slow():
    users = await fetch_users()      # Waits
    products = await fetch_products()  # Then waits
    return users, products
```

## Error Handling

```python
import logging

logger = logging.getLogger(__name__)

class UserNotFoundError(Exception):
    """Raised when user is not found."""
    pass

async def get_user(user_id: str) -> User:
    try:
        user = await db.users.find_one({"id": user_id})
        if not user:
            raise UserNotFoundError(f"User {user_id} not found")
        return User(**user)
    except DatabaseError as e:
        logger.error("Database error", extra={"user_id": user_id, "error": str(e)})
        raise
```

## FastAPI Patterns

### Route Structure
```python
from fastapi import APIRouter, HTTPException, Depends

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    db: Database = Depends(get_db)
) -> UserResponse:
    user = await db.users.find_one({"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse(**user)

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    user_data: UserCreate,
    db: Database = Depends(get_db)
) -> UserResponse:
    user = await db.users.insert_one(user_data.dict())
    return UserResponse(**user)
```

### Dependency Injection
```python
from fastapi import Depends

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    user = await verify_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

def require_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin required")
    return user
```

## Django Patterns

### Model Definition
```python
from django.db import models

class User(models.Model):
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.email
```

### QuerySet Optimization
```python
# GOOD: Select only needed fields
users = User.objects.filter(is_active=True).values('id', 'name', 'email')

# GOOD: Prefetch related to avoid N+1
orders = Order.objects.select_related('user').prefetch_related('items')

# BAD: Fetching everything
users = User.objects.all()
```

## File Structure

```
src/
├── api/
│   ├── __init__.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── products.py
│   └── dependencies.py
├── core/
│   ├── __init__.py
│   ├── config.py
│   └── security.py
├── models/
│   ├── __init__.py
│   └── user.py
├── services/
│   ├── __init__.py
│   └── user_service.py
└── main.py
```

## Testing with pytest

```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_get_user(client: AsyncClient):
    response = await client.get("/users/123")
    assert response.status_code == 200
    assert response.json()["id"] == "123"

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    response = await client.post("/users/", json={
        "name": "Test User",
        "email": "test@example.com"
    })
    assert response.status_code == 201
```

## Formatters & Linters

- **Black** or **Ruff**: Code formatting
- **Ruff**: Fast linting
- **mypy**: Type checking
- **isort**: Import sorting

## Debug Statements to Remove

```python
# Remove before committing
print()
pprint()
breakpoint()
import pdb; pdb.set_trace()
```
