//
//  RepoGatewayTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class RepoGatewayTests: XCTestCase {

    private var sut: RepoGateway!
    private var mockHTTPClient: MockHTTPClient!
    private var mockKeychain: MockKeychainService!
    private var mockCache: MockRepositoryCache!

    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        mockKeychain = MockKeychainService()
        mockCache = MockRepositoryCache()
        sut = RepoGateway(
            httpClient: mockHTTPClient,
            keychainService: mockKeychain,
            cache: mockCache
        )
    }

    override func tearDown() {
        sut = nil
        mockHTTPClient = nil
        mockKeychain = nil
        mockCache = nil
        super.tearDown()
    }

    // MARK: - Cache

    func test_fetchRepositories_returnsCachedData_whenCacheIsValid() async throws {
        // Given
        let cachedRepos = [Repository.stub(id: 1), Repository.stub(id: 2)]
        mockCache.storedItems[1] = cachedRepos
        mockCache.shouldReturnCache = true
        mockKeychain.storage[KeychainService.Keys.accessToken] = "token"

        // When
        let result = try await sut.fetchRepositories(page: 1, perPage: 30)

        // Then — cache hit, no HTTP call made
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(mockHTTPClient.executeCallCount, 0)
    }

    func test_fetchRepositories_callsHTTPClient_whenCacheMisses() async throws {
        // Given
        mockCache.shouldReturnCache = false
        mockKeychain.storage[KeychainService.Keys.accessToken] = "valid_token"
        mockHTTPClient.stubbedResult = [RepositoryDTO].stub()

        // When
        _ = try await sut.fetchRepositories(page: 1, perPage: 30)

        // Then
        XCTAssertEqual(mockHTTPClient.executeCallCount, 1)
    }

    func test_fetchRepositories_storesResultInCache_afterFetch() async throws {
        // Given
        mockCache.shouldReturnCache = false
        mockKeychain.storage[KeychainService.Keys.accessToken] = "valid_token"
        mockHTTPClient.stubbedResult = [RepositoryDTO].stub(count: 3)

        // When
        _ = try await sut.fetchRepositories(page: 1, perPage: 30)

        // Then
        XCTAssertNotNil(mockCache.storedItems[1])
        XCTAssertEqual(mockCache.storedItems[1]?.count, 3)
    }

    func test_fetchRepositories_throwsUnauthorized_whenNoToken() async {
        // Given — no token in keychain
        mockKeychain.stubbedLoadError = KeychainService.KeychainError.itemNotFound

        // When / Then
        do {
            _ = try await sut.fetchRepositories(page: 1, perPage: 30)
            XCTFail("Expected error when no token")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_fetchRepositories_hasNextPage_whenFullPageReturned() async throws {
        // Given
        mockCache.shouldReturnCache = false
        mockKeychain.storage[KeychainService.Keys.accessToken] = "token"
        mockHTTPClient.stubbedResult = [RepositoryDTO].stub(count: 30)

        // When
        let result = try await sut.fetchRepositories(page: 1, perPage: 30)

        // Then
        XCTAssertTrue(result.hasNextPage)
    }

    func test_fetchRepositories_noNextPage_whenPartialPageReturned() async throws {
        // Given
        mockCache.shouldReturnCache = false
        mockKeychain.storage[KeychainService.Keys.accessToken] = "token"
        mockHTTPClient.stubbedResult = [RepositoryDTO].stub(count: 15)

        // When
        let result = try await sut.fetchRepositories(page: 1, perPage: 30)

        // Then
        XCTAssertFalse(result.hasNextPage)
    }
}

// MARK: - RepositoryDTO stub helper

extension Array where Element == RepositoryDTO {
    static func stub(count: Int = 2) -> [RepositoryDTO] {
        let safeCount = Swift.max(1, count)
        return (1...safeCount).map { i in
            RepositoryDTO(
                id: i,
                name: "repo-\(i)",
                fullName: "user/repo-\(i)",
                description: nil,
                private: false,
                stargazersCount: i,
                language: "Swift",
                updatedAt: Date(),
                defaultBranch: "main",
                htmlUrl: "https://github.com/user/repo-\(i)",
                openIssuesCount: 0,
                forksCount: 0
            )
        }
    }
}
