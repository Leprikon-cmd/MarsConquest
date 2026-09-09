//
//  MarsConquestTests.swift
//  MarsConquestTests
//
//  Зачем:
//  Проверяет модель Core Data, миграции и безопасное сохранение журнала.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - тестовые сценарии и данные; на интерфейс приложения они не влияют.
//

import Foundation
import CoreData
import Testing
@testable import MarsConquest

struct MarsConquestTests {
    @Test @MainActor func currentModelHasReciprocalJournalRelationships() throws {
        let context = try makeInMemoryContext()
        let model = try #require(context.persistentStoreCoordinator?.managedObjectModel)

        let colonies = try #require(model.entitiesByName["Game"]?.relationshipsByName["colonies"])
        let colonyGame = try #require(model.entitiesByName["Colony"]?.relationshipsByName["game"])
        #expect(colonies.inverseRelationship === colonyGame)
        #expect(colonyGame.inverseRelationship === colonies)

        let achievements = try #require(
            model.entitiesByName["Player"]?.relationshipsByName["achievements"]
        )
        let achievementPlayer = try #require(
            model.entitiesByName["Achievement"]?.relationshipsByName["player"]
        )
        #expect(achievements.inverseRelationship === achievementPlayer)
        #expect(achievementPlayer.inverseRelationship === achievements)
    }

    @Test @MainActor func gameSaverPersistsCompleteJournalEntry() throws {
        let context = try makeInMemoryContext()
        let firstPlayerID = UUID()
        let secondPlayerID = UUID()
        let gameID = UUID()
        let date = Date(timeIntervalSinceReferenceDate: 123_456)
        let firstScore = LocalScore(
            terraformingRating: 36,
            greenery: 12,
            cities: 8,
            victoryPoints: 15,
            resourcesOnCards: 6,
            conditionsOnCards: 4,
            politics: 3
        )
        let secondScore = LocalScore(victoryPoints: 70)
        let firstPlayer = LocalPlayer(
            id: firstPlayerID,
            name: "Владелец",
            color: "Красный",
            corporation: "Ecoline",
            prologue1: "Allied Banks",
            prologue2: "Biolab",
            score: firstScore,
            remainingMegaCredits: 11,
            unplayedCards: 2
        )
        let secondPlayer = LocalPlayer(
            id: secondPlayerID,
            name: "Соперник",
            color: "Синий",
            corporation: "Helion",
            prologue1: "Business Empire",
            prologue2: "Donation",
            score: secondScore,
            remainingMegaCredits: 5,
            unplayedCards: 1
        )
        let expansions = GameExpansions(
            hasPrelude: true,
            hasVenus: true,
            hasColonies: true,
            hasHellasElysium: true,
            hasTurmoil: true
        )
        let localGame = LocalGameData(
            id: gameID,
            date: date,
            gameField: GameField.hellas.rawValue,
            backgroundImageName: "Hellas1",
            players: [firstPlayer, secondPlayer],
            colonies: ["Luna", "Titan"],
            achievements: [
                LocalAchievement(name: "Эрудит", winnerPlayerIDs: [firstPlayerID])
            ],
            awards: [
                LocalAward(
                    name: "Агроном",
                    firstPlacePlayerIDs: [firstPlayerID],
                    secondPlacePlayerIDs: [secondPlayerID]
                )
            ],
            generation: 9,
            venusTerraformingScale: 20,
            expansions: expansions
        )

        _ = try GameSaver().save(localGame: localGame, in: context)
        context.reset()

        let request = NSFetchRequest<Game>(entityName: "Game")
        request.predicate = NSPredicate(format: "id == %@", gameID as CVarArg)
        let game = try #require(context.fetch(request).first)
        #expect(game.date == date)
        #expect(game.gameField == GameField.hellas.rawValue)
        #expect(game.generation == 9)
        #expect(game.venusTerraformingScale == 20)
        #expect(game.hasPrelude && game.hasVenus && game.hasColonies)
        #expect(game.hasHellasElysium && game.hasTurmoil)

        let colonies = game.colonies?.allObjects as? [Colony] ?? []
        #expect(Set(colonies.compactMap(\.name)) == ["Luna", "Titan"])
        #expect(colonies.allSatisfy { $0.game === game })

        let players = game.players?.allObjects as? [Player] ?? []
        #expect(players.count == 2)
        let savedFirst = try #require(players.first { $0.savedPlayerID == firstPlayerID })
        let savedSecond = try #require(players.first { $0.savedPlayerID == secondPlayerID })
        #expect(savedFirst.score?.terraformingRating == 36)
        #expect(savedFirst.score?.politics == 3)
        #expect(savedFirst.remainingMegaCredits == 11)
        #expect(savedFirst.unplayedCards == 2)
        #expect(savedFirst.achievements?.count == 1)
        #expect(savedSecond.awards?.contains { ($0 as? Award)?.place == 2 } == true)
        #expect(game.achievments?.count == 1)
        #expect(game.awards?.count == 2)
    }

    @Test @MainActor func gameSaverKeepsUnrelatedContextChangesIsolated() throws {
        let context = try makeInMemoryContext()
        let pendingPlayer = SavedPlayer(context: context)
        pendingPlayer.id = UUID()
        pendingPlayer.name = "Несохранённый профиль"
        pendingPlayer.createdAt = Date()
        pendingPlayer.updatedAt = Date()

        let localGame = makeGame([
            makePlayer(name: "Владелец", score: 70, megaCredits: 0, cards: 0)
        ])
        let savedGame = try GameSaver().save(localGame: localGame, in: context)

        #expect(savedGame.id == localGame.id)
        #expect(context.insertedObjects.contains(pendingPlayer))
        #expect(context.hasChanges)

        let request = NSFetchRequest<Game>(entityName: "Game")
        request.predicate = NSPredicate(format: "id == %@", localGame.id as CVarArg)
        #expect(try context.count(for: request) == 1)
    }

    @Test @MainActor func failedSaveLeavesNoEntryAndRetryDoesNotDuplicateIt() throws {
        enum SimulatedSaveError: Error {
            case storageRejected
        }

        let context = try makeInMemoryContext()
        let localGame = makeGame([
            makePlayer(name: "Владелец", score: 70, megaCredits: 0, cards: 0)
        ])
        let request = NSFetchRequest<Game>(entityName: "Game")
        request.predicate = NSPredicate(format: "id == %@", localGame.id as CVarArg)

        let rejectingSaver = GameSaver { _ in
            throw SimulatedSaveError.storageRejected
        }
        #expect(throws: SimulatedSaveError.self) {
            _ = try rejectingSaver.save(localGame: localGame, in: context)
        }
        #expect(try context.count(for: request) == 0)

        _ = try GameSaver().save(localGame: localGame, in: context)
        context.reset()
        #expect(try context.count(for: request) == 1)

        _ = try GameSaver().save(localGame: localGame, in: context)
        context.reset()
        #expect(try context.count(for: request) == 1)
    }

    @Test @MainActor func modelTenStoreMigratesToCurrentModelWithRelationshipsIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("GameDataModel.sqlite")
        let model10 = try compiledModel(named: "GameDataModel 10")
        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model10)
        let oldStore = try oldCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL
        )
        let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        oldContext.persistentStoreCoordinator = oldCoordinator

        let gameID = UUID()
        let playerID = UUID()
        let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: oldContext)
        game.setValue(gameID, forKey: "id")
        game.setValue(GameField.hellas.rawValue, forKey: "gameField")
        let player = NSEntityDescription.insertNewObject(forEntityName: "Player", into: oldContext)
        player.setValue(playerID, forKey: "id")
        player.setValue("Владелец", forKey: "name")
        player.setValue(game, forKey: "game")
        let colony = NSEntityDescription.insertNewObject(forEntityName: "Colony", into: oldContext)
        colony.setValue("Luna", forKey: "name")
        colony.setValue(game, forKey: "game")
        let achievement = NSEntityDescription.insertNewObject(
            forEntityName: "Achievement",
            into: oldContext
        )
        achievement.setValue("Эрудит", forKey: "name")
        achievement.setValue(game, forKey: "game")
        achievement.setValue(player, forKey: "player")
        try oldContext.save()
        try oldCoordinator.remove(oldStore)

        let currentModel = try compiledModel(named: "GameDataModel 11")
        let container = NSPersistentContainer(
            name: "GameDataModel",
            managedObjectModel: currentModel
        )
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        var migrationError: Error?
        container.loadPersistentStores { _, error in
            migrationError = error
        }
        if let migrationError { throw migrationError }

        let request = NSFetchRequest<Game>(entityName: "Game")
        request.predicate = NSPredicate(format: "id == %@", gameID as CVarArg)
        let migratedGame = try #require(container.viewContext.fetch(request).first)
        let migratedPlayers = migratedGame.players?.allObjects as? [Player] ?? []
        let migratedPlayer = try #require(migratedPlayers.first { $0.id == playerID })
        #expect(migratedGame.colonies?.count == 1)
        #expect(migratedGame.achievments?.count == 1)
        #expect(migratedPlayer.achievements?.count == 1)
    }

    @Test @MainActor func modelsFiveThroughNineMigrateToCurrentJournalModel() throws {
        for version in 5...9 {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            defer { try? FileManager.default.removeItem(at: directory) }

            let storeURL = directory.appendingPathComponent("GameDataModel.sqlite")
            let legacyModel = try compiledModel(named: "GameDataModel \(version)")
            let legacyCoordinator = NSPersistentStoreCoordinator(managedObjectModel: legacyModel)
            let legacyStore = try legacyCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL
            )
            let legacyContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            legacyContext.persistentStoreCoordinator = legacyCoordinator

            let gameID = UUID()
            let playerID = UUID()
            let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: legacyContext)
            game.setValue(gameID, forKey: "id")
            game.setValue(GameField.farsida.rawValue, forKey: "gameField")
            let player = NSEntityDescription.insertNewObject(forEntityName: "Player", into: legacyContext)
            player.setValue(playerID, forKey: "id")
            player.setValue("Исторический игрок", forKey: "name")
            player.setValue(game, forKey: "game")
            try legacyContext.save()
            try legacyCoordinator.remove(legacyStore)

            let currentModel = try compiledModel(named: "GameDataModel 11")
            let container = NSPersistentContainer(
                name: "GameDataModel",
                managedObjectModel: currentModel
            )
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]

            var migrationError: Error?
            container.loadPersistentStores { _, error in
                migrationError = error
            }
            if let migrationError { throw migrationError }

            let request = NSFetchRequest<Game>(entityName: "Game")
            request.predicate = NSPredicate(format: "id == %@", gameID as CVarArg)
            let migratedGame = try #require(container.viewContext.fetch(request).first)
            let migratedPlayers = migratedGame.players?.allObjects as? [Player] ?? []
            #expect(migratedGame.gameField == GameField.farsida.rawValue)
            #expect(migratedPlayers.contains { $0.id == playerID && $0.name == "Исторический игрок" })
        }
    }

    @Test @MainActor func careerProgressUsesOnlyLinkedHistoryAndAwardsBaseResults() throws {
        let context = try makeInMemoryContext()
        let ownerID = UUID()

        let win = makeSavedGame(
            in: context,
            players: [
                (ownerID, "Владелец", 90),
                (UUID(), "Аня", 80)
            ]
        )
        let second = makeSavedGame(
            in: context,
            players: [
                (ownerID, "Владелец", 75),
                (UUID(), "Борис", 80),
                (UUID(), "Вера", 70)
            ]
        )
        let twoPlayerLoss = makeSavedGame(
            in: context,
            players: [
                (ownerID, "Владелец", 65),
                (UUID(), "Глеб", 70)
            ]
        )
        let unlinked = makeSavedGame(
            in: context,
            players: [
                (UUID(), "Владелец", 100),
                (UUID(), "Даша", 10)
            ]
        )

        let progress = CareerProgressCalculator().calculate(
            ownerID: ownerID,
            from: [win, second, twoPlayerLoss, unlinked]
        )

        #expect(progress.gamesPlayed == 3)
        #expect(progress.wins == 1)
        #expect(progress.secondPlaces == 2)
        #expect(progress.totalXP == 39)
        #expect(progress.contributions.map(\.totalXP).sorted() == [12, 12, 15])
        let regalia = CareerProgressCalculator().regalia(
            ownerID: ownerID,
            from: [win, second, twoPlayerLoss, unlinked]
        )
        #expect(!CareerProgressCalculator().hasVisibleRegalia(for: progress))
        #expect(regalia.isEmpty)
    }

    @Test @MainActor func careerProgressAwardsObservedContentAndMilestoneOnlyOnce() throws {
        let context = try makeInMemoryContext()
        let ownerID = UUID()
        let start = Date(timeIntervalSinceReferenceDate: 100)
        let games = (0..<5).map { offset in
            makeSavedGame(
                in: context,
                date: start.addingTimeInterval(Double(offset)),
                players: [
                    (ownerID, "Владелец", offset == 0 ? 90 : 70),
                    (UUID(), "Аня", offset == 0 ? 80 : 80),
                    (UUID(), "Борис", 60)
                ]
            )
        }

        for game in games {
            game.gameField = "Фарсида"
            game.gameFieldID = "field.tharsis"
            game.hasPrelude = false
            game.hasVenus = false
            game.hasColonies = false
            game.hasHellasElysium = false
            game.hasTurmoil = false
            let owner = try #require(player(in: game, id: ownerID))
            owner.corporation = "Ecoline"
            owner.corporationID = "corporation.ecoline"
            owner.prologue1 = "Allied Banks"
            owner.prologue1ID = "prelude.allied_banks"
            owner.prologue2 = "Biolab"
            owner.prologue2ID = "prelude.biolab"
        }
        games[0].hasVenus = true
        games[1].hasVenus = true

        let firstOwner = try #require(player(in: games[0], id: ownerID))
        let luna = Colony(context: context)
        luna.name = "Luna"
        luna.referenceID = "colony.luna"
        luna.game = games[0]
        let titan = Colony(context: context)
        titan.name = "Titan"
        titan.referenceID = "colony.titan"
        titan.game = games[1]
        let achievement = Achievement(context: context)
        achievement.player = firstOwner
        achievement.game = games[0]

        let award = Award(context: context)
        award.name = "Banker"
        award.place = 1
        award.player = firstOwner
        award.game = games[0]

        let progress = CareerProgressCalculator().calculate(ownerID: ownerID, from: games)

        #expect(progress.gamesPlayed == 5)
        #expect(progress.totalXP == 153)
        #expect(CareerProgressCalculator().hasVisibleRegalia(for: progress))
        #expect(progress.contributions[0].newFieldXP == 50)
        #expect(progress.contributions[0].newCorporationXP == 10)
        #expect(progress.contributions[0].newCorporationPreludePairXP == 10)
        #expect(progress.contributions[0].achievementXP == 5)
        #expect(progress.contributions[0].awardXP == 5)
        #expect(progress.contributions[4].milestoneXP == 10)
        #expect(progress.contributions.dropFirst().allSatisfy {
            $0.newFieldXP == 0 && $0.newCorporationXP == 0 && $0.newCorporationPreludePairXP == 0
        })

        let regalia = CareerProgressCalculator().regalia(ownerID: ownerID, from: games)
        #expect(regalia.filter { $0.kind == .milestone }.count == 1)
        #expect(Set(regalia.map(\.id)).count == regalia.count)
    }

    @Test func careerLevelRequiresBothExperienceAndGamesPlayed() {
        let calculator = CareerProgressCalculator()

        let insufficientXP = CareerProgressCalculator.Progress(
            totalXP: 49,
            gamesPlayed: 2,
            wins: 0,
            secondPlaces: 0,
            contributions: []
        )
        let secondLevel = CareerProgressCalculator.Progress(
            totalXP: 50,
            gamesPlayed: 2,
            wins: 0,
            secondPlaces: 0,
            contributions: []
        )

        #expect(calculator.level(for: insufficientXP) == 1)
        #expect(calculator.level(for: secondLevel) == 2)
    }

    @Test @MainActor func corporationSpecialistTitleRequiresFiveExpeditions() throws {
        let context = try makeInMemoryContext()
        let ownerID = UUID()
        let calculator = CareerProgressCalculator()
        let games = (0..<5).map { offset in
            makeSavedGame(
                in: context,
                date: Date(timeIntervalSinceReferenceDate: Double(offset)),
                players: [(ownerID, "Владелец", 70), (UUID(), "Аня", 80)]
            )
        }

        for game in games {
            let owner = try #require(player(in: game, id: ownerID))
            owner.corporation = "Ecoline"
            owner.corporationID = "corporation.ecoline"
        }

        #expect(calculator.professionalTitles(ownerID: ownerID, from: Array(games.dropLast())).isEmpty)

        let titles = calculator.professionalTitles(ownerID: ownerID, from: games)
        #expect(titles.count == 1)
        #expect(titles.first?.kind == .corporationSpecialist)
        #expect(titles.first?.detail == "Ecoline")
    }

    private func makeGame(_ players: [LocalPlayer]) -> LocalGameData {
        LocalGameData(
            id: UUID(),
            date: Date(),
            gameField: "Фарсида",
            backgroundImageName: "Tarsis_BG1",
            players: players
        )
    }

    private func makePlayer(
        name: String,
        score: Int32,
        megaCredits: Int32,
        cards: Int32
    ) -> LocalPlayer {
        LocalPlayer(
            id: UUID(),
            name: name,
            color: "Красный",
            corporation: "",
            prologue1: "",
            prologue2: "",
            score: LocalScore(victoryPoints: score),
            remainingMegaCredits: megaCredits,
            unplayedCards: cards
        )
    }

    private func makeInMemoryContext() throws -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "GameDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadingError: Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }

        if let loadingError {
            throw loadingError
        }
        // Контекст должен удерживать контейнер до конца теста: иначе временное хранилище
        // может быть освобождено до создания связанных объектов.
        container.viewContext.userInfo["testPersistentContainer"] = container
        return container.viewContext
    }

    private func compiledModel(named name: String) throws -> NSManagedObjectModel {
        let modelDirectory = try #require(
            Bundle.main.url(forResource: "GameDataModel", withExtension: "momd")
        )
        let modelURL = modelDirectory.appendingPathComponent("\(name).mom")
        return try #require(NSManagedObjectModel(contentsOf: modelURL))
    }

    private func makeSavedGame(
        in context: NSManagedObjectContext,
        date: Date = Date(),
        players: [(UUID, String, Int32)]
    ) -> Game {
        let game = Game(context: context)
        game.id = UUID()
        game.date = date

        for (id, name, points) in players {
            let player = Player(context: context)
            player.id = UUID()
            player.savedPlayerID = id
            player.name = name

            let score = Score(context: context)
            score.victoryPoints = points
            score.player = player
            game.addToPlayers(player)
        }

        return game
    }

    private func player(in game: Game, id: UUID) -> Player? {
        let players = game.players?.allObjects as? [Player] ?? []
        return players.first { $0.savedPlayerID == id }
    }
}
