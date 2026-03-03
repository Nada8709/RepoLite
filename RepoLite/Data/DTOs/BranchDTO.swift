//
//  BranchDTO.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

struct BranchDTO: Decodable {
    struct Commit: Decodable { let sha: String }
    let name: String
    let protected: Bool
    let commit: Commit

    func toDomain() -> Branch {
        Branch(name: name, isProtected: `protected`, commitSHA: commit.sha)
    }
}
