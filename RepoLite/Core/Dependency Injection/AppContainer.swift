//
//  AppContainer.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation
import Combine

// Composition root — assembles all dependencies.
@MainActor
public final class AppContainer: ObservableObject {
    private let keychainService: KeychainServiceProtocol = KeychainService()
    private lazy var httpClient: HTTPClientProtocol = HTTPClient()
    private lazy var repositoryCache: RepositoryCacheProtocol = RepositoryCache()

    // MARK: Repositories (Data layer)
    private lazy var authRepository: AuthRepositoryProtocol = AuthRepository(
        httpClient: httpClient,
        keychainService: keychainService
    )
    private lazy var repoRepository: RepoGatewayProtocol = RepoGateway(
        httpClient: httpClient,
        keychainService: keychainService,
        cache: repositoryCache
    )
    private lazy var branchRepository: BranchRepositoryProtocol = BranchRepository(
        httpClient: httpClient,
        keychainService: keychainService
    )

    // MARK: Auth state
    private let authStateSubject = CurrentValueSubject<Bool, Never>(false)
    var authStatePublisher: AnyPublisher<Bool, Never> { authStateSubject.eraseToAnyPublisher() }

    public init() {
        let args = ProcessInfo.processInfo.arguments

        // Force sign out for UI tests
        if args.contains("RESET_AUTH") {
            try? keychainService.delete(for: KeychainService.Keys.accessToken)
            authStateSubject.send(false)
            return
        }

        // Force sign in for UI tests
        if args.contains("MOCK_AUTHENTICATED") {
            try? keychainService.save("mock_token_ui_test", for: KeychainService.Keys.accessToken)
            authStateSubject.send(true)
            return
        }

        // Normal launch — restore session from Keychain
        let hasToken = (try? keychainService.load(for: KeychainService.Keys.accessToken)) != nil
        authStateSubject.send(hasToken)
    }

    // MARK: - Factory Methods

    func makeSignInViewModel() -> SignInViewModel {
        SignInViewModel(
            signInUseCase: SignInUseCase(repository: authRepository),
            onAuthenticated: { [weak self] in
                self?.authStateSubject.send(true)
            }
        )
    }

    func makeRepositoryListViewModel() -> RepositoryListViewModel {
        RepositoryListViewModel(
            fetchRepositoriesUseCase: FetchRepositoriesUseCase(repository: repoRepository),
            signOutUseCase: SignOutUseCase(repository: authRepository),
            onSignedOut: { [weak self] in
                self?.authStateSubject.send(false)
            }
        )
    }

    func makeBranchListViewModel(repository: Repository) -> BranchListViewModel {
        BranchListViewModel(
            repository: repository,
            fetchBranchesUseCase: FetchBranchesUseCase(repository: branchRepository)
        )
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "repolite",
              url.host == "oauth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else { return }

        NotificationCenter.default.post(
            name: .oauthCallbackReceived,
            object: nil,
            userInfo: ["code": code]
        )
    }
}

extension Notification.Name {
    static let oauthCallbackReceived = Notification.Name("oauthCallbackReceived")
}
