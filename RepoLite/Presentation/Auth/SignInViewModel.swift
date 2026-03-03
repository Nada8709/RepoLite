//
//  SignInViewModel.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation
import AuthenticationServices

@MainActor
public final class SignInViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case error(String)
    }

    @Published private(set) var state: State = .idle

    private let signInUseCase: SignInUseCase
    private let onAuthenticated: () -> Void
    private var oauthObserver: NSObjectProtocol?

    init(signInUseCase: SignInUseCase, onAuthenticated: @escaping () -> Void) {
        self.signInUseCase = signInUseCase
        self.onAuthenticated = onAuthenticated
        observeCallback()
    }

    deinit { oauthObserver.map(NotificationCenter.default.removeObserver) }

    func signInTapped(contextProvider: ASWebAuthenticationPresentationContextProviding) {
        guard state != .loading else { return }

        let scopes = AppConfiguration.oauthScopes
        let clientID = AppConfiguration.clientID
        let redirect = AppConfiguration.oauthScopes
        guard var components = URLComponents(string: "https://github.com/login/oauth/authorize") else { return }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: AppConfiguration.redirectURI)
        ]
        guard let authURL = components.url else { return }

        state = .loading
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "repolite"
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error {
                self.state = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                    ? .idle
                    : .error(error.localizedDescription)
                return
            }
            guard let code = callbackURL.flatMap({
                URLComponents(url: $0, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value
            }) else {
                self.state = .error("No OAuth code in callback.")
                return
            }
            Task { await self.handleCode(code) }
        }
        session.presentationContextProvider = contextProvider
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }

    // MARK: - Private
    private func observeCallback() {
        oauthObserver = NotificationCenter.default.addObserver(
            forName: .oauthCallbackReceived, object: nil, queue: .main
        ) { [weak self] notification in
            guard let code = notification.userInfo?["code"] as? String else { return }
            Task { await self?.handleCode(code) }
        }
    }

    private func handleCode(_ code: String) async {
        state = .loading
        do {
            _ = try await signInUseCase.execute(code: code)
            state = .idle
            onAuthenticated()
        } catch {
            state = .error((error as? NetworkError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
