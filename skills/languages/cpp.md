---
name: cpp-patterns
description: C and C++ specific patterns, modern C++ idioms, and best practices.
---

# C/C++ Patterns

Language-specific patterns for C and modern C++ (C++17/20/23).

## Modern C++ Fundamentals

### Class Definition
```cpp
#include <string>
#include <chrono>
#include <optional>

class User {
public:
    // Constructor with member initializer list
    User(std::string name, std::string email)
        : id_{generate_uuid()}
        , name_{std::move(name)}
        , email_{std::move(email)}
        , created_at_{std::chrono::system_clock::now()}
        , active_{true}
    {}

    // Getters (const correctness)
    [[nodiscard]] const std::string& id() const noexcept { return id_; }
    [[nodiscard]] const std::string& name() const noexcept { return name_; }
    [[nodiscard]] const std::string& email() const noexcept { return email_; }
    [[nodiscard]] bool is_active() const noexcept { return active_; }

    // Setters
    void set_name(std::string name) { name_ = std::move(name); }
    void deactivate() noexcept { active_ = false; }

    // Rule of five (or use = default)
    User(const User&) = default;
    User(User&&) noexcept = default;
    User& operator=(const User&) = default;
    User& operator=(User&&) noexcept = default;
    ~User() = default;

private:
    std::string id_;
    std::string name_;
    std::string email_;
    std::chrono::system_clock::time_point created_at_;
    bool active_;

    static std::string generate_uuid();
};
```

### Struct for Data
```cpp
// Use structs for plain data (all public)
struct UserDTO {
    std::string id;
    std::string name;
    std::string email;
    bool active = true;

    // C++20: Defaulted comparison
    auto operator<=>(const UserDTO&) const = default;
};

// Aggregate initialization
UserDTO user{.id = "123", .name = "John", .email = "john@example.com"};
```

### Smart Pointers
```cpp
#include <memory>

// unique_ptr - single ownership (preferred)
auto user = std::make_unique<User>("John", "john@example.com");

// shared_ptr - shared ownership (when needed)
auto shared_user = std::make_shared<User>("Jane", "jane@example.com");

// weak_ptr - non-owning reference to shared_ptr
std::weak_ptr<User> weak_user = shared_user;

// Pass by reference, not by pointer
void process_user(const User& user);  // GOOD
void process_user(User* user);        // Avoid unless nullable

// Factory function returning unique_ptr
[[nodiscard]] std::unique_ptr<User> create_user(
    const std::string& name,
    const std::string& email)
{
    return std::make_unique<User>(name, email);
}
```

### Optional
```cpp
#include <optional>

std::optional<User> find_user(const std::string& id) {
    auto it = users_.find(id);
    if (it == users_.end()) {
        return std::nullopt;
    }
    return it->second;
}

// Usage
if (auto user = find_user("123"); user) {
    std::cout << user->name() << "\n";
}

// Or with value_or
auto name = find_user("123")
    .transform([](const User& u) { return u.name(); })
    .value_or("Unknown");
```

### Error Handling with Expected (C++23)
```cpp
#include <expected>

enum class Error {
    NotFound,
    InvalidInput,
    NetworkError
};

std::expected<User, Error> get_user(const std::string& id) {
    if (id.empty()) {
        return std::unexpected(Error::InvalidInput);
    }

    auto user = find_user(id);
    if (!user) {
        return std::unexpected(Error::NotFound);
    }

    return *user;
}

// Usage
auto result = get_user("123");
if (result) {
    std::cout << result->name() << "\n";
} else {
    switch (result.error()) {
        case Error::NotFound:
            std::cerr << "User not found\n";
            break;
        case Error::InvalidInput:
            std::cerr << "Invalid input\n";
            break;
        default:
            std::cerr << "Unknown error\n";
    }
}
```

### Variants
```cpp
#include <variant>

using Result = std::variant<User, Error>;

Result get_user_variant(const std::string& id) {
    if (auto user = find_user(id)) {
        return *user;
    }
    return Error::NotFound;
}

// Pattern matching with std::visit
std::visit([](auto&& arg) {
    using T = std::decay_t<decltype(arg)>;
    if constexpr (std::is_same_v<T, User>) {
        std::cout << "User: " << arg.name() << "\n";
    } else if constexpr (std::is_same_v<T, Error>) {
        std::cout << "Error occurred\n";
    }
}, result);
```

## Templates

