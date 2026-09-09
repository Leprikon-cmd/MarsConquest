//
//  MarsConquestUITests.swift
//  MarsConquestUITests
//
//  Зачем:
//  Проверяет основные пользовательские сценарии на запущенном приложении.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - сценарии и идентификаторы элементов; на интерфейс приложения они не влияют.
//

import XCTest

final class MarsConquestUITests: XCTestCase {

    override func setUpWithError() throws {
        // Подготовка выполняется перед каждым сценарием.

        // После первой ошибки сценарий останавливается, чтобы не маскировать причину.
        continueAfterFailure = false

        // Начальное состояние задаётся здесь, до запуска сценария.
    }

    override func tearDownWithError() throws {
        // Очистка выполняется после каждого сценария.
    }

    @MainActor
    func testJournalNavigationFitsInsideApplicationWindow() throws {
        let app = launchJournal()

        let navigation = app.descendants(matching: .any)["root-navigation"]
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

        let playerEditor = app.descendants(matching: .any)["player-editor-card"]
        let playerName = app.textFields["player-name-field"]
        XCTAssertTrue(playerEditor.waitForExistence(timeout: 5))
        XCTAssertTrue(playerName.exists, "После высадки должна открыться карточка владельца.")

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.isHittable)
        backButton.tap()

        let teamScreen = app.descendants(matching: .any)["expedition-team-screen"]
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
    func testExpeditionCanBeRecordedAndOpenedFromJournal() throws {
        let app = launchJournal()

        app.buttons["root-navigation-new-game"].tap()
        XCTAssertTrue(app.buttons["start-expedition-button"].waitForExistence(timeout: 5))
        app.buttons["start-expedition-button"].tap()

        XCTAssertTrue(app.otherElements["player-editor-card"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        let startGame = app.buttons["start-game-button"]
        XCTAssertTrue(startGame.waitForExistence(timeout: 5))
        startGame.tap()

        let scoreScreen = app.descendants(matching: .any)["score-screen"]
        XCTAssertTrue(scoreScreen.waitForExistence(timeout: 5))

        let generationMenu = app.buttons["game-info-generation-menu"]
        XCTAssertTrue(generationMenu.waitForExistence(timeout: 5))
        generationMenu.tap()
        XCTAssertTrue(app.buttons["5"].waitForExistence(timeout: 5))
        app.buttons["5"].tap()

        let archiveEntry = app.buttons["archive-entry-button"]
        for _ in 0..<4 where !archiveEntry.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(archiveEntry.isHittable)
        archiveEntry.tap()

        let confirmation = app.alerts["Подтверждение записи"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Внести в журнал"].tap()

        let recorded = app.alerts["Запись внесена в архив."]
        XCTAssertTrue(recorded.waitForExistence(timeout: 5))
        recorded.buttons["Продолжить"].tap()

        let detail = app.descendants(matching: .any)["game-detail-screen"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Поколение: 5"].exists)
    }

    @MainActor
    private func launchJournal() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-test-in-memory-store")
        app.launchArguments.append("-ui-test-seed-owner")
        app.launch()

        let newExpedition = app.buttons["root-navigation-new-game"]
        guard newExpedition.waitForExistence(timeout: 10) else {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "UI launch failure"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("Тестовый запуск должен открыть бортовой журнал.")
            return app
        }
        return app
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Измеряет время запуска приложения.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launchArguments.append("-ui-test-in-memory-store")
                app.launchArguments.append("-ui-test-seed-owner")
                app.launch()
            }
        }
    }
}
