//
//  JournalCompatibilityTests.swift
//
//  Зачем:
//  Проверяет, что журнал корректно открывает исторические записи после изменений справочников.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - набор проверяемых старых вариантов данных; это не влияет на приложение.
//
import Foundation
import Testing
@testable import MarsConquest

@Suite("Совместимость старых записей")
struct JournalCompatibilityTests {
    @Test("Историческое написание Элада распознаётся как Эллада")
    func legacyHellasSpellingIsResolved() {
        #expect(GameField.resolve(persistedName: "Элада", referenceID: nil) == .hellas)
        #expect(GameField.resolve(persistedName: "  ЭЛАДА  ", referenceID: nil) == .hellas)
    }

    @Test("Постоянный идентификатор поля имеет приоритет над старым названием")
    func stableBoardIdentifierHasPriority() {
        let field = GameField.resolve(
            persistedName: GameField.farsida.rawValue,
            referenceID: GameField.elysium.referenceID
        )

        #expect(field == .elysium)
    }

    @Test("Неизвестное поле не приписывается Фарсиде")
    func unknownBoardRemainsUnknown() {
        #expect(GameField.resolve(persistedName: "Неизвестное поле", referenceID: nil) == nil)
    }
}
