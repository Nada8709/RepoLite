//
//  RepoGateway.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

final class RepoGateway: RepoGatewayProtocol {
    private let httpClient: HTTPClientProtocol
    private let keychainService: KeychainServiceProtocol
    private let cache: RepositoryCacheProtocol

    init(
        httpClient: HTTPClientProtocol,
        keychainService: KeychainServiceProtocol,
        cache: RepositoryCacheProtocol
    ) {
        self.httpClient = httpClient
        self.keychainService = keychainService
        self.cache = cache
    }

    func fetchRepositories(page: Int, perPage: Int) async throws -> Page<Repository> {
        // Cache hit
        if let cached = cache.retrieve(page: page) {
            return Page(items: cached, currentPage: page, hasNextPage: cached.count == perPage)
        }

        let token = try keychainService.load(for: KeychainService.Keys.accessToken)
        let dtos: [RepositoryDTO] = try await httpClient.execute(
            GitHubEndpoint.userRepositories(page: page, perPage: perPage),
            token: token
        )
        let repos = dtos.map { $0.toDomain() }
        cache.store(repos, page: page)

        return Page(items: repos, currentPage: page, hasNextPage: repos.count == perPage)
    }
}
