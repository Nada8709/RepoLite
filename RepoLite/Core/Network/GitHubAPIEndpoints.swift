//
//  GitHubAPIEndpoints.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

// Namespace for all GitHub API endpoints.
enum GitHubEndpoint: APIEndpoint {
    // Auth
    case exchangeCode(code: String, clientID: String, clientSecret: String)

    // User
    case currentUser

    // Repositories
    case userRepositories(page: Int, perPage: Int)

    // Branches
    case branches(owner: String, repo: String, page: Int, perPage: Int)

    // MARK: - APIEndpoint
    var baseURL: URL {
        switch self {
        case .exchangeCode:
            return AppConfiguration.authBaseURL
        default:
            return AppConfiguration.apiBaseURL
        }
    }

    var path: String {
        switch self {
        case .exchangeCode:                          
            return "/login/oauth/access_token"
        case .currentUser:                           
            return "/user"
        case .userRepositories:                      
            return "/user/repos"
        case .branches(let owner, let repo, _, _):  
            return "/repos/\(owner)/\(repo)/branches"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .exchangeCode:
            return .post
        default:
            return .get
        }
    }

    var headers: [String: String] {
        switch self {
        case .exchangeCode:
            return ["Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        default:
            return [:]
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .userRepositories(let page, let perPage):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "sort", value: "updated"),
                URLQueryItem(name: "affiliation", value: "owner")
            ]
        case .branches(_, _, let page, let perPage):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ]
        default: return nil
        }
    }

    var body: Data? {
        switch self {
        case .exchangeCode(let code, let clientID, let secret):
            let params = "client_id=\(clientID)&client_secret=\(secret)&code=\(code)"
            return params.data(using: .utf8)
        default: return nil
        }
    }
}
