//
//  SignOutUseCase.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public struct SignOutUseCase: Sendable {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() throws {
        try repository.signOut()
    }
}
