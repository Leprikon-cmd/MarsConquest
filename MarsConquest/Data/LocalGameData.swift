//
//  LocalGameData.swift
//
//  Зачем:
//  Описывает локальные модели данных, которые используются в интерфейсе
//  до сохранения партии в CoreData.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - временная модель игры до сохранения в БД
//  - временная модель игрока
//  - временная модель очков
//  - временная модель достижений
//  - временная модель наград
//

import Foundation

/// Локальная модель состояния игры.
/// Используется в UI до момента сохранения партии в CoreData.
struct LocalGameData {
  var id: UUID
  var date: Date
  var gameField: String
  var players: [LocalPlayer] = []
  /// Колонии, выбранные для текущей партии до её сохранения.
  var colonies: [String] = []
  var achievements: [LocalAchievement] = []
  var awards: [LocalAward] = []
  var generation: Int = GameConstants.startingGeneration
  var expansions: GameExpansions = GameExpansions()

  static func empty(field: String) -> LocalGameData {
    LocalGameData(
      id: UUID(),
      date: Date(),
      gameField: field,
      players: [],
      achievements: [],
      awards: [],
      generation: GameConstants.startingGeneration,
      expansions: ExpansionSettingsManager.load()
    )
  }
}

/// Локальная модель игрока.
/// Хранит данные игрока до записи в сущность Player.
struct LocalPlayer: Identifiable {
  var id: UUID
  var name: String
  var color: String
  var corporation: String
  var prologue1: String
  var prologue2: String
  var score: LocalScore
}

/// Локальная модель очков игрока.
struct LocalScore {
  var terraformingRating: Int32 = 0
  var greenery: Int32 = 0
  var cities: Int32 = 0
  var victoryPoints: Int32 = 0
  var resourcesOnCards: Int32 = 0
  var conditionsOnCards: Int32 = 0
  var politics: Int32 = 0
}

/// Локальная модель достижения.
/// Нужна для выбора достижения и назначения победителя(ей) до сохранения в БД.
struct LocalAchievement: Identifiable {
  var id = UUID()
  var name: String
  var winnerPlayerIDs: [UUID] = []
}

/// Локальная модель награды.
/// Нужна для выбора награды и назначения первого/второго места до сохранения в БД.
struct LocalAward: Identifiable {
  var id = UUID()
  var name: String
  var firstPlacePlayerIDs: [UUID] = []
  var secondPlacePlayerIDs: [UUID] = []
}
