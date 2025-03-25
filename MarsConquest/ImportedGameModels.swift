//
//  ImportedGameModels.swift
//
//  Зачем:
//  Codable-модели для импорта игр из mars_import.json.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation

struct ImportedGame: Codable {
    let gameNumber: Int?
    let sheetName: String?
    let date: String
    let gameField: String
    let generation: Int
    let expansions: ImportedExpansions
    let players: [ImportedPlayer]
    let achievements: [ImportedAchievement]
    let awards: [ImportedAward]
}

struct ImportedExpansions: Codable {
    let hasPrelude: Bool
    let hasVenus: Bool
    let hasColonies: Bool
    let hasHellasElysium: Bool
    let hasTurmoil: Bool
}

struct ImportedPlayer: Codable {
    let name: String
    let color: String?
    let corporation: String
    let prologue1: String
    let prologue2: String
    let score: ImportedScore
}

struct ImportedScore: Codable {
    let terraformingRating: Int32
    let greenery: Int32
    let cities: Int32
    let victoryPoints: Int32
    let resourcesOnCards: Int32
    let conditionsOnCards: Int32
    let politics: Int32
}

struct ImportedAchievement: Codable {
    let name: String
    let winnerPlayerNames: [String]
}

struct ImportedAward: Codable {
    let name: String
    let firstPlacePlayerNames: [String]
    let secondPlacePlayerNames: [String]
}
