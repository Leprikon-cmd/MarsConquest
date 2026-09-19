//
//  JournalBackupModels.swift
//
//  Зачем:
//  Описывает независимый от Core Data, версионированный JSON-формат архива журнала.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - состав формата и его версию; изменение требует поддержки старых архивов в менеджере.
//

import Foundation

struct JournalBackup: Codable {
    static let currentFormatVersion = 2

    let formatVersion: Int
    let createdAt: Date
    let profile: JournalBackupOwnerProfile?
    let savedPlayers: [JournalBackupSavedPlayer]
    let games: [JournalBackupGame]
    let avatar: JournalBackupAvatar
}

struct JournalBackupOwnerProfile: Codable {
    let id: UUID
    let savedPlayerID: UUID
    let createdAt: Date?
    let updatedAt: Date?
    let hasBaseGame: Bool
    let hasPrelude: Bool
    let hasVenus: Bool
    let hasColonies: Bool
    let hasHellasElysium: Bool
    let hasTurmoil: Bool
}

struct JournalBackupSavedPlayer: Codable {
    let id: UUID
    let name: String?
    let nickname: String?
    let realName: String?
    let favoriteColor: String?
    let isFavorite: Bool
    let createdAt: Date?
    let updatedAt: Date?
}

struct JournalBackupAvatar: Codable {
    let style: String
    let selfieJPEGData: Data?
}

struct JournalBackupGame: Codable {
    let id: UUID
    let date: Date?
    let gameField: String?
    let gameFieldID: String?
    let gameNumber: Int32
    let generation: Int32
    let venusTerraformingScale: Int32
    let hasPrelude: Bool
    let hasVenus: Bool
    let hasColonies: Bool
    let hasHellasElysium: Bool
    let hasTurmoil: Bool
    let hasTieBreakerData: Bool
    /// Необязателен для чтения архивов формата 1.
    let usesHostMode: Bool?
    /// Снимок спортивного регламента и его итога. Классические записи его не содержат.
    let sports: JournalBackupSports?
    let players: [JournalBackupPlayer]
    let colonies: [JournalBackupColony]
    let achievements: [JournalBackupAchievement]
    let awards: [JournalBackupAward]
}

struct JournalBackupSports: Codable {
    let ruleID: String
    let ruleVersion: String
    let timeLimitSeconds: Int64
    let generationLimit: Int32
    let allTimedOutRule: String?
    let outcome: String?
    let winnerPlayerID: UUID?
}

struct JournalBackupPlayer: Codable {
    let id: UUID
    let savedPlayerID: UUID?
    let name: String?
    let color: String?
    let corporation: String?
    let corporationID: String?
    let prologue1: String?
    let prologue1ID: String?
    let prologue2: String?
    let prologue2ID: String?
    let remainingMegaCredits: Int32
    let unplayedCards: Int32
    /// Необязательны для чтения архивов формата 1.
    let sportsTimeUsedSeconds: Int64?
    let sportsTimeExceeded: Bool?
    let score: JournalBackupScore?
}

struct JournalBackupScore: Codable {
    let terraformingRating: Int32
    let greenery: Int32
    let cities: Int32
    let victoryPoints: Int32
    let resourcesOnCards: Int32
    let conditionsOnCards: Int32
    let politics: Int32
}

struct JournalBackupColony: Codable {
    let name: String?
    let referenceID: String?
}

struct JournalBackupAchievement: Codable {
    let name: String?
    let referenceID: String?
    let playerID: UUID
}

struct JournalBackupAward: Codable {
    let name: String?
    let referenceID: String?
    let place: Int16
    let playerID: UUID
}

struct JournalRestoreReport {
    let gamesRestored: Int
    let gamesAlreadyPresent: Int
    let savedPlayersRestored: Int
    let profileRestored: Bool
    /// UUID только что внесённых партий. Нужны, чтобы после переноса чужой истории
    /// предложить владельцу выбрать себя лишь среди новых записей.
    let restoredGameIDs: [UUID]

    var changedJournal: Bool {
        gamesRestored > 0 || savedPlayersRestored > 0 || profileRestored
    }
}
