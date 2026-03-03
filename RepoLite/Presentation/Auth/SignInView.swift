//
//  SignInView.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI
import AuthenticationServices

public struct SignInView: View {
    @ObservedObject var viewModel: SignInViewModel
    @Environment(\.webAuthenticationSession) private var webAuthSession

    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(.primary)

                    Text("Github Lite")
                        .font(.largeTitle.bold())

                    Text("Browse your repositories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if case .error(let msg) = viewModel.state {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(msg)
                            .font(.callout)
                    }
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    viewModel.signInTapped(contextProvider: ASPresentationAnchorProvider())
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.state == .loading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "person.badge.key.fill")
                        }
                        Text("Sign in with GitHub")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.state == .loading ? Color.secondary : Color.primary)
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
                .disabled(viewModel.state == .loading)
                .animation(.default, value: viewModel.state)
            }
        }
        .animation(.easeInOut, value: viewModel.state)
    }
}

// Bridges SwiftUI context to ASWebAuthenticationSession
private final class ASPresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? ASPresentationAnchor()
    }
}
