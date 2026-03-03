//
//  RepositoryDTO.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

struct RepositoryDTO: Decodable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let `private`: Bool
    let stargazersCount: Int
    let language: String?
    let updatedAt: Date
    let defaultBranch: String
    let htmlUrl: String?
    let openIssuesCount: Int
    let forksCount: Int

    func toDomain() -> Repository {
        Repository(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            isPrivate: `private`,
            starCount: stargazersCount,
            language: language,
            updatedAt: updatedAt,
            defaultBranch: defaultBranch,
            url: htmlUrl.flatMap(URL.init),
            openIssuesCount: openIssuesCount,
            forksCount: forksCount
        )
    }
}
