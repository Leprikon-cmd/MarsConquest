//
//  MarsConquestUITests.swift
//  MarsConquestUITests
//
//  Created by Евгений Зотчик on 06.03.2025.
//

import XCTest

final class MarsConquestUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testJournalNavigationFitsInsideApplicationWindow() throws {
        let app = launchJournal()

        let navigation = app.otherElements["root-navigation"]
        XCTAssertTrue(navigation.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["root-navigation-journal"].exists)
        XCTAssertTrue(app.buttons["root-navigation-settings"].exists)
        XCTAssertGreaterThan(navigation.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(navigation.frame.maxY, app.frame.maxY)
    }

    @MainActor
    func testNewExpeditionKeepsStartGameButtonReachable() throws {
        let app = launchJournal()

        let navigation = app.otherElements["root-navigation"]
        let newExpedition = app.buttons["root-navigation-new-game"]
        XCTAssertTrue(newExpedition.waitForExistence(timeout: 5))
        XCTAssertTrue(newExpedition.isHittable)
        XCTAssertGreaterThanOrEqual(newExpedition.frame.minY, navigation.frame.minY)

        newExpedition.tap()

        let landingSiteSelector = app.otherElements["landing-site-selector"]
        let startExpedition = app.buttons["start-expedition-button"]
        XCTAssertTrue(landingSiteSelector.waitForExistence(timeout: 5))
        XCTAssertTrue(startExpedition.isHittable)
        XCTAssertLessThanOrEqual(startExpedition.frame.maxY, app.frame.maxY)

        startExpedition.tap()

        let teamScreen = app.otherElements["expedition-team-screen"]
        let addPlayer = app.buttons["add-player-button"]
        let startGame = app.buttons["start-game-button"]
        XCTAssertTrue(teamScreen.waitForExistence(timeout: 5))
        XCTAssertTrue(addPlayer.waitForExistence(timeout: 5))
        XCTAssertTrue(startGame.waitForExistence(timeout: 5))
        XCTAssertTrue(addPlayer.isHittable, "Кнопка добавления игрока должна оставаться доступной.")
        XCTAssertTrue(startGame.isHittable, "Кнопка начала партии не должна уходить под нижний край экрана.")
        XCTAssertLessThan(addPlayer.frame.maxY, startGame.frame.minY)
        XCTAssertLessThanOrEqual(startGame.frame.maxY, app.frame.maxY)
    }

    @MainActor
    private func launchJournal() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-test-seed-owner")
        app.launch()

        XCTAssertTrue(
            app.otherElements["owner-dashboard"].waitForExistence(timeout: 5),
            "Тестовый запуск должен открыть бортовой журнал."
        )
        return app
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
