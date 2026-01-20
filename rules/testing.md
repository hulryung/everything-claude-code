# Testing Requirements

Universal testing requirements applicable to any programming language.

## Minimum Test Coverage: 80%

Test Types (ALL required for production code):
1. **Unit Tests** - Individual functions, utilities, pure logic
2. **Integration Tests** - API endpoints, database operations, external services
3. **E2E Tests** - Critical user flows, happy paths

## Test-Driven Development (TDD)

Recommended workflow:
1. **RED** - Write test first, it should FAIL
2. **GREEN** - Write minimal implementation to PASS
3. **REFACTOR** - Improve code while keeping tests green
4. Verify coverage (80%+)

## Test Structure (AAA Pattern)

```
function test_calculates_total_correctly():
    # Arrange - Set up test data
    items = [{"price": 10}, {"price": 20}]

    # Act - Execute the code under test
    total = calculate_total(items)

    # Assert - Verify the result
    assert total == 30
```

## Test Naming

```
# GOOD: Descriptive test names
test_returns_empty_array_when_no_items_found()
test_throws_error_when_input_is_invalid()
test_calculates_discount_for_premium_users()

# BAD: Vague test names
test_works()
test_function()
test_1()
```

## What to Test

- **Happy paths** - Expected behavior
- **Edge cases** - Empty inputs, null values, boundaries
- **Error conditions** - Invalid inputs, failures
- **Integration points** - API calls, database queries

## What NOT to Test

- Third-party library internals
- Framework code
- Trivial getters/setters
- Private implementation details

## Troubleshooting Test Failures

1. Check test isolation (no shared state)
2. Verify mocks are correct
3. Fix implementation, not tests (unless tests are wrong)
4. Check for race conditions in async tests

## Agent Support

Use these agents for testing:
- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first
- **e2e-runner** - E2E testing specialist (Playwright, Cypress, Selenium)
