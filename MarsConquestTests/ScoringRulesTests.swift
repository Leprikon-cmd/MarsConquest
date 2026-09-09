//
//  ScoringRulesTests.swift
//
//  Зачем:
//  Проверяет порядок подсчёта очков и разрешения ничьих.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - тестовые сценарии и данные; на интерфейс приложения они не влияют.
//
import Foundation
import Testing
@testable import MarsConquest

@Suite("Правила подсчёта очков")
struct ScoringRulesTests {
    @Test("Оставшиеся M€ разрешают ничью раньше карт")
    func tieBreakerUsesRemainingMegaCreditsBeforeCards() {
        let game = makeGame(players: [
            makePlayer(name: "Аня", score: LocalScore(victoryPoints: 80), megaCredits: 10, cards: 1),
            makePlayer(name: "Борис", score: LocalScore(victoryPoints: 80), megaCredits: 9, cards: 9),
            makePlayer(name: "Вера", score: LocalScore(victoryPoints: 75), megaCredits: 99, cards: 99)
        ])

        let ranking = ScoreManager().ranking(in: game)
        #expect(ranking.map(\.place) == [1, 2, 3])
        #expect(ranking.map(\.player.name) == ["Аня", "Борис", "Вера"])
    }

    @Test("Карты разрешают ничью при равных M€")
    func tieBreakerUsesCardsWhenMegaCreditsAreEqual() {
        let game = makeGame(players: [
            makePlayer(name: "Аня", score: LocalScore(victoryPoints: 80), megaCredits: 7, cards: 2),
            makePlayer(name: "Борис", score: LocalScore(victoryPoints: 80), megaCredits: 7, cards: 4),
            makePlayer(name: "Вера", score: LocalScore(victoryPoints: 75))
        ])

        let ranking = ScoreManager().ranking(in: game)
        #expect(ranking.map(\.place) == [1, 2, 3])
        #expect(ranking.map(\.player.name) == ["Борис", "Аня", "Вера"])
    }

    @Test("Полностью равный тай-брейк сохраняет ничью")
    func equalTieBreakerValuesPreserveTie() {
        let game = makeGame(players: [
            makePlayer(name: "Аня", score: LocalScore(victoryPoints: 80), megaCredits: 7, cards: 4),
            makePlayer(name: "Борис", score: LocalScore(victoryPoints: 80), megaCredits: 7, cards: 4),
            makePlayer(name: "Вера", score: LocalScore(victoryPoints: 75))
        ])

        #expect(ScoreManager().ranking(in: game).map(\.place) == [1, 1, 2])
    }

    @Test("Политика учитывается только с дополнением Кризис")
    func politicsRequiresTurmoil() {
        let player = makePlayer(
            name: "Владелец",
            score: LocalScore(
                terraformingRating: 20,
                greenery: 5,
                cities: 4,
                victoryPoints: 3,
                resourcesOnCards: 2,
                conditionsOnCards: 1,
                politics: 6
            )
        )
        var game = makeGame(players: [player])

        game.expansions.hasTurmoil = false
        #expect(ScoreManager().calculateBaseScore(for: player, in: game) == 35)

        game.expansions.hasTurmoil = true
        #expect(ScoreManager().calculateBaseScore(for: player, in: game) == 41)
    }

    @Test("Достижение и места в награде добавляют правильные очки")
    func achievementsAndAwardsAddExpectedPoints() {
        let first = makePlayer(name: "Аня", score: LocalScore(victoryPoints: 10))
        let second = makePlayer(name: "Борис", score: LocalScore(victoryPoints: 10))
        let third = makePlayer(name: "Вера", score: LocalScore(victoryPoints: 10))
        var game = makeGame(players: [first, second, third])
        game.achievements = [
            LocalAchievement(name: "Градоначальник", winnerPlayerIDs: [first.id])
        ]
        game.awards = [
            LocalAward(
                name: "Банкир",
                firstPlacePlayerIDs: [first.id],
                secondPlacePlayerIDs: [second.id]
            )
        ]

        let calculator = ScoreManager()
        #expect(calculator.calculateTotalScore(for: first, in: game) == 20)
        #expect(calculator.calculateTotalScore(for: second, in: game) == 12)
        #expect(calculator.calculateTotalScore(for: third, in: game) == 10)
    }

    @Test("При ничьей за первое место второе место в награде не начисляется")
    func tiedAwardFirstPlaceSuppressesSecondPlace() {
        let first = makePlayer(name: "Аня")
        let second = makePlayer(name: "Борис")
        let third = makePlayer(name: "Вера")
        var game = makeGame(players: [first, second, third])
        game.awards = [
            LocalAward(
                name: "Учёный",
                firstPlacePlayerIDs: [first.id, second.id],
                secondPlacePlayerIDs: [third.id]
            )
        ]

        let calculator = ScoreManager()
        #expect(calculator.awardPoints(for: first, in: game) == 5)
        #expect(calculator.awardPoints(for: second, in: game) == 5)
        #expect(calculator.awardPoints(for: third, in: game) == 0)
    }

    @Test("В партии вдвоём второе место в награде не начисляется")
    func twoPlayerAwardHasNoSecondPlacePoints() {
        let first = makePlayer(name: "Аня")
        let second = makePlayer(name: "Борис")
        var game = makeGame(players: [first, second])
        game.awards = [
            LocalAward(
                name: "Теплотехник",
                firstPlacePlayerIDs: [first.id],
                secondPlacePlayerIDs: [second.id]
            )
        ]

        #expect(ScoreManager().awardPoints(for: first, in: game) == 5)
        #expect(ScoreManager().awardPoints(for: second, in: game) == 0)
    }

    @Test("Ничья не за первое место сохраняет плотную нумерацию")
    func lowerTieUsesDenseRanking() {
        let game = makeGame(players: [
            makePlayer(name: "Аня", score: LocalScore(victoryPoints: 90)),
            makePlayer(name: "Борис", score: LocalScore(victoryPoints: 80)),
            makePlayer(name: "Вера", score: LocalScore(victoryPoints: 80)),
            makePlayer(name: "Глеб", score: LocalScore(victoryPoints: 70))
        ])

        #expect(ScoreManager().ranking(in: game).map(\.place) == [1, 2, 2, 3])
    }

    private func makeGame(players: [LocalPlayer]) -> LocalGameData {
        LocalGameData(
            id: UUID(),
            date: Date(),
            gameField: GameField.farsida.rawValue,
            backgroundImageName: "Tarsis_BG1",
            players: players
        )
    }

    private func makePlayer(
        name: String,
        score: LocalScore = LocalScore(),
        megaCredits: Int32 = 0,
        cards: Int32 = 0
    ) -> LocalPlayer {
        LocalPlayer(
            id: UUID(),
            name: name,
            color: "Красный",
            corporation: "",
            prologue1: "",
            prologue2: "",
            score: score,
            remainingMegaCredits: megaCredits,
            unplayedCards: cards
        )
    }
}
