//
//  ScoreManager.swift
//
//  Управляет подсчётом очков и итоговым рейтингом игроков.
//

import Foundation
import SwiftUI

struct ScoreRankingEntry: Identifiable {
    let player: LocalPlayer
    let score: Int32
    let place: Int

    var id: UUID { player.id }
}

struct ScoreManager {
    /// Считает базовые очки игрока без наград и достижений.
    func calculateBaseScore(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        var total =
            player.score.terraformingRating +
            player.score.greenery +
            player.score.cities +
            player.score.victoryPoints +
            player.score.resourcesOnCards +
            player.score.conditionsOnCards

        if localGame.expansions.hasTurmoil {
            total += player.score.politics
        }

        return total
    }

    /// Считает очки игрока за достижения.
    func achievementPoints(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        localGame.achievements.reduce(into: Int32(0)) { points, achievement in
            if achievement.winnerPlayerIDs.contains(player.id) {
                points += Int32(GameConstants.achievementPoints)
            }
        }
    }

    /// Считает очки игрока за награды.
    func awardPoints(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        let playersCount = localGame.players.count

        return localGame.awards.reduce(into: Int32(0)) { points, award in
            let hasTieForFirst = award.firstPlacePlayerIDs.count > 1

            if award.firstPlacePlayerIDs.contains(player.id) {
                points += Int32(GameConstants.awardFirstPlacePoints)
            }

            if playersCount >= 3,
               !hasTieForFirst,
               award.secondPlacePlayerIDs.contains(player.id) {
                points += Int32(GameConstants.awardSecondPlacePoints)
            }
        }
    }

    /// Считает полную сумму очков игрока.
    func calculateTotalScore(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        calculateBaseScore(for: player, in: localGame) +
        achievementPoints(for: player, in: localGame) +
        awardPoints(for: player, in: localGame)
    }

    /// Игроки, разделившие первое место по победным очкам до применения тай-брейка.
    func leadersTiedOnPoints(in localGame: LocalGameData) -> [LocalPlayer] {
        let scoredPlayers = localGame.players.map {
            (player: $0, score: calculateTotalScore(for: $0, in: localGame))
        }
        guard let topScore = scoredPlayers.map(\.score).max() else { return [] }

        let leaders = scoredPlayers
            .filter { $0.score == topScore }
            .map(\.player)

        return leaders.count > 1 ? leaders : []
    }

    func hasTieForFirst(in localGame: LocalGameData) -> Bool {
        leadersTiedOnPoints(in: localGame).count > 1
    }

    /// Формирует плотный рейтинг. Тай-брейк действует только на равенство за 1-е место:
    /// сначала оставшиеся M€, затем количество неразыгранных карт.
    func ranking(in localGame: LocalGameData) -> [ScoreRankingEntry] {
        let scoredPlayers = localGame.players.enumerated().map {
            (index: $0.offset, player: $0.element, score: calculateTotalScore(for: $0.element, in: localGame))
        }
        let groupedByScore = Dictionary(grouping: scoredPlayers, by: \.score)
        let scores = groupedByScore.keys.sorted(by: >)

        var result: [ScoreRankingEntry] = []
        var currentPlace = 0

        for (scoreIndex, score) in scores.enumerated() {
            let group = (groupedByScore[score] ?? []).sorted { $0.index < $1.index }

            if scoreIndex == 0, group.count > 1 {
                let tieSorted = group.sorted {
                    if $0.player.remainingMegaCredits != $1.player.remainingMegaCredits {
                        return $0.player.remainingMegaCredits > $1.player.remainingMegaCredits
                    }
                    if $0.player.unplayedCards != $1.player.unplayedCards {
                        return $0.player.unplayedCards > $1.player.unplayedCards
                    }
                    return $0.index < $1.index
                }

                var previousCredits: Int32?
                var previousCards: Int32?

                for item in tieSorted {
                    if previousCredits != item.player.remainingMegaCredits ||
                        previousCards != item.player.unplayedCards {
                        currentPlace += 1
                        previousCredits = item.player.remainingMegaCredits
                        previousCards = item.player.unplayedCards
                    }

                    result.append(
                        ScoreRankingEntry(player: item.player, score: item.score, place: currentPlace)
                    )
                }
            } else {
                currentPlace += 1
                result.append(contentsOf: group.map {
                    ScoreRankingEntry(player: $0.player, score: $0.score, place: currentPlace)
                })
            }
        }

        return result
    }

    /// Проверяет, является ли игрок победителем с учётом тай-брейка.
    func isWinner(_ player: LocalPlayer, in localGame: LocalGameData) -> Bool {
        ranking(in: localGame).first { $0.player.id == player.id }?.place == 1
    }
}

extension Color {
    static func named(_ color: String) -> Color {
        switch color {
        case "Красный": return .red
        case "Синий": return .blue
        case "Желтый": return .yellow
        case "Черный": return .black
        case "Зеленый": return .green
        default: return .gray
        }
    }
}
