---
name: coding-standards
description: Universal coding standards and best practices applicable to any programming language.
---

# Universal Coding Standards & Best Practices

Language-agnostic coding principles for high-quality software development.

## Core Principles

### 1. Readability First
- Code is read 10x more than written
- Clear, descriptive names for variables, functions, and classes
- Self-documenting code preferred over comments
- Consistent formatting throughout the codebase

### 2. KISS (Keep It Simple, Stupid)
- Choose the simplest solution that works
- Avoid over-engineering and premature abstraction
- No premature optimization
- Easy to understand > clever code

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into reusable functions
- Create shared utilities across modules
- Avoid copy-paste programming
- But: don't abstract too early (Rule of Three)

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

### 5. Single Responsibility Principle
- Each function/class should do one thing well
- If you can't describe it without "and", split it
- High cohesion within modules
- Low coupling between modules

## Naming Conventions

### Variables
```
# GOOD: Descriptive names
user_count, is_authenticated, total_revenue, search_query

# BAD: Unclear names
x, flag, temp, data, val, n
```

### Functions/Methods
```
# GOOD: Verb-noun pattern, describes action
fetch_user_data(), calculate_similarity(), is_valid_email()
validate_input(), process_payment(), send_notification()

# BAD: Vague or noun-only
data(), process(), handle(), do_stuff()
```

### Classes/Types
```
# GOOD: Noun, describes what it represents
UserRepository, PaymentProcessor, EmailValidator
HttpClient, DatabaseConnection, CacheManager

# BAD: Vague or action-like
Manager, Helper, Processor, Handler (without context)
```

### Constants
```
# GOOD: SCREAMING_SNAKE_CASE, descriptive
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_MS = 5000
API_BASE_URL = "https://api.example.com"

# BAD: Magic numbers inline
if retry_count > 3:  # What is 3?
```

## Code Organization

### File Structure
- **Many small files > Few large files**
- High cohesion, low coupling
- 200-400 lines typical, 800 max per file
- Organize by feature/domain, not by type

### Function Length
- Keep functions under 50 lines
- If longer, extract helper functions
- Each function should fit on one screen

### Nesting Depth
- Maximum 3-4 levels of nesting
- Use early returns to reduce nesting
- Extract complex conditions into named functions

```
# BAD: Deep nesting
if user:
    if user.is_active:
        if user.has_permission:
            if resource.is_available:
                # do something

# GOOD: Early returns
if not user:
    return
if not user.is_active:
    return
if not user.has_permission:
    return
if not resource.is_available:
    return
# do something
```

## Error Handling

### General Principles
- Always handle errors explicitly
- Fail fast, fail loudly
- Provide meaningful error messages
- Log errors with context

### Pattern
```
try:
    result = risky_operation()
    return result
except SpecificError as e:
    log.error("Operation failed", context={"error": e, "input": input})
    raise UserFriendlyError("Could not complete operation")
```

### What NOT to Do
- Don't silently swallow exceptions
- Don't catch generic exceptions without re-raising
- Don't use exceptions for control flow
- Don't expose internal errors to users

## Immutability (Preferred)

### Why Immutability?
- Prevents unexpected side effects
- Easier to reason about code
- Better for concurrent programming
- Simplifies debugging

### Pattern
```
# GOOD: Create new objects
updated_user = {**user, "name": new_name}
updated_list = [*items, new_item]

# BAD: Mutate in place
user["name"] = new_name  # Side effect!
items.append(new_item)   # Modifies original!
```

## Comments & Documentation

### When to Comment
```
# GOOD: Explain WHY, not WHAT
# Use exponential backoff to avoid overwhelming the API during outages
delay = min(1000 * (2 ** retry_count), 30000)

# Deliberately using mutation here for performance with large arrays
items.push(new_item)

# BAD: Stating the obvious
# Increment counter by 1
count += 1

# Loop through users
for user in users:
```

### Documentation Standards
- Document public APIs with purpose, parameters, return values
- Include examples for complex functions
- Keep documentation close to code
- Update docs when code changes

## Testing Standards

### Test Structure (AAA Pattern)
```
def test_calculates_similarity_correctly():
    # Arrange
    vector1 = [1, 0, 0]
    vector2 = [0, 1, 0]

    # Act
    similarity = calculate_cosine_similarity(vector1, vector2)

    # Assert
    assert similarity == 0
```

### Test Naming
```
# GOOD: Descriptive test names
test_returns_empty_array_when_no_markets_match_query()
test_throws_error_when_api_key_is_missing()
test_falls_back_to_substring_search_when_cache_unavailable()

# BAD: Vague test names
test_works()
test_search()
test_function()
```

### Coverage Target
- Aim for 80% code coverage minimum
- 100% coverage for critical paths
- Unit tests for utilities and pure functions
- Integration tests for APIs and database operations
- E2E tests for critical user flows

## Code Smell Detection

### Watch for These Anti-patterns

**1. Long Functions (>50 lines)**
- Split into smaller, focused functions
- Extract helper methods

**2. Deep Nesting (>4 levels)**
- Use early returns
- Extract conditions into named functions

**3. Magic Numbers/Strings**
- Define named constants
- Use configuration files

**4. God Classes/Functions**
- Split by responsibility
- Use composition over inheritance

**5. Duplicate Code**
- Extract into shared utilities
- But wait for the third occurrence (Rule of Three)

**6. Long Parameter Lists (>4 params)**
- Use parameter objects
- Consider builder pattern

**7. Feature Envy**
- Method uses another object's data too much
- Move method to that object

## API Design Principles

### REST Conventions
```
GET    /api/resources           # List resources
GET    /api/resources/:id       # Get single resource
POST   /api/resources           # Create resource
PUT    /api/resources/:id       # Replace resource
PATCH  /api/resources/:id       # Update resource
DELETE /api/resources/:id       # Delete resource

# Query parameters for filtering
GET /api/resources?status=active&limit=10&offset=0
```

### Response Format
```
# Success
{
  "success": true,
  "data": { ... },
  "meta": { "total": 100, "page": 1 }
}

# Error
{
  "success": false,
  "error": "User-friendly error message",
  "code": "VALIDATION_ERROR"
}
```

## Security Basics

- Never hardcode secrets or credentials
- Validate all user input
- Use parameterized queries (prevent SQL injection)
- Sanitize output (prevent XSS)
- Use HTTPS everywhere
- Implement proper authentication/authorization
- Log security events

## Performance Basics

- Measure before optimizing
- Optimize the critical path
- Use appropriate data structures
- Batch database operations
- Implement caching strategically
- Use async/parallel operations when beneficial

---

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
