//
//  FetchRepositoriesUseCaseTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class FetchRepositoriesUseCaseTests: XCTestCase {

    private var sut: FetchRepositoriesUseCase!
    private var mockGateway: MockRepoGateway!

    override func setUp() {
        super.setUp()
        mockGateway = MockRepoGateway()
        sut = FetchRepositoriesUseCase(repository: mockGateway)
    }

    override func tearDown() {
        sut = nil
        mockGateway = nil
        super.tearDown()
    }

    // MARK: - Happy Path

    func test_execute_returnsRepositoriesFromGateway() async throws {
        // Given
        let repos = [Repository.stub(id: 1), Repository.stub(id: 2), Repository.stub(id: 3)]
        mockGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)

        // When
        let result = try await sut.execute(page: 1, perPage: 30)

        // Then
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.id), [1, 2, 3])
    }

    func test_execute_returnsCorrectPageMetadata() async throws {
        // Given
        let repos = Array(repeating: Repository.stub(), count: 30)
        mockGateway.stubbedPage = Page(items: repos, currentPage: 2, hasNextPage: true)

        // When
        let result = try await sut.execute(page: 2, perPage: 30)

        // Then
        XCTAssertEqual(result.currentPage, 2)
        XCTAssertTrue(result.hasNextPage)
    }

    func test_execute_returnsEmptyPage_whenNoRepositories() async throws {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When
        let result = try await sut.execute(page: 1, perPage: 30)

        // Then
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.hasNextPage)
    }

    func test_execute_forwardsPageParameterToGateway() async throws {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 3, hasNextPage: false)

        // When
        _ = try await sut.execute(page: 3, perPage: 30)

        // Then
        XCTAssertEqual(mockGateway.lastFetchedPage, 3)
        XCTAssertEqual(mockGateway.fetchCallCount, 1)
    }

    // MARK: - Error Handling

    func test_execute_throwsUnauthorized_whenGatewayThrows() async {
        // Given
        mockGateway.stubbedError = NetworkError.unauthorized

        // When / Then
        do {
            _ = try await sut.execute(page: 1, perPage: 30)
            XCTFail("Expected NetworkError.unauthorized to be thrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_throwsNoInternet_whenOffline() async {
        // Given
        mockGateway.stubbedError = NetworkError.noInternetConnection

        // When / Then
        do {
            _ = try await sut.execute(page: 1, perPage: 30)
            XCTFail("Expected NetworkError.noInternetConnection")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .noInternetConnection)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_throwsRateLimited_withRetryAfter() async {
        // Given
        mockGateway.stubbedError = NetworkError.rateLimited(retryAfter: 60)

        // When / Then
        do {
            _ = try await sut.execute(page: 1, perPage: 30)
            XCTFail("Expected NetworkError.rateLimited")
        } catch let error as NetworkError {
            if case .rateLimited(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 60)
            } else {
                XCTFail("Expected rateLimited error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
