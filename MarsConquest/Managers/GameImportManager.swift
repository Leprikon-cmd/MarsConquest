//
//  GameImportManager.swift
//
//  Зачем:
//  Импортирует игры из JSON-файла в Core Data.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation
import CoreData

struct GameImportManager {

    static func importFromBundle(filename: String, in context: NSManagedObjectContext) throws -> Int {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let games = try JSONDecoder().decode([ImportedGame].self, from: data)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var importedCount = 0

        for importedGame in games {
            let game = Game(context: context)
            game.id = UUID()
            game.date = formatter.date(from: importedGame.date) ?? Date()
            game.gameField = importedGame.gameField
            game.generation = Int32(importedGame.generation)

            game.hasPrelude = importedGame.expansions.hasPrelude
            game.hasVenus = importedGame.expansions.hasVenus
            game.hasColonies = importedGame.expansions.hasColonies
            game.hasHellasElysium = importedGame.expansions.hasHellasElysium
            game.hasTurmoil = importedGame.expansions.hasTurmoil

            var playersByName: [String: Player] = [:]

            for importedPlayer in importedGame.players {
                let player = Player(context: context)
                player.id = UUID()
                player.name = importedPlayer.name
                player.color = normalizedColor(importedPlayer.color)
                player.corporation = importedPlayer.corporation
                player.prologue1 = importedPlayer.prologue1
                player.prologue2 = importedPlayer.prologue2

                let score = Score(context: context)
                score.terraformingRating = importedPlayer.score.terraformingRating
                score.greenery = importedPlayer.score.greenery
                score.cities = importedPlayer.score.cities
                score.victoryPoints = importedPlayer.score.victoryPoints
                score.resourcesOnCards = importedPlayer.score.resourcesOnCards
                score.conditionsOnCards = importedPlayer.score.conditionsOnCards
                score.politics = importedPlayer.score.politics

                player.score = score
                game.addToPlayers(player)

                playersByName[importedPlayer.name] = player
            }

            for importedAchievement in importedGame.achievements {
                for playerName in importedAchievement.winnerPlayerNames {
                    guard let player = playersByName[playerName] else { continue }

                    let achievement = Achievement(context: context)
                    achievement.name = importedAchievement.name
                    achievement.game = game
                    achievement.player = player
                }
            }

            for importedAward in importedGame.awards {
                for playerName in importedAward.firstPlacePlayerNames {
                    guard let player = playersByName[playerName] else { continue }

                    let award = Award(context: context)
                    award.name = importedAward.name
                    award.place = 1
                    award.game = game
                    award.player = player
                }

                for playerName in importedAward.secondPlacePlayerNames {
                    guard let player = playersByName[playerName] else { continue }

                    let award = Award(context: context)
                    award.name = importedAward.name
                    award.place = 2
                    award.game = game
                    award.player = player
                }
            }

            importedCount += 1
        }

        try context.save()
        return importedCount
    }

    private static func normalizedColor(_ color: String?) -> String {
        guard let color else { return "" }

        let allowed = ["Красный", "Синий", "Желтый", "Черный", "Зеленый"]
        return allowed.contains(color) ? color : ""
    }

    enum ImportError: Error {
        case fileNotFound
    }
}
