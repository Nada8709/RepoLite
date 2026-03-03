//
//  FetchRepositoriesUseCase.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public struct FetchRepositoriesUseCase: Sendable {
    private let repository: RepoGatewayProtocol

    public init(repository: RepoGatewayProtocol) {
        self.repository = repository
    }

    // Fetches a page of repositories.
    public func execute(page: Int, perPage: Int) async throws -> Page<Repository> {
        try await repository.fetchRepositories(page: page, perPage: perPage)
    }
}
