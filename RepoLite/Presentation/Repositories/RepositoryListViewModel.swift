//
//  RepositoryListViewModel.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation
import Combine

@MainActor
public final class RepositoryListViewModel: ObservableObject {

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case loadingMore
        case error(String)
        case empty
    }

    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var repositories: [Repository] = []
    @Published private(set) var filteredRepositories: [Repository] = []
    @Published var searchText: String = ""
    @Published private(set) var isSigningOut = false

    // MARK: - Pagination

    private var currentPage = 1
    private var hasNextPage = true
    private var isFetching = false

    private let fetchRepositoriesUseCase: FetchRepositoriesUseCase
    private let signOutUseCase: SignOutUseCase
    private let onSignedOut: () -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchRepositoriesUseCase: FetchRepositoriesUseCase,
        signOutUseCase: SignOutUseCase,
        onSignedOut: @escaping () -> Void
    ) {
        self.fetchRepositoriesUseCase = fetchRepositoriesUseCase
        self.signOutUseCase = signOutUseCase
        self.onSignedOut = onSignedOut
        bindSearch()
    }

    func onAppear() {
        guard repositories.isEmpty else { return }
        Task { await loadFirstPage() }
    }

    func refresh() async {
        await loadFirstPage()
    }

    func loadNextPageIfNeeded(current repo: Repository) {
        guard filteredRepositories.last?.id == repo.id,
              hasNextPage,
              viewState != .loadingMore,
              searchText.isEmpty
        else { return }
        Task { await loadNextPage() }
    }

    func signOut() {
        isSigningOut = true
        do {
            try signOutUseCase.execute()
            onSignedOut()
        } catch {
            isSigningOut = false
        }
    }

    // MARK: - Private
    private func loadFirstPage() async {
        guard !isFetching else { return }
        currentPage = 1
        hasNextPage = true
        isFetching = true
        viewState = .loading
        await fetch(page: 1, append: false)
        isFetching = false
    }

    private func loadNextPage() async {
        guard !isFetching, hasNextPage else { return }
        isFetching = true
        viewState = .loadingMore
        await fetch(page: currentPage + 1, append: true)
        isFetching = false
    }

    private func fetch(page: Int, append: Bool) async {
        do {
            let result = try await fetchRepositoriesUseCase
                .execute(page: page,
                         perPage: AppConfiguration.defaultPerPage)
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            if append {
                repositories += result.items
            } else {
                repositories = result.items
            }
            viewState = repositories.isEmpty ? .empty : .loaded
        } catch let error as NetworkError {
            viewState = .error(error.errorDescription ?? "Unknown error")
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    private func bindSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .combineLatest($repositories)
            .map { query, repos in
                query.isEmpty ? repos : repos.filter {
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    ($0.description?.localizedCaseInsensitiveContains(query) == true)
                }
            }
            .assign(to: &$filteredRepositories)
    }
}
