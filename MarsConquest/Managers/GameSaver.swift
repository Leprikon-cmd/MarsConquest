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
        print("=== GameSaver.save START ===")
        print("Game id: \(localGame.id)")
        print("Game field: \(localGame.gameField)")
        print("Players in localGame: \(localGame.players.count)")
        print("Achievements in localGame: \(localGame.achievements.count)")
        print("Awards in localGame: \(localGame.awards.count)")
        
        let game = Game(context: context)
        game.id = localGame.id
        game.date = localGame.date
        game.gameField = localGame.gameField
        game.generation = Int32(localGame.generation)
        game.gameNumber = ScoreManager.generateGameNumber(in: context)
        
        print("Created Game object with number: \(game.gameNumber)")
        
        var playersByID: [UUID: Player] = [:]
        
        for localPlayer in localGame.players {
            print("Saving player: \(localPlayer.name), id: \(localPlayer.id)")
            
            let player = Player(context: context)
            player.id = localPlayer.id
            player.name = localPlayer.name
            player.color = localPlayer.color
            player.corporation = localPlayer.corporation
            player.prologue1 = localPlayer.prologue1
            player.prologue2 = localPlayer.prologue2

            let score = Score(context: context)
            score.terraformingRating = localPlayer.score.terraformingRating
            score.greenery = localPlayer.score.greenery
            score.cities = localPlayer.score.cities
            score.victoryPoints = localPlayer.score.victoryPoints
            score.resourcesOnCards = localPlayer.score.resourcesOnCards
            score.conditionsOnCards = localPlayer.score.conditionsOnCards
            score.politics = localPlayer.score.politics

            print("""
            Score for \(localPlayer.name):
            TR=\(score.terraformingRating),
            greenery=\(score.greenery),
            cities=\(score.cities),
            victoryPoints=\(score.victoryPoints),
            resourcesOnCards=\(score.resourcesOnCards),
            conditionsOnCards=\(score.conditionsOnCards),
            politics=\(score.politics)
            """)

            player.score = score
            game.addToPlayers(player)
            playersByID[localPlayer.id] = player
        }
        
        print("Players saved to dictionary: \(playersByID.count)")
        
        var createdAchievements = 0
        for localAchievement in localGame.achievements {
            print("Processing achievement: \(localAchievement.name)")
            print("Winner IDs count: \(localAchievement.winnerPlayerIDs.count)")
            
            for winnerID in localAchievement.winnerPlayerIDs {
                guard let player = playersByID[winnerID] else {
                    print("WARNING: no Player found for achievement winnerID \(winnerID)")
                    continue
                }
                
                let achievement = Achievement(context: context)
                achievement.name = localAchievement.name
                achievement.game = game
                achievement.player = player
                createdAchievements += 1
                
                print("Saved achievement '\(localAchievement.name)' for player '\(player.name ?? "nil")'")
            }
        }
        
        var createdAwards = 0
        for localAward in localGame.awards {
            print("Processing award: \(localAward.name)")
            print("First place IDs count: \(localAward.firstPlacePlayerIDs.count)")
            print("Second place IDs count: \(localAward.secondPlacePlayerIDs.count)")
            
            for playerID in localAward.firstPlacePlayerIDs {
                guard let player = playersByID[playerID] else {
                    print("WARNING: no Player found for award firstPlace playerID \(playerID)")
                    continue
                }
                
                let award = Award(context: context)
                award.name = localAward.name
                award.place = 1
                award.game = game
                award.player = player
                createdAwards += 1
                
                print("Saved award '\(localAward.name)' place 1 for player '\(player.name ?? "nil")'")
            }
            
            for playerID in localAward.secondPlacePlayerIDs {
                guard let player = playersByID[playerID] else {
                    print("WARNING: no Player found for award secondPlace playerID \(playerID)")
                    continue
                }
                
                let award = Award(context: context)
                award.name = localAward.name
                award.place = 2
                award.game = game
                award.player = player
                createdAwards += 1
                
                print("Saved award '\(localAward.name)' place 2 for player '\(player.name ?? "nil")'")
            }
        }

        print("Before context.save()")
        print("Inserted objects count: \(context.insertedObjects.count)")
        print("Created achievements in memory: \(createdAchievements)")
        print("Created awards in memory: \(createdAwards)")
        
        try context.save()
        
        print("After context.save()")
        
        let achievementRequest: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        achievementRequest.predicate = NSPredicate(format: "game == %@", game)
        
        let awardRequest: NSFetchRequest<Award> = Award.fetchRequest()
        awardRequest.predicate = NSPredicate(format: "game == %@", game)
        
        let savedAchievements = (try? context.count(for: achievementRequest)) ?? -1
        let savedAwards = (try? context.count(for: awardRequest)) ?? -1
        
        print("Saved achievements linked to game: \(savedAchievements)")
        print("Saved awards linked to game: \(savedAwards)")
        print("=== GameSaver.save END ===")
        
        return game
    }
}
