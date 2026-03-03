//
//  AuthRepository.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

final class AuthRepository: AuthRepositoryProtocol {
    private let httpClient: HTTPClientProtocol
    private let keychainService: KeychainServiceProtocol

    init(httpClient: HTTPClientProtocol, keychainService: KeychainServiceProtocol) {
        self.httpClient = httpClient
        self.keychainService = keychainService
    }

    func signIn(code: String) async throws -> User {
        // 1. Exchange code for token
        let tokenDTO: AuthTokenDTO = try await httpClient.execute(
            GitHubEndpoint.exchangeCode(
                code: code,
                clientID: AppConfiguration.clientID,
                clientSecret: AppConfiguration.clientSecret
            ),
            token: nil
        )

        // 2. Persist token
        try keychainService.save(tokenDTO.accessToken, for: KeychainService.Keys.accessToken)

        // 3. Fetch user profile
        let userDTO: UserDTO = try await httpClient.execute(
            GitHubEndpoint.currentUser,
            token: tokenDTO.accessToken
        )
        return userDTO.toDomain()
    }

    func signOut() throws {
        try keychainService.delete(for: KeychainService.Keys.accessToken)
    }

    func isAuthenticated() -> Bool {
        (try? keychainService.load(for: KeychainService.Keys.accessToken)) != nil
    }
}
