//
//  RepoGatewayProtocol.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public protocol RepoGatewayProtocol: Sendable {
    func fetchRepositories(page: Int, perPage: Int) async throws -> Page<Repository>
}
