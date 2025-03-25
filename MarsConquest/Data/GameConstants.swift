//
//  GameConstants.swift
//
//  Зачем:
//  Единое место хранения игровых констант MarsConquest.
//
//  Почему это важно:
//  1. Игровые ограничения (например количество наград) задаются в одном месте.
//  2. Изменение правил не требует поиска по всему проекту.
//  3. Код становится понятнее: вместо "магических чисел" используются осмысленные имена.
//
//  Пример проблемы без констант:
//
//  if selectedItems.count < 3 { ... }
//
//  Через год уже непонятно что означает "3".
//
//  С константой:
//
//  if selectedItems.count < GameConstants.maxAwards { ... }
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation

enum GameConstants {

    // MARK: - Ограничения игры

    static let maxAchievements = 3
    // Максимальное количество достижений в партии
    //
    // Пример:
    // if selectedItems.count < GameConstants.maxAchievements

    static let maxAwards = 3
    // Максимальное количество наград в партии
    //
    // Пример:
    // if selectedItems.count < GameConstants.maxAwards


    // MARK: - Начальные значения игры

    static let startingGeneration = 5
    // Начальное поколение в интерфейсе подсчёта очков
    //
    // Пример:
    // generation: GameConstants.startingGeneration


    // MARK: - Ограничения игроков

    static let maxPlayers = 5
    // Максимальное количество игроков за столом
    //
    // Используется для ограничений UI
    //
    // Пример:
    // if players.count < GameConstants.maxPlayers


    // MARK: - Значения наград

    static let awardFirstPlacePoints = 5
    // Очки за 1 место награды

    static let awardSecondPlacePoints = 2
    // Очки за 2 место награды


    // MARK: - Значения достижений

    static let achievementPoints = 5
    // Очки за достижение

}
