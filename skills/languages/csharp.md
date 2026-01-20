---
name: csharp-patterns
description: C# and .NET specific patterns, ASP.NET Core, and best practices.
---

# C# & .NET Patterns

Language-specific patterns for C#, .NET, and ASP.NET Core applications.

## C# Fundamentals

### Record Types (C# 9+)
```csharp
// Immutable data class
public record User(
    string Id,
    string Name,
    string Email,
    DateTime CreatedAt,
    bool IsActive = true
);

// With-expression for immutable updates
var updatedUser = user with { Name = "New Name" };

// Record with validation
public record CreateUserRequest(string Name, string Email)
{
    public CreateUserRequest
    {
        if (string.IsNullOrWhiteSpace(Name))
            throw new ArgumentException("Name is required", nameof(Name));
        if (string.IsNullOrWhiteSpace(Email))
            throw new ArgumentException("Email is required", nameof(Email));
    }
}
```

### Class with Properties
```csharp
public class User
{
    public string Id { get; init; } = Guid.NewGuid().ToString();
    public required string Name { get; init; }
    public required string Email { get; init; }
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
    public bool IsActive { get; init; } = true;
}

// Usage
var user = new User
{
    Name = "John Doe",
    Email = "john@example.com"
};
```

### Nullable Reference Types
```csharp
#nullable enable

public class UserService
{
    // Non-nullable return
    public User GetUser(string id)
    {
        return _repository.FindById(id)
            ?? throw new NotFoundException($"User {id} not found");
    }

    // Nullable return
    public User? FindUser(string id)
    {
        return _repository.FindById(id);
    }

    // Nullable parameter
    public void UpdateUser(string id, string? nickname)
    {
        var user = GetUser(id);
        if (nickname is not null)
        {
            user.Nickname = nickname;
        }
    }
}
```

### Pattern Matching
```csharp
// Switch expressions
public string GetStatusMessage(UserStatus status) => status switch
{
    UserStatus.Active => "User is active",
    UserStatus.Inactive => "User is inactive",
    UserStatus.Pending => "User is pending approval",
    _ => throw new ArgumentOutOfRangeException(nameof(status))
};

// Type patterns
public decimal CalculateDiscount(object customer) => customer switch
{
    PremiumCustomer p => p.BaseDiscount + 0.1m,
    RegularCustomer r when r.OrderCount > 10 => 0.05m,
    RegularCustomer => 0.02m,
    null => throw new ArgumentNullException(nameof(customer)),
    _ => 0m
};

// Property patterns
public bool IsEligible(User user) => user is
{
    IsActive: true,
    Email: { Length: > 0 }
};
```

### Async/Await
```csharp
// Async method
public async Task<User> GetUserAsync(string id)
{
    var user = await _repository.FindByIdAsync(id);
    return user ?? throw new NotFoundException($"User {id} not found");
}

// Parallel execution
public async Task<(List<User> Users, List<Product> Products)> GetAllDataAsync()
{
    var usersTask = _userRepository.GetAllAsync();
    var productsTask = _productRepository.GetAllAsync();

    await Task.WhenAll(usersTask, productsTask);

    return (await usersTask, await productsTask);
}

// Async enumerable
public async IAsyncEnumerable<User> GetUsersStreamAsync(
    [EnumeratorCancellation] CancellationToken cancellationToken = default)
{
    await foreach (var user in _repository.StreamUsersAsync()
        .WithCancellation(cancellationToken))
    {
        yield return user;
    }
}
```

## ASP.NET Core Patterns

### Controller
```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers(
        [FromQuery] int page = 0,
        [FromQuery] int size = 20)
    {
        var users = await _userService.GetAllAsync(page, size);
        return Ok(users);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(string id)
    {
        var user = await _userService.FindByIdAsync(id);
        if (user is null)
            return NotFound();
        return Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser(
        [FromBody] CreateUserRequest request)
    {
        var user = await _userService.CreateAsync(request);
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<UserDto>> UpdateUser(
        string id,
        [FromBody] UpdateUserRequest request)
    {
        var user = await _userService.UpdateAsync(id, request);
        if (user is null)
            return NotFound();
        return Ok(user);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var deleted = await _userService.DeleteAsync(id);
        if (!deleted)
            return NotFound();
        return NoContent();
    }
}
```

### Minimal API (NET 6+)
```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddDbContext<AppDbContext>();

var app = builder.Build();

app.MapGet("/api/users", async (IUserService service) =>
    Results.Ok(await service.GetAllAsync()));

app.MapGet("/api/users/{id}", async (string id, IUserService service) =>
    await service.FindByIdAsync(id) is User user
        ? Results.Ok(user)
        : Results.NotFound());

app.MapPost("/api/users", async (CreateUserRequest request, IUserService service) =>
{
    var user = await service.CreateAsync(request);
    return Results.Created($"/api/users/{user.Id}", user);
});

app.MapDelete("/api/users/{id}", async (string id, IUserService service) =>
    await service.DeleteAsync(id)
        ? Results.NoContent()
        : Results.NotFound());

app.Run();
```

