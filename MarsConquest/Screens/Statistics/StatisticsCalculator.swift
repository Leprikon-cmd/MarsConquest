//
//  StatisticsCalculator.swift
//
//  Зачем:
//  Содержит расчётную логику статистики по сохранённым партиям.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation
import CoreData

struct StatisticsCalculator {

    struct PlayerStats: Identifiable {
        let id = UUID()
        let name: String
        let games: Int
        let wins: Int
        let averageScore: Double
        let bestScore: Int
    }
    
    struct CorporationStats: Identifiable {
        let id = UUID()
        let name: String
        let games: Int
        let wins: Int
        let averageScore: Double
        let bestScore: Int
    }
    
    struct PrologueStats: Identifiable {
        let id = UUID()
        let name: String
        let games: Int
        let wins: Int
        let averageScore: Double
        let bestScore: Int
    }

    /// Форматирует дату для отображения в статистике.
    static func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return UIStrings.unknown }
        return DateFormatters.shortDate.string(from: date)
    }

    /// Считает итоговый счёт игрока по сохранённым категориям.
    static func totalScore(for player: Player, in game: Game) -> Int {
        baseScore(for: player, in: game)
        + achievementPoints(for: player, in: game)
        + awardPoints(for: player, in: game)
    }
    
    static func baseScore(for player: Player, in game: Game) -> Int {
        guard let score = player.score else { return 0 }

        var total =
            Int(score.terraformingRating)
            + Int(score.greenery)
            + Int(score.cities)
            + Int(score.victoryPoints)
            + Int(score.resourcesOnCards)
            + Int(score.conditionsOnCards)

        if game.hasTurmoil {
            total += Int(score.politics)
        }

        return total
    }

    static func achievementPoints(for player: Player, in game: Game) -> Int {
        guard let context = game.managedObjectContext else { return 0 }

        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@ AND player == %@", game, player)

        let count = (try? context.count(for: request)) ?? 0
        return count * GameConstants.achievementPoints
    }

    static func awardPoints(for player: Player, in game: Game) -> Int {
        guard let context = game.managedObjectContext else { return 0 }

        let request: NSFetchRequest<Award> = Award.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)

        guard let awards = try? context.fetch(request) else { return 0 }

        let playersCount = (game.players?.allObjects as? [Player])?.count ?? 0
        var points = 0

        let groupedAwards = Dictionary(grouping: awards, by: { $0.name ?? "" })

        for (_, awardGroup) in groupedAwards {
            let firstPlaceAwards = awardGroup.filter { $0.place == 1 }
            let secondPlaceAwards = awardGroup.filter { $0.place == 2 }
            let hasTieForFirst = firstPlaceAwards.count > 1

            if firstPlaceAwards.contains(where: { $0.player == player }) {
                points += GameConstants.awardFirstPlacePoints
            }

            if playersCount >= 3 &&
                !hasTieForFirst &&
                secondPlaceAwards.contains(where: { $0.player == player }) {
                points += GameConstants.awardSecondPlacePoints
            }
        }

        return points
    }

    /// Определяет победителя конкретной партии.
    static func winner(of game: Game) -> (name: String, score: Int)? {
        guard let players = game.players?.allObjects as? [Player], !players.isEmpty else {
            return nil
        }

        let sortedPlayers = players.sorted {
            totalScore(for: $0, in: game) > totalScore(for: $1, in: game)
        }

        guard let winner = sortedPlayers.first else { return nil }

        return (
            winner.name ?? UIStrings.noName,
            totalScore(for: winner, in: game)
        )
    }

    /// Сводная статистика по игрокам.
    static func playerStats(from games: [Game]) -> [PlayerStats] {
        var stats: [String: (games: Int, wins: Int, totalScore: Int, bestScore: Int)] = [:]

        for game in games {
            guard let players = game.players?.allObjects as? [Player], !players.isEmpty else {
                continue
            }

            let maxScore = players.map { totalScore(for: $0, in: game) }.max() ?? 0

            for player in players {
                let name = player.name ?? UIStrings.noName
                let score = totalScore(for: player, in: game)
                let isWinner = score == maxScore

                if stats[name] == nil {
                    stats[name] = (games: 0, wins: 0, totalScore: 0, bestScore: 0)
                }

                stats[name]!.games += 1
                stats[name]!.totalScore += score
                stats[name]!.bestScore = max(stats[name]!.bestScore, score)

                if isWinner {
                    stats[name]!.wins += 1
                }
            }
        }

        return stats.map { name, value in
            PlayerStats(
                name: name,
                games: value.games,
                wins: value.wins,
                averageScore: value.games > 0
                    ? Double(value.totalScore) / Double(value.games)
                    : 0,
                bestScore: value.bestScore
            )
        }
        .sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            return $0.averageScore > $1.averageScore
        }
    }
    /// Сводная статистика по корпорациям
    static func corporationStats(from games: [Game]) -> [CorporationStats] {
        var stats: [String: (games: Int, wins: Int, totalScore: Int, bestScore: Int)] = [:]

        for game in games {
            guard let players = game.players?.allObjects as? [Player], !players.isEmpty else { continue }

            let maxScore = players.map { totalScore(for: $0, in: game) }.max() ?? 0

            for player in players {
                let corp = player.corporation ?? UIStrings.unknown
                let score = totalScore(for: player, in: game)
                let isWinner = score == maxScore

                if stats[corp] == nil {
                    stats[corp] = (games: 0, wins: 0, totalScore: 0, bestScore: 0)
                }

                stats[corp]!.games += 1
                stats[corp]!.totalScore += score
                stats[corp]!.bestScore = max(stats[corp]!.bestScore, score)

                if isWinner {
                    stats[corp]!.wins += 1
                }
            }
        }

        return stats.map { name, value in
            CorporationStats(
                name: name,
                games: value.games,
                wins: value.wins,
                averageScore: value.games > 0 ? Double(value.totalScore) / Double(value.games) : 0,
                bestScore: value.bestScore
            )
        }
        .sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            return $0.averageScore > $1.averageScore
        }
    }
    
    ///Сводная статистика по прологам
    static func prologueStats(from games: [Game]) -> [PrologueStats] {
        var stats: [String: (games: Int, wins: Int, totalScore: Int, bestScore: Int)] = [:]

        for game in games {
            guard game.hasPrelude else { continue }
            guard let players = game.players?.allObjects as? [Player], !players.isEmpty else { continue }

            let maxScore = players.map { totalScore(for: $0, in: game) }.max() ?? 0

            for player in players {
                let score = totalScore(for: player, in: game)
                let isWinner = score == maxScore

                let playerPrologues = [player.prologue1, player.prologue2]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }

                for prologue in playerPrologues {
                    if stats[prologue] == nil {
                        stats[prologue] = (games: 0, wins: 0, totalScore: 0, bestScore: 0)
                    }

                    stats[prologue]!.games += 1
                    stats[prologue]!.totalScore += score
                    stats[prologue]!.bestScore = max(stats[prologue]!.bestScore, score)

                    if isWinner {
                        stats[prologue]!.wins += 1
                    }
                }
            }
        }

        return stats.map { name, value in
            PrologueStats(
                name: name,
                games: value.games,
                wins: value.wins,
                averageScore: value.games > 0 ? Double(value.totalScore) / Double(value.games) : 0,
                bestScore: value.bestScore
            )
        }
        .sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            return $0.averageScore > $1.averageScore
        }
    }
}
