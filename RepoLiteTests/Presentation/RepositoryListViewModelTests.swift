//
//  RepositoryListViewModelTests.swift
//  RepoLiteTests
//

import XCTest
import Combine
@testable import RepoLite

@MainActor
final class RepositoryListViewModelTests: XCTestCase {

    private var sut: RepositoryListViewModel!
    private var mockRepoGateway: MockRepoGateway!
    private var mockAuthGateway: MockAuthGateway!
    private var signedOutCalled = false
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockRepoGateway = MockRepoGateway()
        mockAuthGateway = MockAuthGateway()
        signedOutCalled = false
        sut = makeSUT()
    }

    override func tearDown() {
        sut = nil
        mockRepoGateway = nil
        mockAuthGateway = nil
        cancellables.removeAll()
        super.tearDown()
    }

    private func makeSUT() -> RepositoryListViewModel {
        RepositoryListViewModel(
            fetchRepositoriesUseCase: FetchRepositoriesUseCase(repository: mockRepoGateway),
            signOutUseCase: SignOutUseCase(repository: mockAuthGateway),
            onSignedOut: { [weak self] in self?.signedOutCalled = true }
        )
    }

    // MARK: - Initial State

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.viewState, .idle)
        XCTAssertTrue(sut.repositories.isEmpty)
        XCTAssertTrue(sut.filteredRepositories.isEmpty)
        XCTAssertEqual(sut.searchText, "")
    }

    // MARK: - onAppear

    func test_onAppear_setsLoadingState_thenLoaded() async {
        // Given
        let repos = [Repository.stub(id: 1), Repository.stub(id: 2)]
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.repositories.count, 2)
    }

    func test_onAppear_setsEmptyState_whenNoRepositories() async {
        // Given
        mockRepoGateway.stubbedPage = Page(items: [], currentPage: 1, hasNextPage: false)

        // When
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .empty)
        XCTAssertTrue(sut.repositories.isEmpty)
    }

    func test_onAppear_setsErrorState_onNetworkFailure() async {
        // Given
        mockRepoGateway.stubbedError = NetworkError.noInternetConnection

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

    func test_onAppear_doesNotRefetch_whenRepositoriesAlreadyLoaded() async {
        // Given — load first
        mockRepoGateway.stubbedPage = Page(items: [.stub()], currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        let firstCallCount = mockRepoGateway.fetchCallCount

        // When — call onAppear again
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then
        XCTAssertEqual(mockRepoGateway.fetchCallCount, firstCallCount)
    }

    // MARK: - Refresh

    func test_refresh_reloadsFromFirstPage() async {
        // Given — initial load
        mockRepoGateway.stubbedPage = Page(items: [.stub()], currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When — refresh with new data
        let newRepos = [Repository.stub(id: 10), Repository.stub(id: 11)]
        mockRepoGateway.stubbedPage = Page(items: newRepos, currentPage: 1, hasNextPage: false)
        await sut.refresh()

        // Then
        XCTAssertEqual(sut.repositories.count, 2)
        XCTAssertEqual(sut.repositories.map(\.id), [10, 11])
    }

    func test_refresh_invalidatesAndReloadsFromPageOne() async {
        // Given
        mockRepoGateway.stubbedPage = Page(items: [.stub()], currentPage: 1, hasNextPage: false)

        // When
        await sut.refresh()

        // Then
        XCTAssertEqual(mockRepoGateway.lastFetchedPage, 1)
    }

    // MARK: - Search / Filter

    func test_searchText_filtersRepositoriesByName() async {
        // Given
        let repos = [
            Repository.stub(id: 1, name: "ios-app"),
            Repository.stub(id: 2, name: "android-app"),
            Repository.stub(id: 3, name: "ios-toolkit")
        ]
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "ios"
        try? await Task.sleep(nanoseconds: 400_000_000) // Wait for debounce

        // Then
        XCTAssertEqual(sut.filteredRepositories.count, 2)
        XCTAssertTrue(sut.filteredRepositories.allSatisfy { $0.name.contains("ios") })
    }

    func test_searchText_isCaseInsensitive() async {
        // Given
        let repos = [
            Repository.stub(id: 1, name: "RepoLite"),
            Repository.stub(id: 2, name: "other-repo")
        ]
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "repolite"
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertEqual(sut.filteredRepositories.count, 1)
        XCTAssertEqual(sut.filteredRepositories.first?.name, "RepoLite")
    }

    func test_searchText_empty_showsAllRepositories() async {
        // Given
        let repos = [Repository.stub(id: 1), Repository.stub(id: 2)]
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "xyz"
        try? await Task.sleep(nanoseconds: 400_000_000)
        sut.searchText = ""
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertEqual(sut.filteredRepositories.count, 2)
    }

    func test_searchText_filtersRepositoriesByDescription() async {
        // Given
        let repos = [
            Repository.stub(id: 1, name: "repo1", description: "An awesome Swift library"),
            Repository.stub(id: 2, name: "repo2", description: "A Python utility")
        ]
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: false)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When
        sut.searchText = "Swift"
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertEqual(sut.filteredRepositories.count, 1)
        XCTAssertEqual(sut.filteredRepositories.first?.id, 1)
    }

    // MARK: - Pagination

    func test_loadNextPage_isTriggered_whenLastItemAppears() async {
        // Given — first page with next page available
        let firstPageRepos = Array((1...30).map { Repository.stub(id: $0) })
        mockRepoGateway.stubbedPage = Page(items: firstPageRepos, currentPage: 1, hasNextPage: true)
        
        await sut.refresh()
        try? await Task.sleep(nanoseconds: 500_000_000) // wait for Combine to propagate

        // Verify repos loaded before continuing
        guard !sut.repositories.isEmpty else {
            XCTFail("Repositories should be loaded after refresh")
            return
        }

        // Prepare second page
        let secondPageRepos = Array((31...60).map { Repository.stub(id: $0) })
        mockRepoGateway.stubbedPage = Page(items: secondPageRepos, currentPage: 2, hasNextPage: false)

        // When — use repositories directly (not filteredRepositories which needs debounce)
        guard let lastRepo = sut.repositories.last else {
            XCTFail("No repositories loaded")
            return
        }
        sut.loadNextPageIfNeeded(current: lastRepo)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(sut.repositories.count, 60)
        XCTAssertEqual(mockRepoGateway.fetchCallCount, 2)
    }

    func test_loadNextPage_notTriggered_whenSearchActive() async {
        // Given
        let repos = Array((1...30).map { Repository.stub(id: $0) })
        mockRepoGateway.stubbedPage = Page(items: repos, currentPage: 1, hasNextPage: true)
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // When — search is active
        sut.searchText = "something"
        try? await Task.sleep(nanoseconds: 400_000_000)

        let firstCallCount = mockRepoGateway.fetchCallCount
        if let lastRepo = sut.filteredRepositories.last {
            sut.loadNextPageIfNeeded(current: lastRepo)
        }
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then — no additional fetch
        XCTAssertEqual(mockRepoGateway.fetchCallCount, firstCallCount)
    }

    // MARK: - Sign Out

    func test_signOut_callsOnSignedOutCallback() {
        // When
        sut.signOut()

        // Then
        XCTAssertTrue(signedOutCalled)
        XCTAssertEqual(mockAuthGateway.signOutCallCount, 1)
    }

    func test_signOut_doesNotCallOnSignedOut_whenGatewayFails() {
        // Given
        mockAuthGateway.stubbedSignOutError = KeychainService.KeychainError.itemNotFound

        // When
        sut.signOut()

        // Then
        XCTAssertFalse(signedOutCalled)
    }
}
