---
name: php-patterns
description: PHP specific patterns, Laravel, Symfony, and best practices.
---

# PHP Patterns

Language-specific patterns for PHP, Laravel, and Symfony applications.

## PHP Fundamentals

### Class Definition
```php
<?php

declare(strict_types=1);

namespace App\Models;

use DateTimeImmutable;

final class User
{
    public function __construct(
        private readonly string $id,
        private readonly string $name,
        private readonly string $email,
        private readonly DateTimeImmutable $createdAt,
        private bool $active = true,
    ) {}

    public function getId(): string
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function isActive(): bool
    {
        return $this->active;
    }

    public function deactivate(): self
    {
        $clone = clone $this;
        $clone->active = false;
        return $clone;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->createdAt->format('c'),
            'active' => $this->active,
        ];
    }
}
```

### DTOs with readonly classes (PHP 8.2+)
```php
<?php

declare(strict_types=1);

namespace App\DTO;

final readonly class CreateUserDto
{
    public function __construct(
        public string $name,
        public string $email,
        public ?int $age = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            name: $data['name'],
            email: $data['email'],
            age: $data['age'] ?? null,
        );
    }
}
```

### Enums (PHP 8.1+)
```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum UserStatus: string
{
    case Pending = 'pending';
    case Active = 'active';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match($this) {
            self::Pending => 'Pending Approval',
            self::Active => 'Active',
            self::Suspended => 'Suspended',
        };
    }

    public function isActive(): bool
    {
        return $this === self::Active;
    }
}
```

### Traits
```php
<?php

declare(strict_types=1);

namespace App\Traits;

trait HasUuid
{
    public static function bootHasUuid(): void
    {
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }

    public function getIncrementing(): bool
    {
        return false;
    }

    public function getKeyType(): string
    {
        return 'string';
    }
}
```

### Interfaces
```php
<?php

declare(strict_types=1);

namespace App\Contracts;

interface UserRepositoryInterface
{
    public function findById(string $id): ?User;
    public function findByEmail(string $email): ?User;
    public function create(CreateUserDto $dto): User;
    public function update(string $id, UpdateUserDto $dto): User;
    public function delete(string $id): bool;
    public function paginate(int $page = 1, int $perPage = 20): LengthAwarePaginator;
}
```

## Laravel Patterns

### Model
```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

final class User extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'email',
        'status',
    ];

    protected $casts = [
        'status' => UserStatus::class,
        'email_verified_at' => 'datetime',
        'active' => 'boolean',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Relationships
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    // Scopes
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('active', true);
    }

    public function scopeByStatus(Builder $query, UserStatus $status): Builder
    {
        return $query->where('status', $status);
    }

    // Accessors
    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn () => "{$this->first_name} {$this->last_name}",
        );
    }

    // Methods
    public function isActive(): bool
    {
        return $this->active && $this->status === UserStatus::Active;
    }

    public function deactivate(): void
    {
        $this->update([
            'active' => false,
            'deactivated_at' => now(),
        ]);
    }
}
```

### Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Resources\UserResource;
use App\Http\Resources\UserCollection;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

final class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService,
    ) {}

    public function index(): UserCollection
    {
        $users = $this->userService->paginate(
            page: request()->integer('page', 1),
            perPage: request()->integer('per_page', 20),
        );

        return new UserCollection($users);
    }

    public function show(string $id): UserResource
    {
        $user = $this->userService->findOrFail($id);

        return new UserResource($user);
    }

    public function store(CreateUserRequest $request): JsonResponse
    {
        $user = $this->userService->create($request->toDto());

        return (new UserResource($user))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function update(string $id, UpdateUserRequest $request): UserResource
    {
        $user = $this->userService->update($id, $request->toDto());

        return new UserResource($user);
    }

    public function destroy(string $id): JsonResponse
    {
        $this->userService->delete($id);

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }
}
```

### Form Request
```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\DTO\CreateUserDto;
use Illuminate\Foundation\Http\FormRequest;

final class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'unique:users,email'],
            'age' => ['nullable', 'integer', 'min:0', 'max:150'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Name is required',
            'email.unique' => 'This email is already registered',
        ];
    }

    public function toDto(): CreateUserDto
    {
        return new CreateUserDto(
            name: $this->validated('name'),
            email: $this->validated('email'),
            age: $this->validated('age'),
        );
    }
}
```

### Service
```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Contracts\UserRepositoryInterface;
use App\DTO\CreateUserDto;
use App\DTO\UpdateUserDto;
use App\Events\UserCreated;
use App\Exceptions\UserNotFoundException;
use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

