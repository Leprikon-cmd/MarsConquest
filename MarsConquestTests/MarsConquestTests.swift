//
//  MarsConquestTests.swift
//  MarsConquestTests
//

import Foundation
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
}
