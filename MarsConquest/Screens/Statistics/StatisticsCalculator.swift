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
    struct GameRankingEntry {
        let player: Player
        let score: Int
        let place: Int
    }

    /// Участники, разделившие первое место по ПО до применения тай-брейка.
    static func leadersTiedOnPoints(in game: Game) -> [Player] {
        guard let players = game.players?.allObjects as? [Player], !players.isEmpty,
              let topScore = players.map({ totalScore(for: $0, in: game) }).max()
        else {
            return []
        }

        let leaders = players.filter { totalScore(for: $0, in: game) == topScore }
        return leaders.count > 1 ? leaders : []
    }

    /// Плотный рейтинг сохранённой партии. Тай-брейк применяется только к
    /// равенству за 1-е место и только если партия сохранена с этими данными.
    static func ranking(for game: Game) -> [GameRankingEntry] {
        guard let players = game.players?.allObjects as? [Player] else { return [] }

        let scoredPlayers = players.map {
            (player: $0, score: totalScore(for: $0, in: game))
        }
        let groupedByScore = Dictionary(grouping: scoredPlayers, by: \.score)
        let scores = groupedByScore.keys.sorted(by: >)

        var result: [GameRankingEntry] = []
        var currentPlace = 0

        for (scoreIndex, score) in scores.enumerated() {
            let group = (groupedByScore[score] ?? []).sorted(by: playerNameOrder)

            if scoreIndex == 0, group.count > 1, game.hasTieBreakerData {
                let tieSorted = group.sorted {
                    if $0.player.remainingMegaCredits != $1.player.remainingMegaCredits {
                        return $0.player.remainingMegaCredits > $1.player.remainingMegaCredits
                    }
                    if $0.player.unplayedCards != $1.player.unplayedCards {
                        return $0.player.unplayedCards > $1.player.unplayedCards
                    }
                    return playerNameOrder($0, $1)
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
                    result.append(GameRankingEntry(player: item.player, score: item.score, place: currentPlace))
                }
            } else {
                currentPlace += 1
                result.append(contentsOf: group.map {
                    GameRankingEntry(player: $0.player, score: $0.score, place: currentPlace)
                })
            }
        }

        return result
    }

    private static func playerNameOrder(
        _ left: (player: Player, score: Int),
        _ right: (player: Player, score: Int)
    ) -> Bool {
        let leftName = left.player.name ?? ""
        let rightName = right.player.name ?? ""
        return leftName.localizedCaseInsensitiveCompare(rightName) == .orderedAscending
    }
struct OwnerJournalStats {
    struct CorporationPreference {
        let name: String
        let games: Int
        let wins: Int
    }

    struct FieldPreference {
        let persistedName: String
        let referenceID: String?
        let games: Int
        let wins: Int
    }

    let games: Int
    let wins: Int
    let averageScore: Int
    let bestScore: Int
    let averagePlace: Int
    let maxGeneration: Int
    let favoriteColor: String?
    let frequentCorporation: CorporationPreference?
    let successfulField: FieldPreference?
    let fastestWinGeneration: Int?

