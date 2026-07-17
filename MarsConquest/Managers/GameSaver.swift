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
//  - перенос данных из временной модели LocalGameData в CoreData
//

import Foundation
import CoreData

struct GameSaver {
    
    func save(localGame: LocalGameData, in context: NSManagedObjectContext) throws -> Game {
        let game = Game(context: context)
        game.id = localGame.id
        game.date = localGame.date
        game.gameField = localGame.gameField
        game.generation = Int32(localGame.generation)
        
        // Допы
        game.hasPrelude = localGame.expansions.hasPrelude
        game.hasVenus = localGame.expansions.hasVenus
        game.hasColonies = localGame.expansions.hasColonies
        game.hasHellasElysium = localGame.expansions.hasHellasElysium
        game.hasTurmoil = localGame.expansions.hasTurmoil

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
            player.name = localPlayer.name
            player.color = localPlayer.color
            player.corporation = localPlayer.corporation
            player.corporationID = GameData.corporationID(named: localPlayer.corporation)
            player.prologue1 = localPlayer.prologue1
            player.prologue1ID = GameData.preludeID(named: localPlayer.prologue1)
            player.prologue2 = localPlayer.prologue2
            player.prologue2ID = GameData.preludeID(named: localPlayer.prologue2)

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
                award.place = 2
                award.game = game
                award.player = player
            }
        }
        
        try context.save()
        
        return game
    }
}
