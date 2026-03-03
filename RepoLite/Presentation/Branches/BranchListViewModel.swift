//
//  BranchListViewModel.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

@MainActor
public final class BranchListViewModel: ObservableObject {

    enum ViewState: Equatable {
        case idle, loading, loaded, loadingMore, empty
        case error(String)
    }

    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var branches: [Branch] = []
    @Published var searchText: String = ""

    let repository: Repository

    private var currentPage = 1
    private var hasNextPage = true
    private var isFetching = false
    private let fetchBranchesUseCase: FetchBranchesUseCase

    init(repository: Repository, fetchBranchesUseCase: FetchBranchesUseCase) {
        self.repository = repository
        self.fetchBranchesUseCase = fetchBranchesUseCase
    }

    var filteredBranches: [Branch] {
        searchText.isEmpty ? branches : branches.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    func onAppear() {
        guard branches.isEmpty else { return }
        Task { await load(page: 1, append: false) }
    }

    func refresh() async {
        currentPage = 1
        hasNextPage = true
        await load(page: 1, append: false)
    }

    func loadNextIfNeeded(current branch: Branch) {
        guard filteredBranches.last?.id == branch.id,
              hasNextPage, viewState != .loadingMore, searchText.isEmpty else { return }
        Task { await load(page: currentPage + 1, append: true) }
    }

    // MARK: - Private
    private func load(page: Int, append: Bool) async {
        guard !isFetching else { return }
        isFetching = true
        viewState = append ? .loadingMore : .loading

        let parts = repository.fullName.split(separator: "/").map(String.init)
        guard parts.count == 2 else {
            viewState = .error("Invalid repository name.")
            isFetching = false
            return
        }

        do {
            let result = try await fetchBranchesUseCase.execute(
                owner: parts[0],
                repo: parts[1],
                page: page,
                perPage: AppConfiguration.defaultPerPage
            )
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            branches = append ? branches + result.items : result.items
            viewState = branches.isEmpty ? .empty : .loaded
        } catch let error as NetworkError {
            viewState = .error(error.errorDescription ?? "Unknown error")
        } catch {
            viewState = .error(error.localizedDescription)
        }
        isFetching = false
    }
}
