---
name: java-patterns
description: Java and Kotlin specific patterns, Spring Boot, and JVM best practices.
---

# Java & Kotlin Patterns

Language-specific patterns for Java, Kotlin, Spring Boot, and JVM applications.

## Java Fundamentals

### Class Structure
```java
public class User {
    private final String id;
    private final String name;
    private final String email;
    private final Instant createdAt;
    private final boolean active;

    // Use builder or factory method for complex objects
    private User(Builder builder) {
        this.id = builder.id;
        this.name = builder.name;
        this.email = builder.email;
        this.createdAt = builder.createdAt;
        this.active = builder.active;
    }

    // Getters only - immutable
    public String getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public Instant getCreatedAt() { return createdAt; }
    public boolean isActive() { return active; }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String id;
        private String name;
        private String email;
        private Instant createdAt = Instant.now();
        private boolean active = true;

        public Builder id(String id) { this.id = id; return this; }
        public Builder name(String name) { this.name = name; return this; }
        public Builder email(String email) { this.email = email; return this; }
        public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
        public Builder active(boolean active) { this.active = active; return this; }

        public User build() {
            return new User(this);
        }
    }
}
```

### Records (Java 16+)
```java
// Immutable data class
public record UserDto(
    String id,
    String name,
    String email,
    Instant createdAt
) {
    // Compact constructor for validation
    public UserDto {
        Objects.requireNonNull(id, "id cannot be null");
        Objects.requireNonNull(name, "name cannot be null");
        Objects.requireNonNull(email, "email cannot be null");
    }
}
```

### Optional Usage
```java
// GOOD: Proper Optional usage
public Optional<User> findById(String id) {
    return userRepository.findById(id);
}

// Usage
findById("123")
    .map(User::getName)
    .orElse("Unknown");

// BAD: Don't use Optional for fields or parameters
public class User {
    private Optional<String> nickname; // BAD
}

// GOOD: Use nullable with annotation
public class User {
    @Nullable
    private String nickname;
}
```

## Kotlin Patterns

### Data Classes
```kotlin
data class User(
    val id: String,
    val name: String,
    val email: String,
    val createdAt: Instant = Instant.now(),
    val active: Boolean = true
)

// Copy with modifications (immutable update)
val updatedUser = user.copy(name = "New Name")
```

### Null Safety
```kotlin
// Nullable types
fun findUser(id: String): User? {
    return userRepository.findById(id)
}

// Safe calls
val name = user?.name ?: "Unknown"

// Let for null checks
user?.let {
    processUser(it)
}

// Elvis operator with throw
val user = findUser(id) ?: throw NotFoundException("User not found")
```

### Extension Functions
```kotlin
// Add functionality to existing classes
fun String.isValidEmail(): Boolean {
    return this.matches(Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$"))
}

// Usage
if (email.isValidEmail()) {
    // process
}

// Extension on collections
fun <T> List<T>.secondOrNull(): T? = this.getOrNull(1)
```

### Coroutines
```kotlin
// Suspend functions
suspend fun fetchUser(id: String): User {
    return withContext(Dispatchers.IO) {
        userRepository.findById(id)
    }
}

// Parallel execution
suspend fun fetchAll(): Pair<List<User>, List<Product>> = coroutineScope {
    val users = async { fetchUsers() }
    val products = async { fetchProducts() }
    users.await() to products.await()
}

// Flow for streams
fun observeUsers(): Flow<User> = flow {
    while (true) {
        emit(fetchLatestUser())
        delay(1000)
    }
}
```

## Spring Boot Patterns

### Controller Layer
```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<UserDto>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(userService.findAll(page, size));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable String id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<UserDto> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        UserDto created = userService.create(request);
        URI location = URI.create("/api/users/" + created.id());
        return ResponseEntity.created(location).body(created);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable String id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

### Service Layer
```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public List<UserDto> findAll(int page, int size) {
        return userRepository.findAll(PageRequest.of(page, size))
            .map(userMapper::toDto)
            .getContent();
    }

    public Optional<UserDto> findById(String id) {
        return userRepository.findById(id)
            .map(userMapper::toDto);
    }

    @Transactional
    public UserDto create(CreateUserRequest request) {
        User user = userMapper.toEntity(request);
        User saved = userRepository.save(user);
        return userMapper.toDto(saved);
    }

    @Transactional
    public void delete(String id) {
        if (!userRepository.existsById(id)) {
            throw new NotFoundException("User not found: " + id);
        }
        userRepository.deleteById(id);
    }
}
```

### Repository Layer
```java
@Repository
public interface UserRepository extends JpaRepository<User, String> {

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.active = true AND u.createdAt > :since")
    List<User> findActiveUsersSince(@Param("since") Instant since);

