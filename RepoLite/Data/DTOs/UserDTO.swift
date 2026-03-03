//
//  UserDTO.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

struct UserDTO: Decodable {
    let id: Int
    let login: String
    let avatarUrl: String?
    let name: String?
    let publicRepos: Int

    func toDomain() -> User {
        User(
            id: id,
            login: login,
            avatarURL: avatarUrl.flatMap(URL.init),
            name: name,
            publicRepos: publicRepos
        )
    }
}

struct AuthTokenDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String

    func toDomain() -> AuthToken {
        AuthToken(accessToken: accessToken, tokenType: tokenType, scope: scope)
    }
}
