//
//  PlayerValidationTests.swift
//
//  Зачем:
//  Проверяет правила допустимого состава участников экспедиции.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - тестовые сценарии и данные; на интерфейс приложения они не влияют.
//
import CoreData
import Foundation
import Testing
@testable import MarsConquest

@Suite("Проверка состава экспедиции")
struct PlayerValidationTests {
    @Test("Имя сравнивается без учёта регистра и крайних пробелов")
    @MainActor
    func savedPlayerNameIsNormalized() throws {
        let context = try makeInMemoryContext()
        let savedPlayer = SavedPlayer(context: context)
        savedPlayer.id = UUID()
        savedPlayer.name = "  Евгений  "

        let message = AddPlayerValidator.errorMessage(
            name: "евгений",
            corporation: "Ecoline",
            prologue1: "",
            prologue2: "",
            hasPrelude: false,
            editingPlayerID: nil,
            isUsingSavedPlayer: false,
            savedPlayers: [savedPlayer],
            localPlayers: [],
            locale: Locale(identifier: "ru")
        )

        #expect(message != nil)
    }

    @Test("Редактируемый игрок не конфликтует сам с собой")
    func editingPlayerCanKeepOwnSelections() {
        let id = UUID()
        let player = makePlayer(
            id: id,
            name: "Евгений",
            corporation: "Helion",
            prologue1: "Allied Banks",
            prologue2: "Biolab"
        )

        let message = AddPlayerValidator.errorMessage(
            name: player.name,
            corporation: player.corporation,
            prologue1: player.prologue1,
            prologue2: player.prologue2,
            hasPrelude: true,
            editingPlayerID: id,
            isUsingSavedPlayer: false,
            savedPlayers: [],
            localPlayers: [player],
            locale: Locale(identifier: "ru")
        )

        #expect(message == nil)
    }

    @Test("Корпорацию нельзя назначить двум игрокам")
    func corporationMustBeUniqueWithinGame() {
        let player = makePlayer(name: "Аня", corporation: "Ecoline")

        let message = AddPlayerValidator.errorMessage(
            name: "Борис",
            corporation: "Ecoline",
            prologue1: "",
            prologue2: "",
            hasPrelude: false,
            editingPlayerID: nil,
            isUsingSavedPlayer: false,
            savedPlayers: [],
            localPlayers: [player],
            locale: Locale(identifier: "ru")
        )

        #expect(message != nil)
    }

    @Test("Прологи проверяются только когда дополнение включено")
    func preludeCollisionDependsOnExpansion() {
        let player = makePlayer(
            name: "Аня",
            corporation: "Ecoline",
            prologue1: "Allied Banks",
            prologue2: "Biolab"
        )
        let commonArguments: (Bool) -> String? = { hasPrelude in
            AddPlayerValidator.errorMessage(
                name: "Борис",
                corporation: "Helion",
                prologue1: "Allied Banks",
                prologue2: "Donation",
                hasPrelude: hasPrelude,
                editingPlayerID: nil,
                isUsingSavedPlayer: false,
                savedPlayers: [],
                localPlayers: [player],
                locale: Locale(identifier: "ru")
            )
        }

        #expect(commonArguments(true) != nil)
        #expect(commonArguments(false) == nil)
    }

    private func makePlayer(
        id: UUID = UUID(),
        name: String,
        corporation: String,
        prologue1: String = "",
        prologue2: String = ""
    ) -> LocalPlayer {
        LocalPlayer(
            id: id,
            name: name,
            color: "Красный",
            corporation: corporation,
            prologue1: prologue1,
            prologue2: prologue2,
            score: LocalScore()
        )
    }

    @MainActor
    private func makeInMemoryContext() throws -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "GameDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadingError: Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }
        if let loadingError { throw loadingError }

        container.viewContext.userInfo["testPersistentContainer"] = container
        return container.viewContext
    }
}