    @Query(value = "SELECT * FROM users WHERE email LIKE %:domain", nativeQuery = true)
    List<User> findByEmailDomain(@Param("domain") String domain);

    boolean existsByEmail(String email);
}
```

### Exception Handling
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();

        return ResponseEntity.badRequest()
            .body(new ErrorResponse("VALIDATION_ERROR", "Validation failed", errors));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(new ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred"));
    }
}

public record ErrorResponse(
    String code,
    String message,
    List<String> details
) {
    public ErrorResponse(String code, String message) {
        this(code, message, List.of());
    }
}
```

### Validation
```java
public record CreateUserRequest(
    @NotBlank(message = "Name is required")
    @Size(min = 1, max = 100, message = "Name must be 1-100 characters")
    String name,

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email,

    @Min(value = 0, message = "Age must be non-negative")
    @Max(value = 150, message = "Age must be at most 150")
    Integer age
) {}
```

## Dependency Injection

### Constructor Injection (Preferred)
```java
@Service
@RequiredArgsConstructor // Lombok generates constructor
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final UserMapper userMapper;
}
```

### Kotlin with Spring
```kotlin
@Service
class UserService(
    private val userRepository: UserRepository,
    private val emailService: EmailService
) {
    fun findById(id: String): User? = userRepository.findById(id).orElse(null)
}
```

## Stream API

### Collection Processing
```java
// Filter and map
List<String> activeUserNames = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .sorted()
    .toList();

// Grouping
Map<String, List<User>> usersByDomain = users.stream()
    .collect(Collectors.groupingBy(u -> u.getEmail().split("@")[1]));

// Reduce
int totalAge = users.stream()
    .mapToInt(User::getAge)
    .sum();

// FlatMap
List<Order> allOrders = users.stream()
    .flatMap(u -> u.getOrders().stream())
    .toList();
```

## Testing

### JUnit 5 + Mockito
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Test
    void findById_existingUser_returnsUser() {
        // Arrange
        User user = User.builder().id("123").name("Test").build();
        when(userRepository.findById("123")).thenReturn(Optional.of(user));

        // Act
        Optional<UserDto> result = userService.findById("123");

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().name()).isEqualTo("Test");
        verify(userRepository).findById("123");
    }

    @Test
    void findById_nonExistingUser_returnsEmpty() {
        // Arrange
        when(userRepository.findById("999")).thenReturn(Optional.empty());

        // Act
        Optional<UserDto> result = userService.findById("999");

        // Assert
        assertThat(result).isEmpty();
    }
}
```

### Spring Boot Test
```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createUser_validRequest_returnsCreated() throws Exception {
        CreateUserRequest request = new CreateUserRequest("Test", "test@example.com", 25);

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Test"))
            .andExpect(jsonPath("$.email").value("test@example.com"));
    }
}
```

## Project Structure

```
src/
├── main/
│   ├── java/com/example/app/
│   │   ├── Application.java
│   │   ├── config/
│   │   │   └── SecurityConfig.java
│   │   ├── controller/
│   │   │   └── UserController.java
│   │   ├── service/
│   │   │   └── UserService.java
│   │   ├── repository/
│   │   │   └── UserRepository.java
│   │   ├── entity/
│   │   │   └── User.java
│   │   ├── dto/
│   │   │   ├── UserDto.java
│   │   │   └── CreateUserRequest.java
│   │   ├── mapper/
│   │   │   └── UserMapper.java
│   │   └── exception/
│   │       ├── NotFoundException.java
│   │       └── GlobalExceptionHandler.java
│   └── resources/
│       └── application.yml
└── test/
    └── java/com/example/app/
        └── service/
            └── UserServiceTest.java
```

## Formatters & Linters

- **google-java-format**: Code formatting
- **Checkstyle**: Style enforcement
- **SpotBugs**: Bug detection
- **SonarQube**: Code quality
- **ktlint**: Kotlin linting

## Debug Statements to Remove

```java
// Remove before committing
System.out.println()
System.out.print()
System.err.println()
e.printStackTrace()

// Kotlin
println()
print()
```
