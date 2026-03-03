//
//  FetchBranchesUseCaseTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class FetchBranchesUseCaseTests: XCTestCase {

    private var sut: FetchBranchesUseCase!
    private var mockGateway: MockBranchGateway!

    override func setUp() {
        super.setUp()
        mockGateway = MockBranchGateway()
        sut = FetchBranchesUseCase(repository: mockGateway)
    }

    override func tearDown() {
        sut = nil
        mockGateway = nil
        super.tearDown()
    }

    // MARK: - Happy Path

    func test_execute_returnsBranchesFromGateway() async throws {
        // Given
        let branches = [
            Branch.stub(name: "main"),
            Branch.stub(name: "develop"),
            Branch.stub(name: "feature/login")
        ]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)

        // When
        let result = try await sut.execute(owner: "testuser", repo: "RepoLite", page: 1, perPage: 30)

        // Then
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.name), ["main", "develop", "feature/login"])
    }

    func test_execute_forwardsOwnerAndRepoToGateway() async throws {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When
        _ = try await sut.execute(owner: "Nada8709", repo: "RepoLite", page: 1, perPage: 30)

        // Then
        XCTAssertEqual(mockGateway.lastOwner, "Nada8709")
        XCTAssertEqual(mockGateway.lastRepo, "RepoLite")
    }

    func test_execute_returnsProtectedBranches() async throws {
        // Given
        let branches = [
            Branch.stub(name: "main", isProtected: true),
            Branch.stub(name: "develop", isProtected: false)
        ]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)

        // When
        let result = try await sut.execute(owner: "testuser", repo: "repo", page: 1, perPage: 30)

        // Then
        XCTAssertTrue(result.items.first?.isProtected == true)
        XCTAssertFalse(result.items.last?.isProtected == true)
    }

    func test_execute_usesDefaultPerPage_whenZeroProvided() async throws {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When — passing 0 triggers the fallback to AppConfiguration.defaultPerPage
        _ = try await sut.execute(owner: "user", repo: "repo", page: 1, perPage: 0)

        // Then — gateway was still called (perPage resolved internally)
        XCTAssertEqual(mockGateway.fetchCallCount, 1)
    }

    func test_execute_hasNextPage_whenFullPageReturned() async throws {
        // Given
        let branches = Array(repeating: Branch.stub(), count: 30)
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: true)

        // When
        let result = try await sut.execute(owner: "user", repo: "repo", page: 1, perPage: 30)

        // Then
        XCTAssertTrue(result.hasNextPage)
    }

    // MARK: - Error Handling

    func test_execute_throwsNotFound_forMissingRepo() async {
        // Given
        mockGateway.stubbedError = NetworkError.notFound

        // When / Then
        do {
            _ = try await sut.execute(owner: "user", repo: "nonexistent", page: 1, perPage: 30)
            XCTFail("Expected NetworkError.notFound")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_throwsUnauthorized_whenTokenExpired() async {
        // Given
        mockGateway.stubbedError = NetworkError.unauthorized

        // When / Then
        do {
            _ = try await sut.execute(owner: "user", repo: "repo", page: 1, perPage: 30)
            XCTFail("Expected NetworkError.unauthorized")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
