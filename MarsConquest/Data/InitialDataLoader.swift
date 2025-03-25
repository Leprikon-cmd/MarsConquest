//
//  InitialDataLoader.swift
//
//  Зачем:
//  Загружает стартовые справочные данные в CoreData при первом запуске приложения.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - загрузка корпораций
//  - загрузка прологов
//  - загрузка шаблонов достижений
//  - загрузка шаблонов наград
//

import Foundation
import CoreData

/// Создаёт и сохраняет стартовые справочные данные в базе.
/// Вызывается при первом запуске приложения.
func generateInitialGameData(in viewContext: NSManagedObjectContext) {
    
    /// Загружаем корпорации.
    for corpName in GameData.corporations {
        let corp = Corporation(context: viewContext)
        corp.name = corpName
        corp.gamesPlayed = 0
        corp.wins = 0
    }
    
    /// Загружаем прологи.
    for prologueName in GameData.prologues {
        let prologue = Prologue(context: viewContext)
        prologue.name = prologueName
        prologue.gamesPlayed = 0
        prologue.wins = 0
    }
    
    /// Загружаем шаблоны достижений для всех игровых полей.
    let fields = GameField.allCases.map(\.rawValue)
    for field in fields {
        for achievementName in GameData.achievements(for: field) {
            let achievement = AchievementTemplate(context: viewContext)
            achievement.name = achievementName
            achievement.gameField = field
        }
    }
    
    /// Загружаем шаблоны наград для всех игровых полей.
    for field in fields {
        for awardName in GameData.awards(for: field) {
            let award = AwardTemplate(context: viewContext)
            award.name = awardName
            award.gameField = field
        }
    }
    
    /// Сохраняем все стартовые данные в CoreData.
    do {
        try viewContext.save()
        print("Изначальные данные успешно загружены в базу!")
    } catch {
        print("Ошибка при сохранении изначальных данных: \(error.localizedDescription)")
    }
}
