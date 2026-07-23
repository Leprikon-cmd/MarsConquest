//
//  MarsConquestTests.swift
//  MarsConquestTests
//

import Foundation
import CoreData
import Testing
@testable import MarsConquest

struct MarsConquestTests {
    @Test func tieBreakerUsesRemainingMegaCreditsBeforeCards() {
        let game = makeGame([
            makePlayer(name: "Аня", score: 80, megaCredits: 10, cards: 1),
            makePlayer(name: "Борис", score: 80, megaCredits: 9, cards: 9),
            makePlayer(name: "Вера", score: 75, megaCredits: 99, cards: 99)
        ])

        let ranking = ScoreManager().ranking(in: game)

        #expect(ranking.map(\.place) == [1, 2, 3])
        #expect(ranking.map(\.player.name) == ["Аня", "Борис", "Вера"])
    }

    @Test func tieBreakerUsesCardsWhenMegaCreditsAreEqual() {
        let game = makeGame([
            makePlayer(name: "Аня", score: 80, megaCredits: 7, cards: 2),
            makePlayer(name: "Борис", score: 80, megaCredits: 7, cards: 4),
            makePlayer(name: "Вера", score: 75, megaCredits: 0, cards: 0)
        ])

        let ranking = ScoreManager().ranking(in: game)

        #expect(ranking.map(\.place) == [1, 2, 3])
        #expect(ranking.map(\.player.name) == ["Борис", "Аня", "Вера"])
    }

    @Test func equalTieBreakerValuesPreserveTie() {
        let game = makeGame([
            makePlayer(name: "Аня", score: 80, megaCredits: 7, cards: 4),
            makePlayer(name: "Борис", score: 80, megaCredits: 7, cards: 4),
            makePlayer(name: "Вера", score: 75, megaCredits: 0, cards: 0)
        ])

        let ranking = ScoreManager().ranking(in: game)

        #expect(ranking.map(\.place) == [1, 1, 2])
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
        #expect(CareerProgressCalculator().hasVisibleRegalia(for: progress))
        #expect(regalia.map(\.kind).contains(.firstExpedition))
        #expect(regalia.map(\.kind).contains(.firstVictory))
        #expect(regalia.map(\.kind).contains(.firstVictoryWithCorporation) == false)
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
        #expect(regalia.filter { $0.kind == .newCorporationPreludePair }.count == 2)
        #expect(regalia.filter { $0.kind == .newPrelude }.count == 2)
        #expect(regalia.filter { $0.kind == .newColony }.count == 2)
        #expect(regalia.filter { $0.kind == .firstExpeditionWithExpansion }.count == 1)
        #expect(regalia.filter { $0.kind == .firstVictoryWithExpansion }.count == 1)
        #expect(regalia.filter { $0.kind == .firstVictoryWithField }.count == 1)
        #expect(regalia.filter { $0.kind == .firstVictoryWithCorporation }.count == 1)
        #expect(regalia.filter { $0.kind == .firstVictoryWithPrelude }.count == 2)
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
