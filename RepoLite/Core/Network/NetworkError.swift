//
//  NetworkError.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

// Typed network errors for the entire app.
public enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(retryAfter: Int?)
    case serverError(statusCode: Int)
    case decodingFailure(String)
    case noInternetConnection
    case timeout
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:             
            return "Invalid URL."
        case .unauthorized:           
            return "Session expired. Please sign in again."
        case .forbidden:              
            return "You don't have access to this resource."
        case .notFound:               
            return "Resource not found."
        case .rateLimited(let after): 
            return after.map { "Rate limited. Retry in \($0)s." } ?? "Rate limited by GitHub."
        case .serverError(let code):  
            return "Server error (\(code)). Try again later."
        case .decodingFailure(let message): 
            return "Data error: \(message)"
        case .noInternetConnection:   
            return "No internet connection."
        case .timeout:                
            return "Request timed out."
        case .unknown(let message):
            return message
        }
    }

    var isRetryable: Bool {
        switch self {
        case .timeout, .noInternetConnection, .serverError: return true
        default: return false
        }
    }
}