### Service Layer
```csharp
public interface IUserService
{
    Task<IEnumerable<UserDto>> GetAllAsync(int page, int size);
    Task<UserDto?> FindByIdAsync(string id);
    Task<UserDto> CreateAsync(CreateUserRequest request);
    Task<UserDto?> UpdateAsync(string id, UpdateUserRequest request);
    Task<bool> DeleteAsync(string id);
}

public class UserService : IUserService
{
    private readonly AppDbContext _context;
    private readonly IMapper _mapper;

    public UserService(AppDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<IEnumerable<UserDto>> GetAllAsync(int page, int size)
    {
        var users = await _context.Users
            .Skip(page * size)
            .Take(size)
            .ToListAsync();

        return _mapper.Map<IEnumerable<UserDto>>(users);
    }

    public async Task<UserDto?> FindByIdAsync(string id)
    {
        var user = await _context.Users.FindAsync(id);
        return user is null ? null : _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request)
    {
        var user = _mapper.Map<User>(request);
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return _mapper.Map<UserDto>(user);
    }

    public async Task<bool> DeleteAsync(string id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user is null) return false;

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        return true;
    }
}
```

### Entity Framework Core
```csharp
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasMany(e => e.Orders).WithOne(o => o.User);
        });
    }
}

// Repository pattern (optional)
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(string id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    void Update(T entity);
    void Delete(T entity);
    Task SaveChangesAsync();
}
```

### Exception Handling
```csharp
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (statusCode, response) = exception switch
        {
            NotFoundException e => (StatusCodes.Status404NotFound,
                new ErrorResponse("NOT_FOUND", e.Message)),
            ValidationException e => (StatusCodes.Status400BadRequest,
                new ErrorResponse("VALIDATION_ERROR", e.Message, e.Errors)),
            _ => (StatusCodes.Status500InternalServerError,
                new ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred"))
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
        {
            _logger.LogError(exception, "Unhandled exception");
        }

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);
        return true;
    }
}

public record ErrorResponse(string Code, string Message, IEnumerable<string>? Details = null);
```

### Validation with FluentValidation
```csharp
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(100).WithMessage("Name must be at most 100 characters");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Age)
            .InclusiveBetween(0, 150).WithMessage("Age must be between 0 and 150");
    }
}

// Registration in Program.cs
builder.Services.AddValidatorsFromAssemblyContaining<Program>();
```

### Dependency Injection
```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Scoped (per request)
builder.Services.AddScoped<IUserService, UserService>();

// Singleton (single instance)
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// Transient (new instance each time)
builder.Services.AddTransient<IEmailService, EmailService>();

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

// Options pattern
builder.Services.Configure<JwtOptions>(
    builder.Configuration.GetSection("Jwt"));
```

## LINQ

### Query Syntax vs Method Syntax
```csharp
// Method syntax (preferred)
var activeUsers = users
    .Where(u => u.IsActive)
    .OrderBy(u => u.Name)
    .Select(u => new UserDto(u.Id, u.Name, u.Email))
    .ToList();

// Query syntax
var activeUsers =
    from u in users
    where u.IsActive
    orderby u.Name
    select new UserDto(u.Id, u.Name, u.Email);

// Grouping
var usersByDomain = users
    .GroupBy(u => u.Email.Split('@')[1])
    .ToDictionary(g => g.Key, g => g.ToList());

// Aggregate
var stats = users
    .Aggregate(
        new { Count = 0, TotalAge = 0 },
        (acc, u) => new { Count = acc.Count + 1, TotalAge = acc.TotalAge + u.Age });
```

## Testing

### xUnit + Moq
```csharp
public class UserServiceTests
{
    private readonly Mock<AppDbContext> _contextMock;
    private readonly Mock<IMapper> _mapperMock;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _contextMock = new Mock<AppDbContext>();
        _mapperMock = new Mock<IMapper>();
        _sut = new UserService(_contextMock.Object, _mapperMock.Object);
    }

    [Fact]
    public async Task FindByIdAsync_ExistingUser_ReturnsUser()
    {
        // Arrange
        var user = new User { Id = "123", Name = "Test" };
        var userDto = new UserDto("123", "Test", "test@example.com");

        _contextMock.Setup(c => c.Users.FindAsync("123"))
            .ReturnsAsync(user);
        _mapperMock.Setup(m => m.Map<UserDto>(user))
            .Returns(userDto);

        // Act
        var result = await _sut.FindByIdAsync("123");

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Test", result.Name);
    }

    [Fact]
    public async Task FindByIdAsync_NonExistingUser_ReturnsNull()
    {
        // Arrange
        _contextMock.Setup(c => c.Users.FindAsync("999"))
            .ReturnsAsync((User?)null);

        // Act
        var result = await _sut.FindByIdAsync("999");

        // Assert
        Assert.Null(result);
    }
}
```

### Integration Test
```csharp
public class UsersControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetUsers_ReturnsOkResult()
    {
        // Act
        var response = await _client.GetAsync("/api/users");

        // Assert
        response.EnsureSuccessStatusCode();
        var users = await response.Content.ReadFromJsonAsync<List<UserDto>>();
        Assert.NotNull(users);
    }
}
```

## Project Structure

```
src/
├── MyApp.Api/
│   ├── Controllers/
│   ├── Middleware/
│   └── Program.cs
├── MyApp.Application/
│   ├── Services/
│   ├── DTOs/
│   └── Validators/
├── MyApp.Domain/
│   ├── Entities/
│   ├── Interfaces/
│   └── Exceptions/
└── MyApp.Infrastructure/
    ├── Data/
    ├── Repositories/
    └── External/

tests/
├── MyApp.UnitTests/
└── MyApp.IntegrationTests/
```

## Formatters & Linters

- **dotnet format**: Built-in formatter
- **.editorconfig**: Style configuration
- **StyleCop**: Style enforcement
- **SonarAnalyzer**: Code quality

## Debug Statements to Remove

```csharp
// Remove before committing
Console.WriteLine()
Console.Write()
Debug.WriteLine()
Debugger.Break()
```
