---
name: typescript-patterns
description: TypeScript and JavaScript specific patterns, React, Next.js, and Node.js best practices.
---

# TypeScript/JavaScript Patterns

Language-specific patterns for TypeScript, JavaScript, React, Next.js, and Node.js.

## Type Safety

### Proper Types
```typescript
// GOOD: Proper types
interface User {
  id: string
  name: string
  status: 'active' | 'inactive' | 'pending'
  createdAt: Date
}

function getUser(id: string): Promise<User> {
  // Implementation
}

// BAD: Using 'any'
function getUser(id: any): Promise<any> {
  // Implementation
}
```

### Type Guards
```typescript
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj && 'name' in obj
}

// Usage
if (isUser(data)) {
  console.log(data.name) // TypeScript knows data is User
}
```

### Utility Types
```typescript
// Partial - all properties optional
type UpdateUserDto = Partial<User>

// Pick - select specific properties
type UserPreview = Pick<User, 'id' | 'name'>

// Omit - exclude properties
type CreateUserDto = Omit<User, 'id' | 'createdAt'>

// Record - dictionary type
type UserMap = Record<string, User>
```

## Immutability Pattern (CRITICAL)

```typescript
// ALWAYS use spread operator
const updatedUser = {
  ...user,
  name: 'New Name'
}

const updatedArray = [...items, newItem]
const filteredArray = items.filter(item => item.active)

// NEVER mutate directly
user.name = 'New Name'  // BAD
items.push(newItem)     // BAD
```

## Async/Await Best Practices

```typescript
// GOOD: Parallel execution when possible
const [users, products, stats] = await Promise.all([
  fetchUsers(),
  fetchProducts(),
  fetchStats()
])

// BAD: Sequential when unnecessary
const users = await fetchUsers()
const products = await fetchProducts()
const stats = await fetchStats()
```

## Error Handling

```typescript
async function fetchData(url: string) {
  try {
    const response = await fetch(url)

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Fetch failed:', error)
    throw new Error('Failed to fetch data')
  }
}
```

## React Patterns

### Component Structure
```typescript
interface ButtonProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {children}
    </button>
  )
}
```

### Custom Hooks
```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}
```

### State Updates
```typescript
const [count, setCount] = useState(0)

// GOOD: Functional update for state based on previous state
setCount(prev => prev + 1)

// BAD: Direct state reference (can be stale)
setCount(count + 1)
```

## Input Validation with Zod

```typescript
import { z } from 'zod'

const UserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

type User = z.infer<typeof UserSchema>

// Usage
const validated = UserSchema.parse(input)
```

## File Naming Conventions

```
components/Button.tsx          # PascalCase for components
hooks/useAuth.ts              # camelCase with 'use' prefix
lib/formatDate.ts             # camelCase for utilities
types/user.types.ts           # camelCase with .types suffix
constants/config.ts           # camelCase for constants
```

## Testing with Vitest/Jest

```typescript
import { describe, it, expect } from 'vitest'

describe('calculateTotal', () => {
  it('returns zero for empty cart', () => {
    expect(calculateTotal([])).toBe(0)
  })

  it('sums all item prices', () => {
    const items = [{ price: 10 }, { price: 20 }]
    expect(calculateTotal(items)).toBe(30)
  })
})
```

## Formatters & Linters

- **Prettier**: Code formatting
- **ESLint**: Linting with TypeScript rules
- **TypeScript**: Type checking with `tsc --noEmit`

## Debug Statements to Remove

```typescript
// Remove before committing
console.log()
console.debug()
console.info()
debugger
```
