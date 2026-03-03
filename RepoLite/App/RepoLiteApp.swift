//
//  RepoLiteApp.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI

@main
struct RepoLiteApp: App {
    @StateObject private var appContainer = AppContainer()
    @State private var isAuthenticated = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    RepositoryListView(
                        viewModel: appContainer.makeRepositoryListViewModel(),
                        appContainer: appContainer
                    )
                } else {
                    SignInView(
                        viewModel: appContainer.makeSignInViewModel()
                    )
                }
            }
            .onReceive(appContainer.authStatePublisher) { state in
                withAnimation { isAuthenticated = state }
            }
            .onOpenURL { url in
                appContainer.handleDeepLink(url)
            }
        }
    }
}
