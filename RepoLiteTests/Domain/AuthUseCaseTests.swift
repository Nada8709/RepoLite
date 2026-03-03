//
//  AuthUseCaseTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class SignInUseCaseTests: XCTestCase {

    private var sut: SignInUseCase!
    private var mockGateway: MockAuthGateway!

    override func setUp() {
        super.setUp()
        mockGateway = MockAuthGateway()
        sut = SignInUseCase(repository: mockGateway)
    }

    override func tearDown() {
        sut = nil
        mockGateway = nil
        super.tearDown()
    }

    // MARK: - Happy Path

    func test_execute_returnsUser_whenCodeIsValid() async throws {
        // Given
        let expectedUser = User.stub(login: "Nada8709")
        mockGateway.stubbedUser = expectedUser

        // When
        let result = try await sut.execute(code: "valid_oauth_code")

        // Then
        XCTAssertEqual(result.login, "Nada8709")
        XCTAssertEqual(mockGateway.signInCallCount, 1)
    }

    func test_execute_forwardsCodeToGateway() async throws {
        // Given
        let code = "abc123xyz"

        // When
        _ = try await sut.execute(code: code)

        // Then
        XCTAssertEqual(mockGateway.lastCode, code)
    }

    // MARK: - Validation

    func test_execute_throwsUnknownError_whenCodeIsEmpty() async {
        // When / Then
        do {
            _ = try await sut.execute(code: "")
            XCTFail("Expected error for empty code")
        } catch let error as NetworkError {
            if case .unknown(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected NetworkError.unknown")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_doesNotCallGateway_whenCodeIsEmpty() async {
        // When
        _ = try? await sut.execute(code: "")

        // Then
        XCTAssertEqual(mockGateway.signInCallCount, 0)
    }

    // MARK: - Error Propagation

    func test_execute_propagatesUnauthorizedError() async {
        // Given
        mockGateway.stubbedSignInError = NetworkError.unauthorized

        // When / Then
        do {
            _ = try await sut.execute(code: "some_code")
            XCTFail("Expected error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: -

final class SignOutUseCaseTests: XCTestCase {

    private var sut: SignOutUseCase!
    private var mockGateway: MockAuthGateway!

    override func setUp() {
        super.setUp()
        mockGateway = MockAuthGateway()
        sut = SignOutUseCase(repository: mockGateway)
    }

    override func tearDown() {
        sut = nil
        mockGateway = nil
        super.tearDown()
    }

    func test_execute_callsGatewaySignOut() throws {
        // When
        try sut.execute()

        // Then
        XCTAssertEqual(mockGateway.signOutCallCount, 1)
    }

    func test_execute_propagatesError_whenGatewayFails() {
        // Given
        mockGateway.stubbedSignOutError = KeychainService.KeychainError.unexpectedStatus(-1)

        // When / Then
        XCTAssertThrowsError(try sut.execute())
    }
}
