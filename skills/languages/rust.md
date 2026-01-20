---
name: rust-patterns
description: Rust specific patterns, idioms, and best practices.
---

# Rust Patterns

Language-specific patterns and idioms for Rust.

## Error Handling

### Result Type
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UserError {
    #[error("User not found: {0}")]
    NotFound(String),
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Validation error: {0}")]
    Validation(String),
}

pub async fn get_user(id: &str) -> Result<User, UserError> {
    let user = db::find_user(id)
        .await?
        .ok_or_else(|| UserError::NotFound(id.to_string()))?;
    Ok(user)
}
```

### Using ? Operator
```rust
pub async fn process_user(id: &str) -> Result<ProcessedUser, UserError> {
    let user = get_user(id).await?;
    let validated = validate_user(&user)?;
    let processed = transform_user(validated)?;
    Ok(processed)
}
```

### Handling Options
```rust
// Using combinators
let user_name = get_user(id)
    .await
    .ok()
    .map(|u| u.name.clone())
    .unwrap_or_default();

// Using if let
if let Some(user) = users.get(id) {
    println!("Found user: {}", user.name);
}

// Using match
match get_user(id).await {
    Ok(user) => process(user),
    Err(UserError::NotFound(_)) => create_default_user(),
    Err(e) => return Err(e),
}
```

## Struct Definitions

```rust
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub name: String,
    pub email: String,
    pub created_at: DateTime<Utc>,
    pub is_active: bool,
}

#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub name: String,
    pub email: String,
}

impl User {
    pub fn new(name: String, email: String) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            name,
            email,
            created_at: Utc::now(),
            is_active: true,
        }
    }
}
```

## Traits

```rust
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: &str) -> Result<Option<User>, DbError>;
    async fn create(&self, user: &User) -> Result<(), DbError>;
    async fn update(&self, user: &User) -> Result<(), DbError>;
    async fn delete(&self, id: &str) -> Result<(), DbError>;
}

pub struct UserService<R: UserRepository> {
    repo: R,
}

impl<R: UserRepository> UserService<R> {
    pub fn new(repo: R) -> Self {
        Self { repo }
    }

    pub async fn get_user(&self, id: &str) -> Result<User, UserError> {
        self.repo
            .find_by_id(id)
            .await?
            .ok_or_else(|| UserError::NotFound(id.to_string()))
    }
}
```

## Ownership & Borrowing

```rust
// Taking ownership
fn process_user(user: User) -> ProcessedUser {
    // user is moved here, caller can't use it anymore
    ProcessedUser::from(user)
}

// Borrowing (read-only)
fn display_user(user: &User) {
    println!("User: {}", user.name);
    // user is borrowed, caller still owns it
}

// Mutable borrowing
fn update_name(user: &mut User, name: String) {
    user.name = name;
}

// Clone when you need a copy
let user_copy = user.clone();
```

## Iterators

```rust
// Chaining iterators
let active_names: Vec<String> = users
    .iter()
    .filter(|u| u.is_active)
    .map(|u| u.name.clone())
    .collect();

// Parallel iteration with rayon
use rayon::prelude::*;

let results: Vec<_> = items
    .par_iter()
    .map(|item| process(item))
    .collect();
```

## Async/Await

```rust
use tokio;

// Concurrent execution
pub async fn fetch_all() -> Result<(Users, Products), Error> {
    let (users, products) = tokio::join!(
        fetch_users(),
        fetch_products()
    );
    Ok((users?, products?))
}

// With timeout
use tokio::time::{timeout, Duration};

let result = timeout(Duration::from_secs(5), fetch_data())
    .await
    .map_err(|_| Error::Timeout)??;
```

## Axum Web Framework

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", get(get_user).delete(delete_user))
        .with_state(state)
}

async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<User>, StatusCode> {
    state
        .user_service
        .get_user(&id)
        .await
        .map(Json)
        .map_err(|e| match e {
            UserError::NotFound(_) => StatusCode::NOT_FOUND,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        })
}
```

## Project Structure

```
project/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── api/
│   │   ├── mod.rs
│   │   └── handlers.rs
│   ├── domain/
│   │   ├── mod.rs
│   │   └── user.rs
│   ├── repository/
│   │   ├── mod.rs
│   │   └── user_repo.rs
│   └── service/
│       ├── mod.rs
│       └── user_service.rs
├── tests/
│   └── integration_tests.rs
├── Cargo.toml
└── Cargo.lock
```

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_creation() {
        let user = User::new("Test".to_string(), "test@example.com".to_string());

        assert_eq!(user.name, "Test");
        assert!(user.is_active);
    }

    #[tokio::test]
    async fn test_get_user() {
        let repo = MockUserRepository::new();
        let service = UserService::new(repo);

        let result = service.get_user("123").await;

        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_get_user_not_found() {
        let repo = MockUserRepository::empty();
        let service = UserService::new(repo);

        let result = service.get_user("999").await;

        assert!(matches!(result, Err(UserError::NotFound(_))));
    }
}
```

## Formatters & Linters

- **rustfmt**: Standard formatter
- **clippy**: Comprehensive linting
- **cargo check**: Fast type checking
- **cargo audit**: Security audit

## Debug Statements to Remove

```rust
// Remove before committing
println!()
dbg!()
eprintln!() // if only for debugging
```
