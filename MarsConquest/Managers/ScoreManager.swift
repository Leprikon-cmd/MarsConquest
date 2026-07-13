//
//  ScoreManager.swift
//
//  Зачем:
//  Управляет подсчётом итоговых очков игроков и вспомогательной логикой,
//  связанной с результатами партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - подсчёт итоговых очков игрока
//  - подсчёт очков за достижения
//  - подсчёт очков за награды
//  - определение победителя
//  - преобразование строкового имени цвета в Color
//

import Foundation
import SwiftUI

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
        var points: Int32 = 0
        
        for achievement in localGame.achievements {
            if achievement.winnerPlayerIDs.contains(player.id) {
                points += Int32(GameConstants.achievementPoints)
            }
        }
        
        return points
    }
    
    /// Считает очки игрока за награды.
    func awardPoints(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        var points: Int32 = 0
        let playersCount = localGame.players.count
        
        for award in localGame.awards {
            let hasTieForFirst = award.firstPlacePlayerIDs.count > 1

            if award.firstPlacePlayerIDs.contains(player.id) {
                points += Int32(GameConstants.awardFirstPlacePoints)
            }
            
            if playersCount >= 3 && !hasTieForFirst && award.secondPlacePlayerIDs.contains(player.id) {
                points += Int32(GameConstants.awardSecondPlacePoints)
            }
        }
        
        return points
    }

    /// Считает полную сумму очков игрока.
    func calculateTotalScore(for player: LocalPlayer, in localGame: LocalGameData) -> Int32 {
        calculateBaseScore(for: player, in: localGame) +
        achievementPoints(for: player, in: localGame) +
        awardPoints(for: player, in: localGame)
    }

    /// Проверяет, является ли игрок победителем партии.
    func isWinner(_ player: LocalPlayer, in localGame: LocalGameData) -> Bool {
        let scores = localGame.players.map { calculateTotalScore(for: $0, in: localGame) }
        guard let maxScore = scores.max() else { return false }
        return calculateTotalScore(for: player, in: localGame) == maxScore
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
