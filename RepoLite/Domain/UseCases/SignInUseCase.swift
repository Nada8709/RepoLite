//
//  SignInUseCase.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public struct SignInUseCase: Sendable {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    /// - Parameter code: The OAuth code received from the callback URL.
    /// - Returns: The authenticated `User`.
    public func execute(code: String) async throws -> User {
        guard !code.isEmpty else {
            throw NetworkError.unknown("OAuth code is empty.")
        }
        return try await repository.signIn(code: code)
    }
}
