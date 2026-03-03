//
//  BranchListViewModelTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

@MainActor
final class BranchListViewModelTests: XCTestCase {

    private var sut: BranchListViewModel!
    private var mockGateway: MockBranchGateway!
    private let testRepository = Repository.stub(
        id: 1,
        name: "RepoLite",
        fullName: "Nada8709/RepoLite",
        defaultBranch: "main"
    )

    override func setUp() {
        super.setUp()
        mockGateway = MockBranchGateway()
        sut = BranchListViewModel(
            repository: testRepository,
            fetchBranchesUseCase: FetchBranchesUseCase(repository: mockGateway)
        )
    }

    override func tearDown() {
        sut = nil
        mockGateway = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.viewState, .idle)
        XCTAssertTrue(sut.branches.isEmpty)
        XCTAssertEqual(sut.searchText, "")
    }

    func test_repository_isSetCorrectly() {
        XCTAssertEqual(sut.repository.fullName, "Nada8709/RepoLite")
    }

    // MARK: - onAppear

    func test_onAppear_loadsBranches_successfully() async {
        // Given
        let branches = [
            Branch.stub(name: "main"),
            Branch.stub(name: "develop"),
            Branch.stub(name: "feature/auth")
        ]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.branches.count, 3)
    }

    func test_onAppear_setsEmptyState_whenNoBranches() async {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .empty)
    }

    func test_onAppear_setsErrorState_onFailure() async {
        // Given
        mockGateway.stubbedError = NetworkError.forbidden

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        if case .error(let message) = sut.viewState {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .error state, got \(sut.viewState)")
        }
    }

    func test_onAppear_doesNotRefetch_whenBranchesAlreadyLoaded() async {
        // Given
        mockGateway.stubbedPage = Page(items: [.stub()], currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)
        let firstCallCount = mockGateway.fetchCallCount

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(mockGateway.fetchCallCount, firstCallCount)
    }

    func test_onAppear_parsesOwnerAndRepoFromFullName() async {
        // Given
        mockGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(mockGateway.lastOwner, "Nada8709")
        XCTAssertEqual(mockGateway.lastRepo, "RepoLite")
    }

    // MARK: - Invalid fullName

    func test_onAppear_setsError_whenFullNameIsInvalid() async {
        // Given — repository with invalid fullName
        let invalidRepo = Repository.stub(id: 99, name: "bad", fullName: "invalid-no-slash")
        sut = BranchListViewModel(
            repository: invalidRepo,
            fetchBranchesUseCase: FetchBranchesUseCase(repository: mockGateway)
        )

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        if case .error = sut.viewState { /* pass */ } else {
            XCTFail("Expected .error for invalid fullName")
        }
        XCTAssertEqual(mockGateway.fetchCallCount, 0)
    }

    // MARK: - Search / Filter

    func test_filteredBranches_returnsAll_whenSearchEmpty() async {
        // Given
        let branches = [Branch.stub(name: "main"), Branch.stub(name: "develop")]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = ""

        // Then
        XCTAssertEqual(sut.filteredBranches.count, 2)
    }

    func test_filteredBranches_filtersByName() async {
        // Given
        let branches = [
            Branch.stub(name: "main"),
            Branch.stub(name: "develop"),
            Branch.stub(name: "feature/main-refactor")
        ]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "main"

        // Then
        XCTAssertEqual(sut.filteredBranches.count, 2)
    }

    func test_filteredBranches_isCaseInsensitive() async {
        // Given
        let branches = [Branch.stub(name: "Main"), Branch.stub(name: "develop")]
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "main"

        // Then
        XCTAssertEqual(sut.filteredBranches.count, 1)
        XCTAssertEqual(sut.filteredBranches.first?.name, "Main")
    }

    // MARK: - Refresh

    func test_refresh_reloadsFromFirstPage() async {
        // Given — initial load
        mockGateway.stubbedPage = Page(items: [.stub(name: "main")], currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When — refresh with new data
        mockGateway.stubbedPage = Page(
            items: [.stub(name: "main"), .stub(name: "develop")],
            currentPage: 1,
            hasNextPage: false
        )
        await sut.refresh()

        // Then
        XCTAssertEqual(sut.branches.count, 2)
    }

    // MARK: - Pagination

    func test_loadNextIfNeeded_appendsBranches() async {
        // Given — first page
        let firstPage = Array((1...30).map { Branch.stub(name: "branch-\($0)") })
        mockGateway.stubbedPage = Page(items: firstPage, currentPage: 1, hasNextPage: true)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Prepare second page
        let secondPage = Array((31...60).map { Branch.stub(name: "branch-\($0)") })
        mockGateway.stubbedPage = Page(items: secondPage, currentPage: 2, hasNextPage: false)

        // When — trigger load more
        guard let lastBranch = sut.filteredBranches.last else {
            XCTFail("No branches loaded")
            return
        }
        sut.loadNextIfNeeded(current: lastBranch)
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(sut.branches.count, 60)
    }

    func test_loadNextIfNeeded_notTriggered_whenSearchIsActive() async {
        // Given
        let branches = Array((1...30).map { Branch.stub(name: "branch-\($0)") })
        mockGateway.stubbedPage = Page(items: branches, currentPage: 1, hasNextPage: true)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When — search is active
        sut.searchText = "main"
        let callCountBefore = mockGateway.fetchCallCount
        if let last = sut.filteredBranches.last {
            sut.loadNextIfNeeded(current: last)
        }
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(mockGateway.fetchCallCount, callCountBefore)
    }
}