final class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $repository,
    ) {}

    public function findOrFail(string $id): User
    {
        return $this->repository->findById($id)
            ?? throw new UserNotFoundException($id);
    }

    public function paginate(int $page, int $perPage): LengthAwarePaginator
    {
        return $this->repository->paginate($page, $perPage);
    }

    public function create(CreateUserDto $dto): User
    {
        return DB::transaction(function () use ($dto) {
            $user = $this->repository->create($dto);

            event(new UserCreated($user));

            return $user;
        });
    }

    public function update(string $id, UpdateUserDto $dto): User
    {
        $this->findOrFail($id);

        return $this->repository->update($id, $dto);
    }

    public function delete(string $id): bool
    {
        $this->findOrFail($id);

        return $this->repository->delete($id);
    }
}
```

### Repository
```php
<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Contracts\UserRepositoryInterface;
use App\DTO\CreateUserDto;
use App\DTO\UpdateUserDto;
use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;

final class EloquentUserRepository implements UserRepositoryInterface
{
    public function findById(string $id): ?User
    {
        return User::find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function create(CreateUserDto $dto): User
    {
        return User::create([
            'name' => $dto->name,
            'email' => $dto->email,
            'age' => $dto->age,
        ]);
    }

    public function update(string $id, UpdateUserDto $dto): User
    {
        $user = User::findOrFail($id);
        $user->update(array_filter([
            'name' => $dto->name,
            'email' => $dto->email,
            'age' => $dto->age,
        ], fn ($value) => $value !== null));

        return $user->fresh();
    }

    public function delete(string $id): bool
    {
        return (bool) User::destroy($id);
    }

    public function paginate(int $page = 1, int $perPage = 20): LengthAwarePaginator
    {
        return User::query()
            ->active()
            ->orderBy('created_at', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);
    }
}
```

### Resource
```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'status' => $this->status->value,
            'active' => $this->active,
            'created_at' => $this->created_at->toIso8601String(),
            'orders' => OrderResource::collection($this->whenLoaded('orders')),
        ];
    }
}
```

### Action Class
```php
<?php

declare(strict_types=1);

namespace App\Actions;

use App\DTO\CreateUserDto;
use App\Models\User;
use App\Notifications\WelcomeNotification;
use Illuminate\Support\Facades\DB;

final class CreateUserAction
{
    public function execute(CreateUserDto $dto): User
    {
        return DB::transaction(function () use ($dto) {
            $user = User::create([
                'name' => $dto->name,
                'email' => $dto->email,
            ]);

            $user->notify(new WelcomeNotification());

            return $user;
        });
    }
}
```

## Error Handling

```php
<?php

declare(strict_types=1);

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class UserNotFoundException extends Exception
{
    public function __construct(string $id)
    {
        parent::__construct("User with id {$id} not found");
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'error' => $this->getMessage(),
            'code' => 'USER_NOT_FOUND',
        ], 404);
    }
}

// In Handler
public function register(): void
{
    $this->renderable(function (UserNotFoundException $e, Request $request) {
        return response()->json([
            'error' => $e->getMessage(),
            'code' => 'USER_NOT_FOUND',
        ], 404);
    });

    $this->renderable(function (ValidationException $e, Request $request) {
        return response()->json([
            'error' => 'Validation failed',
            'code' => 'VALIDATION_ERROR',
            'details' => $e->errors(),
        ], 422);
    });
}
```

## Testing with PHPUnit/Pest

### PHPUnit
```php
<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_users(): void
    {
        User::factory()->count(3)->create();

        $response = $this->getJson('/api/users');

        $response->assertOk()
            ->assertJsonCount(3, 'data');
    }

    public function test_can_create_user(): void
    {
        $data = [
            'name' => 'Test User',
            'email' => 'test@example.com',
        ];

        $response = $this->postJson('/api/users', $data);

        $response->assertCreated()
            ->assertJson(['data' => ['name' => 'Test User']]);

        $this->assertDatabaseHas('users', $data);
    }

    public function test_create_user_validates_email(): void
    {
        $response = $this->postJson('/api/users', [
            'name' => 'Test',
            'email' => 'invalid-email',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }
}
```

### Pest
```php
<?php

use App\Models\User;

test('can list users', function () {
    User::factory()->count(3)->create();

    $this->getJson('/api/users')
        ->assertOk()
        ->assertJsonCount(3, 'data');
});

test('can create user', function () {
    $data = [
        'name' => 'Test User',
        'email' => 'test@example.com',
    ];

    $this->postJson('/api/users', $data)
        ->assertCreated()
        ->assertJson(['data' => ['name' => 'Test User']]);

    $this->assertDatabaseHas('users', $data);
});

test('create user validates email')
    ->postJson('/api/users', ['name' => 'Test', 'email' => 'invalid'])
    ->assertStatus(422)
    ->assertJsonValidationErrors(['email']);
```

## Project Structure

```
app/
├── Actions/
├── Contracts/
├── DTO/
├── Enums/
├── Events/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Notifications/
├── Repositories/
├── Services/
└── Traits/

tests/
├── Feature/
└── Unit/
```

## Formatters & Linters

- **PHP-CS-Fixer**: Code formatting
- **PHPStan**: Static analysis
- **Psalm**: Type checking
- **Pint**: Laravel style fixer

## Debug Statements to Remove

```php
// Remove before committing
var_dump()
print_r()
dd()
dump()
echo
die()
exit()
ray()
```
