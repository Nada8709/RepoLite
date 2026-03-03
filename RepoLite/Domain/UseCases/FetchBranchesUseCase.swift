//
//  FetchBranchesUseCase.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public struct FetchBranchesUseCase: Sendable {
    private let repository: BranchRepositoryProtocol

    public init(repository: BranchRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(owner: String, repo: String, page: Int, perPage: Int) async throws -> Page<Branch> {
        let resolvedPerPage = perPage == 0 ? AppConfiguration.defaultPerPage : perPage
        return try await repository.fetchBranches(owner: owner, repo: repo, page: page, perPage: resolvedPerPage)
    }
}
