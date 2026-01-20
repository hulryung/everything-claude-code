---
name: swift-patterns
description: Swift specific patterns, iOS/macOS development, and best practices.
---

# Swift Patterns

Language-specific patterns for Swift, iOS, macOS, and server-side Swift applications.

## Swift Fundamentals

### Struct vs Class
```swift
// Prefer structs for data models (value types, immutable by default)
struct User {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
    var isActive: Bool

    init(id: String = UUID().uuidString,
         name: String,
         email: String,
         createdAt: Date = Date(),
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

// Use classes for reference semantics, inheritance, or identity
final class UserManager {
    static let shared = UserManager()
    private init() {}

    private var users: [String: User] = [:]

    func getUser(id: String) -> User? {
        users[id]
    }
}
```

### Optionals
```swift
// Optional binding
func getUser(id: String) -> User? {
    return users[id]
}

// if let
if let user = getUser(id: "123") {
    print(user.name)
}

// guard let (early exit)
func processUser(id: String) {
    guard let user = getUser(id: id) else {
        print("User not found")
        return
    }
    // user is non-optional here
    process(user)
}

// Nil coalescing
let name = user?.name ?? "Unknown"

// Optional chaining
let uppercaseName = user?.name.uppercased()

// map and flatMap
let length = user.map { $0.name.count }
let nestedUser = getUser(id: "123").flatMap { getRelatedUser($0) }
```

### Enums with Associated Values
```swift
enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(statusCode: Int, message: String)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
```

### Protocols
```swift
protocol UserRepository {
    func findById(_ id: String) async throws -> User?
    func save(_ user: User) async throws
    func delete(_ id: String) async throws
}

protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

// Protocol extensions for default implementations
extension UserRepository {
    func findOrCreate(id: String, creator: () -> User) async throws -> User {
        if let existing = try await findById(id) {
            return existing
        }
        let newUser = creator()
        try await save(newUser)
        return newUser
    }
}
```

### Generics
```swift
struct APIResponse<T: Decodable> {
    let success: Bool
    let data: T?
    let error: String?
}

func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(T.self, from: data)
}

// Generic constraints
func process<T: Collection>(_ items: T) where T.Element: Equatable {
    // ...
}
```

## Async/Await (Swift 5.5+)

### Basic Async
```swift
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NetworkError.httpError(statusCode: 0, message: "Invalid response")
    }

    return try JSONDecoder().decode(User.self, from: data)
}

// Usage
Task {
    do {
        let user = try await fetchUser(id: "123")
        print(user.name)
    } catch {
        print("Error: \(error)")
    }
}
```

### Concurrent Execution
```swift
func fetchAllData() async throws -> (users: [User], products: [Product]) {
    async let users = fetchUsers()
    async let products = fetchProducts()

    return try await (users, products)
}

// TaskGroup for dynamic concurrency
func fetchUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }

        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

### Actors
```swift
actor UserCache {
    private var cache: [String: User] = [:]

    func get(_ id: String) -> User? {
        cache[id]
    }

    func set(_ user: User) {
        cache[user.id] = user
    }

    func clear() {
        cache.removeAll()
    }
}

// Usage
let cache = UserCache()
await cache.set(user)
let cachedUser = await cache.get("123")
```

## SwiftUI Patterns

### View Structure
```swift
struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .toolbar { toolbarContent }
                .task { await viewModel.loadUsers() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let users):
            userList(users)
        case .error(let error):
            errorView(error)
        }
    }

    private func userList(_ users: [User]) -> some View {
        List(users) { user in
            NavigationLink(value: user) {
                UserRowView(user: user)
            }
        }
        .navigationDestination(for: User.self) { user in
            UserDetailView(user: user)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add") {
                viewModel.showAddUser = true
            }
        }
    }
}
```

### ViewModel with ObservableObject
```swift
@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var state: LoadingState<[User]> = .idle
    @Published var showAddUser = false

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    func loadUsers() async {
        state = .loading
        do {
            let users = try await userService.fetchUsers()
            state = .loaded(users)
        } catch {
            state = .error(error)
        }
    }

    func deleteUser(_ user: User) async {
        do {
            try await userService.delete(user.id)
            await loadUsers()
        } catch {
            // Handle error
        }
    }
}
```

### Observable Macro (iOS 17+)
```swift
@Observable
final class UserListViewModel {
    private(set) var state: LoadingState<[User]> = .idle
    var showAddUser = false

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    @MainActor
    func loadUsers() async {
        state = .loading
        do {
            let users = try await userService.fetchUsers()
            state = .loaded(users)
        } catch {
            state = .error(error)
        }
    }
}
```

### Custom ViewModifier
```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage
Text("Hello")
    .cardStyle()
