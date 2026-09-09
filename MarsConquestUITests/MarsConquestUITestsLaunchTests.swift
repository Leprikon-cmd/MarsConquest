//
//  MarsConquestUITestsLaunchTests.swift
//  MarsConquestUITests
//
//  Зачем:
//  Проверяет, что приложение запускается и формирует снимок стартового экрана.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - параметры запуска и сценарий снимка; на интерфейс приложения они не влияют.
//

import XCTest

final class MarsConquestUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-test-in-memory-store")
        app.launchArguments.append("-ui-test-seed-owner")
        app.launch()

        // Здесь размещаются действия после запуска и до снимка стартового экрана.

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
