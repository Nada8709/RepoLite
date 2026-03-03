//
//  NetworkErrorTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class NetworkErrorTests: XCTestCase {

    // MARK: - Error Descriptions

    func test_unauthorized_hasDescription() {
        XCTAssertNotNil(NetworkError.unauthorized.errorDescription)
        XCTAssertFalse(NetworkError.unauthorized.errorDescription!.isEmpty)
    }

    func test_noInternetConnection_hasDescription() {
        XCTAssertNotNil(NetworkError.noInternetConnection.errorDescription)
    }

    func test_rateLimited_withRetryAfter_includesSeconds() {
        let error = NetworkError.rateLimited(retryAfter: 60)
        XCTAssertTrue(error.errorDescription?.contains("60") == true)
    }

    func test_rateLimited_withoutRetryAfter_hasGenericMessage() {
        let error = NetworkError.rateLimited(retryAfter: nil)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_serverError_includesStatusCode() {
        let error = NetworkError.serverError(statusCode: 503)
        XCTAssertTrue(error.errorDescription?.contains("503") == true)
    }

    func test_decodingFailure_includesMessage() {
        let error = NetworkError.decodingFailure("missing key 'id'")
        XCTAssertTrue(error.errorDescription?.contains("missing key 'id'") == true)
    }

    func test_unknown_includesMessage() {
        let error = NetworkError.unknown("something went wrong")
        XCTAssertEqual(error.errorDescription, "something went wrong")
    }

    // MARK: - isRetryable

    func test_timeout_isRetryable() {
        XCTAssertTrue(NetworkError.timeout.isRetryable)
    }

    func test_noInternetConnection_isRetryable() {
        XCTAssertTrue(NetworkError.noInternetConnection.isRetryable)
    }

    func test_serverError_isRetryable() {
        XCTAssertTrue(NetworkError.serverError(statusCode: 500).isRetryable)
    }

    func test_unauthorized_isNotRetryable() {
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
    }

    func test_notFound_isNotRetryable() {
        XCTAssertFalse(NetworkError.notFound.isRetryable)
    }

    func test_decodingFailure_isNotRetryable() {
        XCTAssertFalse(NetworkError.decodingFailure("bad format").isRetryable)
    }

    // MARK: - Equatable

    func test_sameErrors_areEqual() {
        XCTAssertEqual(NetworkError.unauthorized, NetworkError.unauthorized)
        XCTAssertEqual(NetworkError.notFound, NetworkError.notFound)
        XCTAssertEqual(NetworkError.timeout, NetworkError.timeout)
    }

    func test_differentErrors_areNotEqual() {
        XCTAssertNotEqual(NetworkError.unauthorized, NetworkError.forbidden)
        XCTAssertNotEqual(NetworkError.timeout, NetworkError.noInternetConnection)
    }

    func test_rateLimited_withDifferentRetryAfter_areNotEqual() {
        XCTAssertNotEqual(
            NetworkError.rateLimited(retryAfter: 30),
            NetworkError.rateLimited(retryAfter: 60)
        )
    }
}
