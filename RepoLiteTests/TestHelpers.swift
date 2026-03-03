//
//  TestHelpers.swift
//  RepoLiteTests
//

import Foundation
@testable import RepoLite

// MARK: - Entity Stubs

extension Repository {
    static func stub(
        id: Int = 1,
        name: String = "repo-\(Int.random(in: 1...999))",
        fullName: String? = nil,
        description: String? = "A test repository",
        isPrivate: Bool = false,
        starCount: Int = 42,
        language: String? = "Swift",
        updatedAt: Date = Date(),
        defaultBranch: String = "main"
    ) -> Repository {
        Repository(
            id: id,
            name: name,
            fullName: fullName ?? "testuser/\(name)",
            description: description,
            isPrivate: isPrivate,
            starCount: starCount,
            language: language,
            updatedAt: updatedAt,
            defaultBranch: defaultBranch,
            url: URL(string: "https://github.com/testuser/\(name)"),
            openIssuesCount: 3,
            forksCount: 5
        )
    }
}

extension Branch {
    static func stub(
        name: String = "main",
        isProtected: Bool = false,
        commitSHA: String = "abc1234def5678"
    ) -> Branch {
        Branch(name: name, isProtected: isProtected, commitSHA: commitSHA)
    }
}

extension User {
    static func stub(
        id: Int = 1,
        login: String = "testuser"
    ) -> User {
        User(
            id: id,
            login: login,
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/\(id)"),
            name: "Test User",
            publicRepos: 10
        )
    }
}

// MARK: - Mock RepoGateway

final class MockRepoGateway: RepoGatewayProtocol {
    var stubbedPage: Page<Repository>?
    var stubbedError: Error?
    var fetchCallCount = 0
    var lastFetchedPage: Int?

    func fetchRepositories(page: Int, perPage: Int) async throws -> Page<Repository> {
        fetchCallCount += 1
        lastFetchedPage = page
        if let error = stubbedError { throw error }
        return stubbedPage ?? Page(items: [], currentPage: page, hasNextPage: false)
    }
}

// MARK: - Mock BranchGateway

final class MockBranchGateway: BranchRepositoryProtocol {
    var stubbedPage: Page<Branch>?
    var stubbedError: Error?
    var fetchCallCount = 0
    var lastOwner: String?
    var lastRepo: String?

    func fetchBranches(owner: String, repo: String, page: Int, perPage: Int) async throws -> Page<Branch> {
        fetchCallCount += 1
        lastOwner = owner
        lastRepo = repo
        if let error = stubbedError { throw error }
        return stubbedPage ?? Page(items: [], currentPage: page, hasNextPage: false)
    }
}

// MARK: - Mock AuthGateway

final class MockAuthGateway: AuthRepositoryProtocol {
    var stubbedUser: User = .stub()
    var stubbedSignInError: Error?
    var stubbedSignOutError: Error?
    var stubbedIsAuthenticated: Bool = true
    var signInCallCount = 0
    var signOutCallCount = 0
    var lastCode: String?

    func signIn(code: String) async throws -> User {
        signInCallCount += 1
        lastCode = code
        if let error = stubbedSignInError { throw error }
        return stubbedUser
    }

    func signOut() throws {
        signOutCallCount += 1
        if let error = stubbedSignOutError { throw error }
    }

    func isAuthenticated() -> Bool {
        stubbedIsAuthenticated
    }
}

// MARK: - Mock KeychainService

final class MockKeychainService: KeychainServiceProtocol {
    var storage: [String: String] = [:]
    var stubbedLoadError: Error?
    var stubbedSaveError: Error?

    func save(_ value: String, for key: String) throws {
        if let error = stubbedSaveError { throw error }
        storage[key] = value
    }

    func load(for key: String) throws -> String {
        if let error = stubbedLoadError { throw error }
        guard let value = storage[key] else {
            throw KeychainService.KeychainError.itemNotFound
        }
        return value
    }

    func delete(for key: String) throws {
        storage.removeValue(forKey: key)
    }
}

// MARK: - Mock HTTPClient

final class MockHTTPClient: HTTPClientProtocol {
    var stubbedResult: Any?
    var stubbedError: Error?
    var executeCallCount = 0

    func execute<T: Decodable>(_ endpoint: APIEndpoint, token: String?) async throws -> T {
        executeCallCount += 1
        if let error = stubbedError { throw error }
        guard let result = stubbedResult as? T else {
            throw NetworkError.decodingFailure("Mock type mismatch: expected \(T.self)")
        }
        return result
    }
}

// MARK: - Mock RepositoryCache

final class MockRepositoryCache: RepositoryCacheProtocol {
    var storedItems: [Int: [Repository]] = [:]
    var invalidateCallCount = 0
    var shouldReturnCache = false

    func store(_ repos: [Repository], page: Int) {
        storedItems[page] = repos
    }

    func retrieve(page: Int) -> [Repository]? {
        shouldReturnCache ? storedItems[page] : nil
    }

    func invalidate() {
        invalidateCallCount += 1
        storedItems.removeAll()
    }
}