    static let empty = OwnerJournalStats(
        games: 0,
        wins: 0,
        averageScore: 0,
        bestScore: 0,
        averagePlace: 0,
        maxGeneration: 0,
        favoriteColor: nil,
        frequentCorporation: nil,
        successfulField: nil,
        fastestWinGeneration: nil
    )
}


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
    static func formattedDate(_ date: Date?, locale: Locale = .current) -> String {
        guard let date else {
            return locale.identifier.lowercased().hasPrefix("en") ? "Unknown" : "Неизвестно"
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .short
        return formatter.string(from: date)
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

/// Определяет победителя конкретной партии. При полной ничьей возвращает всех победителей.
static func winner(of game: Game, locale: Locale) -> (name: String, score: Int)? {
    let ranking = ranking(for: game)
    guard let winningScore = ranking.first?.score else { return nil }

    let winnerNames = ranking
        .filter { $0.place == 1 }
        .map { $0.player.name ?? UIStrings.noName(locale: locale) }

    return (winnerNames.joined(separator: ", "), winningScore)
}

/// Плотное место игрока. Для равенства за первое место используются M€ и карты на руке,
/// если эти значения были записаны вместе с партией.
static func place(of player: Player, in game: Game) -> Int {
    ranking(for: game).first { $0.player == player }?.place ?? 1
}


/// Личные показатели владельца по стабильному UUID в сохранённых партиях.
static func ownerJournalStats(ownerID: UUID, from games: [Game]) -> OwnerJournalStats {
    var scores: [Int] = []
    var places: [Int] = []
    var wins = 0
    var maxGeneration = 0
    var fastestWinGeneration: Int?
    var colorUsage: [String: (count: Int, lastPlayed: Date)] = [:]
    var corporationUsage: [String: (games: Int, wins: Int, lastPlayed: Date)] = [:]
    var fieldUsage: [String: (persistedName: String, referenceID: String?, games: Int, wins: Int, lastPlayed: Date)] = [:]

    for game in games {
        guard let players = game.players?.allObjects as? [Player],
              let owner = players.first(where: { $0.savedPlayerID == ownerID || $0.id == ownerID })
        else {
            continue
        }

        let score = totalScore(for: owner, in: game)
        let ownerPlace = place(of: owner, in: game)
        scores.append(score)
        places.append(ownerPlace)
        maxGeneration = max(maxGeneration, Int(game.generation))

        if let color = owner.color, !color.isEmpty {
            var usage = colorUsage[color] ?? (count: 0, lastPlayed: .distantPast)
            usage.count += 1
            usage.lastPlayed = max(usage.lastPlayed, game.date ?? .distantPast)
            colorUsage[color] = usage
        }

        let playedAt = game.date ?? .distantPast
        if let corporation = owner.corporation, !corporation.isEmpty {
            var usage = corporationUsage[corporation] ?? (games: 0, wins: 0, lastPlayed: .distantPast)
            usage.games += 1
            usage.lastPlayed = max(usage.lastPlayed, playedAt)
            if ownerPlace == 1 { usage.wins += 1 }
            corporationUsage[corporation] = usage
        }

        if let persistedName = game.gameField, !persistedName.isEmpty {
            let field = GameField.resolve(
                persistedName: persistedName,
                referenceID: game.gameFieldID
            )
            let fieldKey = field?.referenceID ?? persistedName
            var usage = fieldUsage[fieldKey] ?? (
                persistedName: field?.rawValue ?? persistedName,
                referenceID: field?.referenceID ?? game.gameFieldID,
                games: 0,
                wins: 0,
                lastPlayed: .distantPast
            )
            usage.games += 1
            usage.lastPlayed = max(usage.lastPlayed, playedAt)
            if ownerPlace == 1 { usage.wins += 1 }
            fieldUsage[fieldKey] = usage
        }

        if ownerPlace == 1 {
            wins += 1
            if game.generation > 0 {
                fastestWinGeneration = min(fastestWinGeneration ?? Int.max, Int(game.generation))
            }
        }
    }

    guard !scores.isEmpty else { return .empty }

    let favoriteColor = colorUsage.max {
        if $0.value.count != $1.value.count {
            return $0.value.count < $1.value.count
        }
        return $0.value.lastPlayed < $1.value.lastPlayed
    }?.key

    let frequentCorporation = corporationUsage
        .filter { $0.value.games >= 3 }
        .max {
        if $0.value.games != $1.value.games { return $0.value.games < $1.value.games }
        return $0.value.lastPlayed < $1.value.lastPlayed
    }.map {
        OwnerJournalStats.CorporationPreference(
            name: $0.key,
            games: $0.value.games,
            wins: $0.value.wins
        )
    }

    let successfulField = fieldUsage
        .filter { $0.value.games >= 3 }
        .max {
            let leftRate = Double($0.value.wins) / Double($0.value.games)
            let rightRate = Double($1.value.wins) / Double($1.value.games)
            if leftRate != rightRate { return leftRate < rightRate }
            if $0.value.games != $1.value.games { return $0.value.games < $1.value.games }
            return $0.value.lastPlayed < $1.value.lastPlayed
        }
        .map {
            OwnerJournalStats.FieldPreference(
                persistedName: $0.value.persistedName,
                referenceID: $0.value.referenceID,
                games: $0.value.games,
                wins: $0.value.wins
            )
        }

    return OwnerJournalStats(
        games: scores.count,
        wins: wins,
        averageScore: Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded()),
        bestScore: scores.max() ?? 0,
        averagePlace: Int((Double(places.reduce(0, +)) / Double(places.count)).rounded()),
        maxGeneration: maxGeneration,
        favoriteColor: favoriteColor,
        frequentCorporation: frequentCorporation,
        successfulField: successfulField,
        fastestWinGeneration: fastestWinGeneration
    )
}

    /// Сводная статистика по игрокам.
    static func playerStats(from games: [Game], locale: Locale) -> [PlayerStats] {
        var stats: [String: (games: Int, wins: Int, totalScore: Int, bestScore: Int)] = [:]

        for game in games {
            guard let players = game.players?.allObjects as? [Player], !players.isEmpty else {
                continue
            }

            for player in players {
                let name = player.name ?? UIStrings.noName(locale: locale)
                let score = totalScore(for: player, in: game)
                let isWinner = place(of: player, in: game) == 1

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
    static func corporationStats(from games: [Game], locale: Locale) -> [CorporationStats] {
        var stats: [String: (games: Int, wins: Int, totalScore: Int, bestScore: Int)] = [:]

        for game in games {
            guard let players = game.players?.allObjects as? [Player], !players.isEmpty else { continue }

            for player in players {
                let corp = player.corporation ?? UIStrings.unknown(locale: locale)
                let score = totalScore(for: player, in: game)
                let isWinner = place(of: player, in: game) == 1

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

            for player in players {
                let score = totalScore(for: player, in: game)
                let isWinner = place(of: player, in: game) == 1

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