```

## Dependency Injection

```swift
// Protocol-based DI
protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User
}

final class UserService: UserServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = .shared) {
        self.networkClient = networkClient
    }

    func fetchUsers() async throws -> [User] {
        try await networkClient.fetch([User].self, from: "/users")
    }
}

// Environment-based DI for SwiftUI
private struct UserServiceKey: EnvironmentKey {
    static let defaultValue: UserServiceProtocol = UserService()
}

extension EnvironmentValues {
    var userService: UserServiceProtocol {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

// Usage
struct ContentView: View {
    @Environment(\.userService) private var userService

    var body: some View {
        // ...
    }
}
```

## Error Handling

```swift
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case notFound(resource: String)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process data"
        case .notFound(let resource):
            return "\(resource) not found"
        case .unauthorized:
            return "Please log in to continue"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}

// Result type usage
func fetchUser(id: String) async -> Result<User, AppError> {
    do {
        let user = try await api.getUser(id)
        return .success(user)
    } catch let error as DecodingError {
        return .failure(.decodingError(underlying: error))
    } catch {
        return .failure(.networkError(underlying: error))
    }
}

// Handling
let result = await fetchUser(id: "123")
switch result {
case .success(let user):
    display(user)
case .failure(let error):
    showError(error)
}
```

## Testing

### XCTest
```swift
final class UserServiceTests: XCTestCase {
    var sut: UserService!
    var mockNetworkClient: MockNetworkClient!

    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        sut = UserService(networkClient: mockNetworkClient)
    }

    override func tearDown() {
        sut = nil
        mockNetworkClient = nil
        super.tearDown()
    }

    func testFetchUsers_success() async throws {
        // Arrange
        let expectedUsers = [User(name: "Test", email: "test@example.com")]
        mockNetworkClient.mockResponse = expectedUsers

        // Act
        let users = try await sut.fetchUsers()

        // Assert
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "Test")
    }

    func testFetchUsers_networkError_throws() async {
        // Arrange
        mockNetworkClient.mockError = NetworkError.noData

        // Act & Assert
        do {
            _ = try await sut.fetchUsers()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

### Swift Testing (Xcode 16+)
```swift
import Testing

@Suite("UserService Tests")
struct UserServiceTests {
    let mockNetworkClient = MockNetworkClient()
    var sut: UserService

    init() {
        sut = UserService(networkClient: mockNetworkClient)
    }

    @Test("Fetch users returns expected users")
    func fetchUsersSuccess() async throws {
        mockNetworkClient.mockResponse = [User(name: "Test", email: "test@example.com")]

        let users = try await sut.fetchUsers()

        #expect(users.count == 1)
        #expect(users.first?.name == "Test")
    }

    @Test("Fetch users throws on network error")
    func fetchUsersNetworkError() async {
        mockNetworkClient.mockError = NetworkError.noData

        await #expect(throws: NetworkError.self) {
            try await sut.fetchUsers()
        }
    }
}
```

## Project Structure

```
MyApp/
├── App/
│   └── MyApp.swift
├── Features/
│   ├── Users/
│   │   ├── Views/
│   │   │   ├── UserListView.swift
│   │   │   └── UserDetailView.swift
│   │   ├── ViewModels/
│   │   │   └── UserListViewModel.swift
│   │   └── Models/
│   │       └── User.swift
│   └── Settings/
├── Core/
│   ├── Network/
│   │   ├── NetworkClient.swift
│   │   └── Endpoints.swift
│   ├── Services/
│   │   └── UserService.swift
│   └── Extensions/
└── Resources/

Tests/
├── UnitTests/
└── UITests/
```

## Formatters & Linters

- **swift-format**: Official formatter
- **SwiftLint**: Linting and style
- **Periphery**: Dead code detection

## Debug Statements to Remove

```swift
// Remove before committing
print()
debugPrint()
dump()
NSLog()
#if DEBUG print(...) #endif  // OK to keep
```
