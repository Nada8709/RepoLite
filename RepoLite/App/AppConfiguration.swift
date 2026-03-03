//
//  AppConfiguration.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

// Centralises all environment-specific constants.
// Values are read from Info.plist so they can be set per build scheme.
enum AppConfiguration {
    // MARK: GitHub OAuth
    static var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String ?? ""
    }
    static var clientSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_SECRET") as? String ?? ""
    }
    static var redirectURI: String { "repolite://oauth/callback" }
    static var oauthScopes: String { "repo,read:user" }

    // MARK: API
    static let apiBaseURL = URL(string: "https://api.github.com")!
    static let authBaseURL = URL(string: "https://github.com")!
    static let defaultPerPage = 30
}
