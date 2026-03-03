//
//  AuthRepositoryProtocol.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public protocol AuthRepositoryProtocol: Sendable {
    func signIn(code: String) async throws -> User
    func signOut() throws
    func isAuthenticated() -> Bool
}
