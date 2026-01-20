---
name: go-patterns
description: Go specific patterns, idioms, and best practices.
---

# Go Patterns

Language-specific patterns and idioms for Go.

## Error Handling

### Standard Pattern
```go
func GetUser(id string) (*User, error) {
    user, err := db.FindUser(id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user %s: %w", id, err)
    }
    return user, nil
}

// Usage
user, err := GetUser("123")
if err != nil {
    log.Error("failed to get user", "error", err)
    return err
}
```

### Custom Errors
```go
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with id %s not found", e.Resource, e.ID)
}

func GetUser(id string) (*User, error) {
    user, err := db.FindUser(id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, &NotFoundError{Resource: "user", ID: id}
        }
        return nil, fmt.Errorf("database error: %w", err)
    }
    return user, nil
}
```

### Error Checking
```go
// Check specific error type
var notFound *NotFoundError
if errors.As(err, &notFound) {
    http.Error(w, "Not found", http.StatusNotFound)
    return
}

// Check sentinel error
if errors.Is(err, ErrNotFound) {
    // handle not found
}
```

## Struct Definitions

```go
type User struct {
    ID        string    `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
    IsActive  bool      `json:"is_active"`
}

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=1,max=100"`
    Email string `json:"email" validate:"required,email"`
}
```

## Interfaces

```go
// Define small interfaces
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
}

type UserService struct {
    repo UserRepository
}

func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}
```

## Context Usage

```go
func GetUser(ctx context.Context, id string) (*User, error) {
    // Always pass context as first parameter
    // Check for cancellation in long operations
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    default:
    }

    return db.FindUser(ctx, id)
}

// With timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

user, err := GetUser(ctx, "123")
```

## Concurrency Patterns

### Goroutines with WaitGroup
```go
func ProcessItems(items []Item) error {
    var wg sync.WaitGroup
    errChan := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            if err := processItem(item); err != nil {
                errChan <- err
            }
        }(item)
    }

    wg.Wait()
    close(errChan)

    for err := range errChan {
        if err != nil {
            return err
        }
    }
    return nil
}
```

### Channels
```go
func FetchAll(urls []string) []Result {
    results := make(chan Result, len(urls))

    for _, url := range urls {
        go func(url string) {
            data, err := fetch(url)
            results <- Result{URL: url, Data: data, Err: err}
        }(url)
    }

    var all []Result
    for range urls {
        all = append(all, <-results)
    }
    return all
}
```

## HTTP Handlers

### Standard Library
```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id") // Go 1.22+

    user, err := h.service.GetUser(r.Context(), id)
    if err != nil {
        var notFound *NotFoundError
        if errors.As(err, &notFound) {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Internal error", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### Middleware
```go
func LoggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        log.Info("request",
            "method", r.Method,
            "path", r.URL.Path,
            "duration", time.Since(start),
        )
    })
}

func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if token == "" {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        // Validate token...
        next.ServeHTTP(w, r)
    })
}
```

## Project Structure

```
project/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handler/
│   │   └── user.go
│   ├── service/
│   │   └── user.go
│   ├── repository/
│   │   └── user.go
│   └── model/
│       └── user.go
├── pkg/
│   └── utils/
├── go.mod
└── go.sum
```

## Testing

```go
func TestGetUser(t *testing.T) {
    // Arrange
    repo := &MockUserRepository{
        users: map[string]*User{
            "123": {ID: "123", Name: "Test User"},
        },
    }
    service := NewUserService(repo)

    // Act
    user, err := service.GetUser(context.Background(), "123")

    // Assert
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "Test User" {
        t.Errorf("expected name 'Test User', got '%s'", user.Name)
    }
}

func TestGetUser_NotFound(t *testing.T) {
    repo := &MockUserRepository{users: map[string]*User{}}
    service := NewUserService(repo)

    _, err := service.GetUser(context.Background(), "999")

    var notFound *NotFoundError
    if !errors.As(err, &notFound) {
        t.Errorf("expected NotFoundError, got %T", err)
    }
}
```

## Formatters & Linters

- **gofmt**: Standard formatter (automatic)
- **goimports**: Import management
- **golangci-lint**: Comprehensive linting
- **go vet**: Static analysis

## Debug Statements to Remove

```go
// Remove before committing
fmt.Println()
fmt.Printf()
log.Println() // if only for debugging
spew.Dump()
```