### Function Templates
```cpp
template<typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}

// With concepts (C++20)
template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template<Numeric T>
T safe_divide(T a, T b) {
    if (b == T{0}) {
        throw std::invalid_argument("Division by zero");
    }
    return a / b;
}

// Variadic templates
template<typename... Args>
void log(Args&&... args) {
    (std::cout << ... << args) << "\n";
}
```

### Class Templates
```cpp
template<typename T>
class Repository {
public:
    virtual ~Repository() = default;

    virtual std::optional<T> find_by_id(const std::string& id) = 0;
    virtual void save(const T& entity) = 0;
    virtual void remove(const std::string& id) = 0;
    virtual std::vector<T> find_all() = 0;
};

template<typename T>
class InMemoryRepository : public Repository<T> {
public:
    std::optional<T> find_by_id(const std::string& id) override {
        auto it = data_.find(id);
        if (it == data_.end()) return std::nullopt;
        return it->second;
    }

    void save(const T& entity) override {
        data_[entity.id()] = entity;
    }

private:
    std::unordered_map<std::string, T> data_;
};
```

## STL Algorithms

### Range-based Operations (C++20)
```cpp
#include <ranges>
#include <algorithm>

std::vector<User> users = get_users();

// Filter and transform
auto active_names = users
    | std::views::filter([](const User& u) { return u.is_active(); })
    | std::views::transform([](const User& u) { return u.name(); });

// Sort
std::ranges::sort(users, {}, &User::name);

// Find
auto it = std::ranges::find_if(users,
    [](const User& u) { return u.email().ends_with("@example.com"); });

// Collect to vector (C++23)
auto names = users
    | std::views::transform(&User::name)
    | std::ranges::to<std::vector>();
```

### Classic STL
```cpp
// Transform
std::vector<std::string> names;
std::transform(users.begin(), users.end(), std::back_inserter(names),
    [](const User& u) { return u.name(); });

// Filter (remove_if + erase)
users.erase(
    std::remove_if(users.begin(), users.end(),
        [](const User& u) { return !u.is_active(); }),
    users.end());

// Sort
std::sort(users.begin(), users.end(),
    [](const User& a, const User& b) { return a.name() < b.name(); });
```

## Concurrency

### Threads and Futures
```cpp
#include <thread>
#include <future>
#include <mutex>

// Async task
std::future<User> fetch_user_async(const std::string& id) {
    return std::async(std::launch::async, [id]() {
        // Simulated network call
        return User{/*...*/};
    });
}

// Usage
auto future = fetch_user_async("123");
// Do other work...
User user = future.get();  // Blocks until ready

// Multiple async tasks
std::vector<std::future<User>> futures;
for (const auto& id : user_ids) {
    futures.push_back(fetch_user_async(id));
}

std::vector<User> users;
for (auto& f : futures) {
    users.push_back(f.get());
}
```

### Mutex and Locks
```cpp
class ThreadSafeCache {
public:
    std::optional<User> get(const std::string& id) {
        std::shared_lock lock(mutex_);  // Read lock
        auto it = cache_.find(id);
        if (it == cache_.end()) return std::nullopt;
        return it->second;
    }

    void set(const User& user) {
        std::unique_lock lock(mutex_);  // Write lock
        cache_[user.id()] = user;
    }

private:
    std::unordered_map<std::string, User> cache_;
    mutable std::shared_mutex mutex_;
};
```

### Coroutines (C++20)
```cpp
#include <coroutine>

// Generator pattern
template<typename T>
struct Generator {
    struct promise_type {
        T current_value;

        Generator get_return_object() {
            return Generator{std::coroutine_handle<promise_type>::from_promise(*this)};
        }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() noexcept { return {}; }
        std::suspend_always yield_value(T value) {
            current_value = std::move(value);
            return {};
        }
        void return_void() {}
        void unhandled_exception() { std::terminate(); }
    };

    std::coroutine_handle<promise_type> handle;

    bool next() {
        if (!handle.done()) {
            handle.resume();
            return !handle.done();
        }
        return false;
    }

    T value() { return handle.promise().current_value; }
};

Generator<int> range(int start, int end) {
    for (int i = start; i < end; ++i) {
        co_yield i;
    }
}
```

## RAII Pattern

