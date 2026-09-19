//
//  GameSaver.swift
//
//  Зачем:
//  Сохраняет новую партию из локальной модели LocalGameData в CoreData.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - создание сущности Game
//  - создание связанных сущностей Player
//  - создание связанных сущностей Score
//  - создание связанных сущностей Achievement
//  - создание связанных сущностей Award
//
//  Что можно менять руками:
//  - соответствие LocalGameData и Core Data — только вместе с моделью данных и архивом журнала.
//  - перенос данных из временной модели LocalGameData в CoreData
//

import Foundation
import CoreData

struct GameSaver {
    /// Единственная точка фиксации записи. В обычном приложении это `save()` контекста;
    /// отдельная операция позволяет воспроизводимо проверить отказ хранилища в тесте.
    private let commit: (NSManagedObjectContext) throws -> Void

    init(commit: @escaping (NSManagedObjectContext) throws -> Void = { try $0.save() }) {
        self.commit = commit
    }
    
    func save(localGame: LocalGameData, in context: NSManagedObjectContext) throws -> Game {
        guard let coordinator = context.persistentStoreCoordinator else {
            throw SaveError.missingPersistentStoreCoordinator
        }

        let savingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        savingContext.persistentStoreCoordinator = coordinator
        savingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let gameObjectID = try savingContext.performAndWait {
            // Повторная попытка с тем же идентификатором должна вернуть уже внесённую запись,
            // а не создать её копию.
            if let existingGame = try existingGame(id: localGame.id, in: savingContext) {
                return existingGame.objectID
            }

            do {
                let game = try insert(localGame: localGame, in: savingContext)
                try commit(savingContext)
                return game.objectID
            } catch {
                // Все новые объекты жили только в частном контексте. Явно отбрасываем их,
                // прежде чем вернуть ошибку и позволить пользователю повторить попытку.
                savingContext.rollback()
                throw error
            }
        }

        return context.performAndWait {
            // После успешного сохранения objectID постоянный и относится к сущности Game.
            context.object(with: gameObjectID) as! Game
        }
    }

    private func existingGame(id: UUID, in context: NSManagedObjectContext) throws -> Game? {
        let request = NSFetchRequest<Game>(entityName: "Game")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func insert(
        localGame: LocalGameData,
        in context: NSManagedObjectContext
    ) throws -> Game {
        let game = Game(context: context)
        game.id = localGame.id
        game.date = localGame.date
        game.gameField = localGame.gameField
        game.gameFieldID = GameData.gameFieldID(named: localGame.gameField)
        game.generation = Int32(localGame.generation ?? 0)
        game.venusTerraformingScale = Int32(localGame.venusTerraformingScale ?? 0)
        
        // Допы
        game.hasPrelude = localGame.expansions.hasPrelude
        game.hasVenus = localGame.expansions.hasVenus
        game.hasColonies = localGame.expansions.hasColonies
        game.hasHellasElysium = localGame.expansions.hasHellasElysium
        game.hasTurmoil = localGame.expansions.hasTurmoil
        game.hasTieBreakerData = ScoreManager().hasTieForFirst(in: localGame)

        if let hostSession = localGame.hostSession {
            game.usesHostMode = true
            game.isSportsMode = hostSession.configuration.isSportsMode

            if hostSession.configuration.isSportsMode {
                game.sportsRuleID = SportsRegulationMetadata.ruleID
                game.sportsRuleVersion = SportsRegulationMetadata.ruleVersion
                game.sportsTimeLimitSeconds = Int64(
                    hostSession.configuration.usesTimer ? hostSession.configuration.timeLimitSeconds : 0
                )
                game.sportsGenerationLimit = Int32(hostSession.configuration.generationLimit ?? 0)
                game.sportsAllTimedOutRule = hostSession.configuration.allTimedOutRule.rawValue
                game.sportsOutcome = (hostSession.sportsOutcome ?? .marsTerraformed).rawValue
                game.sportsWinnerPlayerID = SportsRegulationCalculator.winnerID(in: localGame)
            }
        }

        for colonyName in localGame.colonies {
            let colony = Colony(context: context)
            colony.name = colonyName
            colony.referenceID = GameData.colonyID(named: colonyName)
            colony.game = game
        }

        var playersByID: [UUID: Player] = [:]
        
        for localPlayer in localGame.players {
            let player = Player(context: context)
            player.id = localPlayer.id
            player.savedPlayerID = localPlayer.id
            player.name = localPlayer.name
            player.color = localPlayer.color
            player.corporation = localPlayer.corporation
            player.corporationID = GameData.corporationID(named: localPlayer.corporation)
            player.prologue1 = localPlayer.prologue1
            player.prologue1ID = GameData.preludeID(named: localPlayer.prologue1)
            player.prologue2 = localPlayer.prologue2
            player.prologue2ID = GameData.preludeID(named: localPlayer.prologue2)
            player.remainingMegaCredits = localPlayer.remainingMegaCredits
            player.unplayedCards = localPlayer.unplayedCards

            if let hostSession = localGame.hostSession,
               hostSession.configuration.usesTimer {
                let usedSeconds = hostSession.elapsedSeconds(for: localPlayer.id)
                player.sportsTimeUsedSeconds = Int64(usedSeconds)
                player.sportsTimeExceeded = hostSession.hasExceededTime(for: localPlayer.id)
            }

            let score = Score(context: context)
            score.terraformingRating = localPlayer.score.terraformingRating
            score.greenery = localPlayer.score.greenery
            score.cities = localPlayer.score.cities
            score.victoryPoints = localPlayer.score.victoryPoints
            score.resourcesOnCards = localPlayer.score.resourcesOnCards
            score.conditionsOnCards = localPlayer.score.conditionsOnCards
            score.politics = localPlayer.score.politics

            player.score = score
            game.addToPlayers(player)
            playersByID[localPlayer.id] = player
        }

        for localAchievement in localGame.achievements {
            for winnerID in localAchievement.winnerPlayerIDs {
                guard let player = playersByID[winnerID] else {
                    continue
                }
                
                let achievement = Achievement(context: context)
                achievement.name = localAchievement.name
                achievement.referenceID = GameData.achievementID(
                    named: localAchievement.name,
                    for: localGame.gameField
                )
                achievement.game = game
                achievement.player = player
            }
        }
        
        for localAward in localGame.awards {
            for playerID in localAward.firstPlacePlayerIDs {
                guard let player = playersByID[playerID] else {
                    continue
                }
                
                let award = Award(context: context)
                award.name = localAward.name
                award.referenceID = GameData.awardID(
                    named: localAward.name,
                    for: localGame.gameField
                )
                award.place = 1
                award.game = game
                award.player = player
            }
            
            for playerID in localAward.secondPlacePlayerIDs {
                guard let player = playersByID[playerID] else {
                    continue
                }
                
                let award = Award(context: context)
                award.name = localAward.name
                award.referenceID = GameData.awardID(
                    named: localAward.name,
                    for: localGame.gameField
                )
                award.place = 2
                award.game = game
                award.player = player
            }
        }
        
        return game
    }

    enum SaveError: LocalizedError {
        case missingPersistentStoreCoordinator

        var errorDescription: String? {
            switch self {
            case .missingPersistentStoreCoordinator:
                return "Хранилище журнала недоступно."
            }
        }
    }
}
