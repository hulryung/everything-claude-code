---
name: backend-patterns
description: Language-agnostic backend architecture patterns, API design, and server-side best practices.
---

# Backend Development Patterns

Language-agnostic backend architecture patterns and best practices for scalable server-side applications.

## API Design Patterns

### RESTful API Structure
```
GET    /api/resources           # List resources
GET    /api/resources/:id       # Get single resource
POST   /api/resources           # Create resource
PUT    /api/resources/:id       # Replace resource (full update)
PATCH  /api/resources/:id       # Update resource (partial)
DELETE /api/resources/:id       # Delete resource

# Query parameters for filtering, sorting, pagination
GET /api/resources?status=active&sort=created_at&limit=20&offset=0
```

### Response Format
```json
// Success response
{
  "success": true,
  "data": { ... },
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20
  }
}

// Error response
{
  "success": false,
  "error": "User-friendly error message",
  "code": "VALIDATION_ERROR",
  "details": [ ... ]
}
```

### HTTP Status Codes
```
200 OK              - Successful GET, PUT, PATCH
201 Created         - Successful POST
204 No Content      - Successful DELETE
400 Bad Request     - Validation error
401 Unauthorized    - Authentication required
403 Forbidden       - Insufficient permissions
404 Not Found       - Resource doesn't exist
409 Conflict        - Resource conflict
422 Unprocessable   - Semantic error
429 Too Many Reqs   - Rate limit exceeded
500 Internal Error  - Server error
```

## Architecture Patterns

### Repository Pattern
Abstracts data access logic from business logic.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Handler   │ --> │   Service   │ --> │ Repository  │
│  (HTTP/API) │     │  (Business) │     │   (Data)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Benefits:**
- Testable (mock repository in tests)
- Swappable storage (switch DB without changing business logic)
- Clear separation of concerns

### Service Layer Pattern
Contains business logic, orchestrates operations.

```
Handler → receives HTTP request, validates input
    ↓
Service → applies business rules, coordinates operations
    ↓
Repository → persists/retrieves data
```

### Middleware Pattern
Request/response processing pipeline.

```
Request → Auth → Logging → Rate Limit → Handler → Response
                                              ↓
                                    Response Middleware
```

**Common Middleware:**
- Authentication/Authorization
- Request logging
- Rate limiting
- CORS handling
- Request ID injection
- Error handling

## Database Patterns

### Query Optimization
```
# GOOD: Select only needed columns
SELECT id, name, email FROM users WHERE status = 'active' LIMIT 10

# BAD: Select everything
SELECT * FROM users
```

### N+1 Query Prevention
```
# BAD: N+1 queries
users = get_all_users()
for user in users:
    orders = get_orders_for_user(user.id)  # N queries!

# GOOD: Batch fetch
users = get_all_users()
user_ids = [u.id for u in users]
orders = get_orders_for_users(user_ids)  # 1 query
orders_by_user = group_by(orders, 'user_id')
```

### Connection Pooling
- Reuse database connections
- Configure pool size based on load
- Set appropriate timeouts
- Handle connection errors gracefully

### Transaction Pattern
```
BEGIN TRANSACTION
    INSERT INTO orders (...)
    UPDATE inventory SET quantity = quantity - 1
    INSERT INTO order_items (...)
COMMIT

ON ERROR:
    ROLLBACK
```

## Caching Strategies

### Cache-Aside Pattern
```
function get_user(id):
    # Check cache first
    cached = cache.get("user:" + id)
    if cached:
        return cached

    # Cache miss - fetch from DB
    user = db.find_user(id)

    # Store in cache with TTL
    cache.set("user:" + id, user, ttl=300)

    return user
```

### Cache Invalidation
```
function update_user(id, data):
    # Update database
    db.update_user(id, data)

    # Invalidate cache
    cache.delete("user:" + id)
```

### Caching Best Practices
- Set appropriate TTLs
- Cache at the right layer
- Handle cache failures gracefully
- Monitor cache hit rates

## Error Handling

### Centralized Error Handler
```
function handle_error(error):
    if error is ValidationError:
        return response(400, "Validation failed", error.details)

    if error is NotFoundError:
        return response(404, "Resource not found")

    if error is AuthenticationError:
        return response(401, "Authentication required")

    # Log unexpected errors
    log.error("Unexpected error", error)
    return response(500, "Internal server error")
```

### Retry with Exponential Backoff
```
function fetch_with_retry(operation, max_retries=3):
    for i in range(max_retries):
        try:
            return operation()
        except TransientError:
            if i == max_retries - 1:
                raise
            delay = min(2^i * 1000, 30000)  # Max 30s
            sleep(delay)
```

## Authentication & Authorization

### Token-Based Auth Flow
```
1. Client sends credentials
2. Server validates, returns token (JWT)
3. Client stores token
4. Client sends token in Authorization header
5. Server validates token on each request
```

### Role-Based Access Control (RBAC)
```
Roles:
  admin: [read, write, delete, admin]
  moderator: [read, write, delete]
  user: [read, write]

function check_permission(user, permission):
    return permission in roles[user.role]
```

### API Key Authentication
- Use for server-to-server communication
- Store hashed keys
- Rotate keys periodically
- Rate limit per key

## Rate Limiting

### Strategies
```
# Fixed Window
100 requests per minute per IP

# Sliding Window
More accurate, prevents burst at window edges

# Token Bucket
Allows controlled bursts
```

### Implementation
```
function rate_limit(identifier, limit, window):
    current = get_request_count(identifier, window)
    if current >= limit:
        return error(429, "Rate limit exceeded")
    increment_request_count(identifier)
    continue_request()
```

## Background Jobs & Queues

### Queue Pattern
```
# Producer
queue.add({
    type: "send_email",
    data: { to: "user@example.com", subject: "..." }
})

# Consumer
while true:
    job = queue.pop()
    try:
        process(job)
        job.complete()
    except:
        job.retry() or job.fail()
```

### Use Cases
- Email sending
- Report generation
- Data processing
- Scheduled tasks
- Webhook delivery

## Logging & Monitoring

### Structured Logging
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "error",
  "message": "Failed to process order",
  "request_id": "abc-123",
  "user_id": "user-456",
  "order_id": "order-789",
  "error": "Insufficient inventory",
  "stack_trace": "..."
}
```

### What to Log
- Request/response metadata
- Authentication events
- Errors with context
- Business events
- Performance metrics

### What NOT to Log
- Passwords
- API keys/tokens
- Credit card numbers
- Personal data (PII)

## Health Checks

### Endpoint Design
```
GET /health         # Simple liveness check
GET /health/ready   # Readiness check (dependencies)

Response:
{
  "status": "healthy",
  "checks": {
    "database": "ok",
    "cache": "ok",
    "queue": "degraded"
  }
}
```

## API Versioning

### Strategies
```
# URL Path (recommended)
/api/v1/users
/api/v2/users

# Header
Accept: application/vnd.api+json; version=1

# Query Parameter
/api/users?version=1
```

---

**Remember**: Backend patterns enable scalable, maintainable server-side applications. Choose patterns that fit your complexity level - don't over-engineer.
