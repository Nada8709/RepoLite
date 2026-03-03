//
//  AuthFlowUITests.swift
//  RepoLiteUITests
//

import XCTest

final class AuthFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Sign In Screen
    func test_signInScreen_isPresented_onFirstLaunch() {
        app.launchArguments = ["UI_TESTING", "RESET_AUTH"]
        app.launch()

        XCTAssertTrue(
            app.buttons["signInButton"].waitForExistence(timeout: 5),
            "Sign in button should be visible"
        )
    }

    func test_signInButton_isEnabled_onLaunch() {
        app.launchArguments = ["UI_TESTING", "RESET_AUTH"]
        app.launch()

        let signInButton = app.buttons["Sign in with GitHub"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        XCTAssertTrue(signInButton.isEnabled)
    }

    func test_signOutAlert_isPresented_whenSignOutTapped() {
        app.launchArguments = ["UI_TESTING", "MOCK_AUTHENTICATED"]
        app.launch()

        XCTAssertTrue(app.buttons["signOutButton"].waitForExistence(timeout: 10))
        app.buttons["signOutButton"].tap()

        XCTAssertTrue(
            app.alerts["Sign Out"].waitForExistence(timeout: 3),
            "Confirmation alert should appear"
        )
    }

    func test_signOutAlert_hasCancelOption() {
        app.launchArguments = ["UI_TESTING", "MOCK_AUTHENTICATED"]
        app.launch()

        XCTAssertTrue(app.buttons["signOutButton"].waitForExistence(timeout: 10))
        app.buttons["signOutButton"].tap()

        let alert = app.alerts["Sign Out"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
    }

    func test_dismissingSignOutAlert_keepsRepositoryList_visible() {
        app.launchArguments = ["UI_TESTING", "MOCK_AUTHENTICATED"]
        app.launch()

        XCTAssertTrue(app.buttons["signOutButton"].waitForExistence(timeout: 10))
        app.buttons["signOutButton"].tap()
        app.alerts["Sign Out"].buttons["Cancel"].tap()

        XCTAssertTrue(
            app.buttons["signOutButton"].waitForExistence(timeout: 3),
            "Repository list should still be visible after cancelling sign out"
        )
    }
}
