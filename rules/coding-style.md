# Coding Style

Universal coding style rules applicable to any programming language.

## Immutability (Preferred)

Create new objects instead of mutating existing ones:

```
# WRONG: Mutation
function update_user(user, name):
    user.name = name  # MUTATION!
    return user

# CORRECT: Immutability
function update_user(user, name):
    return {
        ...user,
        name: name
    }
```

## File Organization

**MANY SMALL FILES > FEW LARGE FILES:**
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:

```
try:
    result = risky_operation()
    return result
catch error:
    log.error("Operation failed:", error)
    raise UserFriendlyError("Detailed user-friendly message")
```

## Input Validation

ALWAYS validate user input at system boundaries:
- API endpoints
- Form submissions
- File uploads
- External data sources

## Naming Conventions

- Variables: descriptive, lowercase with underscores or camelCase
- Functions: verb_noun pattern (get_user, calculate_total)
- Classes: PascalCase, noun describing what it represents
- Constants: SCREAMING_SNAKE_CASE

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No debug statements (print, console.log, etc.)
- [ ] No hardcoded values (use constants)
- [ ] Immutable patterns used where possible
