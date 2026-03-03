//
//  BranchRepositoryProtocol.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public protocol BranchRepositoryProtocol: Sendable {
    func fetchBranches(owner: String, repo: String, page: Int, perPage: Int) async throws -> Page<Branch>
}
