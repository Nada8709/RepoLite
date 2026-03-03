//
//  BranchRepository.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

final class BranchRepository: BranchRepositoryProtocol {
    private let httpClient: HTTPClientProtocol
    private let keychainService: KeychainServiceProtocol

    init(httpClient: HTTPClientProtocol, keychainService: KeychainServiceProtocol) {
        self.httpClient = httpClient
        self.keychainService = keychainService
    }

    func fetchBranches(owner: String, repo: String, page: Int, perPage: Int) async throws -> Page<Branch> {
        let token = try keychainService.load(for: KeychainService.Keys.accessToken)
        let dtos: [BranchDTO] = try await httpClient.execute(
            GitHubEndpoint.branches(owner: owner, repo: repo, page: page, perPage: perPage),
            token: token
        )
        let branches = dtos.map { $0.toDomain() }
        return Page(items: branches, currentPage: page, hasNextPage: branches.count == perPage)
    }
}
