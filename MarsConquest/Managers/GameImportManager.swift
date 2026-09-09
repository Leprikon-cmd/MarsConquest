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
//  Что можно менять руками:
//  - правила исторического импорта; для резервных копий используйте JournalBackupManager;
//  - импорт всегда проходит в отдельном контексте, чтобы ошибка не оставляла частичные записи.
//

import Foundation
import CoreData

struct GameImportManager {

    static func importFromBundle(filename: String, in context: NSManagedObjectContext) throws -> Int {
        // Xcode собирает синхронизируемые ресурсы в корень bundle, даже если
        // они аккуратно разложены по папкам в исходном проекте.
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let games = try JSONDecoder().decode([ImportedGame].self, from: data)

        guard let coordinator = context.persistentStoreCoordinator else {
            throw ImportError.missingPersistentStoreCoordinator
        }

        let savingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        savingContext.persistentStoreCoordinator = coordinator

        let saveObserver = ImportContextSaveObserver()
        let token = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: savingContext,
            queue: nil
        ) { notification in
            saveObserver.notification = notification
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let importedCount = try savingContext.performAndWait {
            do {
                let count = try restoreImportedGames(games, in: savingContext)
                try savingContext.save()
                return count
            } catch {
                savingContext.rollback()
                throw error
            }
        }

        if let notification = saveObserver.notification {
            context.performAndWait {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }

        return importedCount
    }

    /// Вносит исторические записи только в переданный частный контекст.
    /// Внешний метод сохраняет его одним атомарным действием.
    private static func restoreImportedGames(
        _ games: [ImportedGame],
        in context: NSManagedObjectContext
    ) throws -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var importedCount = 0

        for importedGame in games {
            let game = Game(context: context)
            game.id = UUID()
            game.date = formatter.date(from: importedGame.date) ?? Date()
            game.gameField = importedGame.gameField
            game.gameFieldID = GameData.gameFieldID(named: importedGame.gameField)
            game.gameNumber = Int32(importedGame.gameNumber ?? 0)
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
                player.corporationID = GameData.corporationID(named: importedPlayer.corporation)
                player.prologue1 = importedPlayer.prologue1
                player.prologue1ID = GameData.preludeID(named: importedPlayer.prologue1)
                player.prologue2 = importedPlayer.prologue2
                player.prologue2ID = GameData.preludeID(named: importedPlayer.prologue2)

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
                    achievement.referenceID = GameData.achievementID(
                        named: importedAchievement.name,
                        for: importedGame.gameField
                    )
                    achievement.game = game
                    achievement.player = player
                }
            }

            for importedAward in importedGame.awards {
                for playerName in importedAward.firstPlacePlayerNames {
                    guard let player = playersByName[playerName] else { continue }

                    let award = Award(context: context)
                    award.name = importedAward.name
                    award.referenceID = GameData.awardID(
                        named: importedAward.name,
                        for: importedGame.gameField
                    )
                    award.place = 1
                    award.game = game
                    award.player = player
                }

                for playerName in importedAward.secondPlacePlayerNames {
                    guard let player = playersByName[playerName] else { continue }

                    let award = Award(context: context)
                    award.name = importedAward.name
                    award.referenceID = GameData.awardID(
                        named: importedAward.name,
                        for: importedGame.gameField
                    )
                    award.place = 2
                    award.game = game
                    award.player = player
                }
            }

            importedCount += 1
        }

        return importedCount
    }

    private static func normalizedColor(_ color: String?) -> String {
        guard let color else { return "" }

        let allowed = ["Красный", "Синий", "Желтый", "Черный", "Зеленый"]
        return allowed.contains(color) ? color : ""
    }

    enum ImportError: LocalizedError {
        case fileNotFound
        case missingPersistentStoreCoordinator

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Файл исторического импорта не найден."
            case .missingPersistentStoreCoordinator:
                return "Хранилище журнала недоступно."
            }
        }
    }
}

private final class ImportContextSaveObserver {
    var notification: Notification?
}
