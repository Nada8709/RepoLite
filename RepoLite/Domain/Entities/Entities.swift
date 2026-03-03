//
//  Entities.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

// MARK: - User

public struct User: Equatable, Sendable {
    public let id: Int
    public let login: String
    public let avatarURL: URL?
    public let name: String?
    public let publicRepos: Int
}

// MARK: - Repository

public struct Repository: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let description: String?
    public let isPrivate: Bool
    public let starCount: Int
    public let language: String?
    public let updatedAt: Date
    public let defaultBranch: String
    public let url: URL?
    public let openIssuesCount: Int
    public let forksCount: Int
}

// MARK: - Branch

public struct Branch: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let isProtected: Bool
    public let commitSHA: String
}

// MARK: - Page

public struct Page<T: Sendable>: Sendable {
    public let items: [T]
    public let currentPage: Int
    public let hasNextPage: Bool
}

// MARK: - AuthToken

public struct AuthToken: Equatable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
}