```cpp
// File handle wrapper
class FileHandle {
public:
    explicit FileHandle(const std::string& path)
        : file_(std::fopen(path.c_str(), "r"))
    {
        if (!file_) {
            throw std::runtime_error("Failed to open file");
        }
    }

    ~FileHandle() {
        if (file_) {
            std::fclose(file_);
        }
    }

    // Non-copyable, movable
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
    FileHandle(FileHandle&& other) noexcept : file_(other.file_) {
        other.file_ = nullptr;
    }
    FileHandle& operator=(FileHandle&& other) noexcept {
        if (this != &other) {
            if (file_) std::fclose(file_);
            file_ = other.file_;
            other.file_ = nullptr;
        }
        return *this;
    }

    FILE* get() { return file_; }

private:
    FILE* file_;
};

// Lock guard pattern (standard library)
std::mutex mtx;
{
    std::lock_guard<std::mutex> lock(mtx);
    // Protected code
}  // Automatically unlocks
```

## Testing with GoogleTest

```cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>

// Mock class
class MockUserRepository : public UserRepository {
public:
    MOCK_METHOD(std::optional<User>, find_by_id, (const std::string&), (override));
    MOCK_METHOD(void, save, (const User&), (override));
};

// Test fixture
class UserServiceTest : public ::testing::Test {
protected:
    void SetUp() override {
        mock_repo_ = std::make_unique<MockUserRepository>();
        service_ = std::make_unique<UserService>(mock_repo_.get());
    }

    std::unique_ptr<MockUserRepository> mock_repo_;
    std::unique_ptr<UserService> service_;
};

TEST_F(UserServiceTest, FindUser_ExistingUser_ReturnsUser) {
    // Arrange
    User expected{"John", "john@example.com"};
    EXPECT_CALL(*mock_repo_, find_by_id("123"))
        .WillOnce(::testing::Return(expected));

    // Act
    auto result = service_->get_user("123");

    // Assert
    ASSERT_TRUE(result.has_value());
    EXPECT_EQ(result->name(), "John");
}

TEST_F(UserServiceTest, FindUser_NonExistingUser_ReturnsEmpty) {
    // Arrange
    EXPECT_CALL(*mock_repo_, find_by_id("999"))
        .WillOnce(::testing::Return(std::nullopt));

    // Act
    auto result = service_->get_user("999");

    // Assert
    EXPECT_FALSE(result.has_value());
}
```

## Project Structure

```
project/
├── CMakeLists.txt
├── include/
│   └── project/
│       ├── user.hpp
│       ├── user_repository.hpp
│       └── user_service.hpp
├── src/
│   ├── user.cpp
│   ├── user_repository.cpp
│   └── user_service.cpp
├── tests/
│   ├── CMakeLists.txt
│   ├── user_test.cpp
│   └── user_service_test.cpp
└── examples/
    └── main.cpp
```

## CMake Example

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Library
add_library(mylib
    src/user.cpp
    src/user_service.cpp
)
target_include_directories(mylib PUBLIC include)

# Executable
add_executable(myapp examples/main.cpp)
target_link_libraries(myapp PRIVATE mylib)

# Tests
enable_testing()
find_package(GTest REQUIRED)
add_executable(tests
    tests/user_test.cpp
    tests/user_service_test.cpp
)
target_link_libraries(tests PRIVATE mylib GTest::gtest_main GTest::gmock)
add_test(NAME unit_tests COMMAND tests)
```

## Formatters & Linters

- **clang-format**: Code formatting
- **clang-tidy**: Static analysis
- **cppcheck**: Bug detection
- **include-what-you-use**: Header optimization

## Debug Statements to Remove

```cpp
// Remove before committing
std::cout <<
std::cerr <<
printf()
fprintf(stderr, ...)
std::clog <<
assert()  // Keep in debug builds, but review
```

## C-Specific Patterns

### Safe String Handling
```c
#include <string.h>
#include <stdio.h>

// Use snprintf instead of sprintf
char buffer[256];
snprintf(buffer, sizeof(buffer), "User: %s", username);

// Use strncpy with null termination
char dest[64];
strncpy(dest, src, sizeof(dest) - 1);
dest[sizeof(dest) - 1] = '\0';
```

### Error Handling in C
```c
typedef enum {
    SUCCESS = 0,
    ERR_NULL_POINTER,
    ERR_OUT_OF_MEMORY,
    ERR_INVALID_INPUT
} ErrorCode;

ErrorCode create_user(const char* name, User** out_user) {
    if (!name || !out_user) {
        return ERR_NULL_POINTER;
    }

    *out_user = malloc(sizeof(User));
    if (!*out_user) {
        return ERR_OUT_OF_MEMORY;
    }

    // Initialize...
    return SUCCESS;
}

// Usage
User* user = NULL;
ErrorCode err = create_user("John", &user);
if (err != SUCCESS) {
    // Handle error
}
// Don't forget to free(user) when done
```
