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

/// Переносит встроенный каталог GameData в единый рабочий справочник Core Data.
/// Функцию безопасно вызывать при каждом запуске: она добавит только отсутствующие
/// записи и удалит точные дубликаты справочных данных.
func generateInitialGameData(in viewContext: NSManagedObjectContext) {
    do {
        var addedCount = 0
        var removedDuplicatesCount = 0

        let corporationsRequest: NSFetchRequest<Corporation> = Corporation.fetchRequest()
        let corporations = try viewContext.fetch(corporationsRequest)
        var corporationsByName: [String: Corporation] = [:]

        for corporation in corporations {
            guard let name = corporation.name else { continue }
            let key = normalizedReferenceName(name)

            if corporationsByName[key] == nil {
                corporationsByName[key] = corporation
            } else {
                viewContext.delete(corporation)
                removedDuplicatesCount += 1
            }
        }

        for name in GameData.corporations where corporationsByName[normalizedReferenceName(name)] == nil {
            let corporation = Corporation(context: viewContext)
            corporation.name = name
            corporation.gamesPlayed = 0
            corporation.wins = 0
            addedCount += 1
        }

        let prologuesRequest: NSFetchRequest<Prologue> = Prologue.fetchRequest()
        let prologues = try viewContext.fetch(prologuesRequest)
        var prologuesByName: [String: Prologue] = [:]

        for prologue in prologues {
            guard let name = prologue.name else { continue }
            let key = normalizedReferenceName(name)

            if prologuesByName[key] == nil {
                prologuesByName[key] = prologue
            } else {
                viewContext.delete(prologue)
                removedDuplicatesCount += 1
            }
        }

        for name in GameData.prologues where prologuesByName[normalizedReferenceName(name)] == nil {
            let prologue = Prologue(context: viewContext)
            prologue.name = name
            prologue.gamesPlayed = 0
            prologue.wins = 0
            addedCount += 1
        }

        let achievementsRequest: NSFetchRequest<AchievementTemplate> = AchievementTemplate.fetchRequest()
        let achievements = try viewContext.fetch(achievementsRequest)
        var achievementTemplatesByKey: [String: AchievementTemplate] = [:]

        for achievement in achievements {
            guard let name = achievement.name, let field = achievement.gameField else { continue }
            let key = referenceKey(name: name, field: field)

            if achievementTemplatesByKey[key] == nil {
                achievementTemplatesByKey[key] = achievement
            } else {
                viewContext.delete(achievement)
                removedDuplicatesCount += 1
            }
        }

        let awardsRequest: NSFetchRequest<AwardTemplate> = AwardTemplate.fetchRequest()
        let awards = try viewContext.fetch(awardsRequest)
        var awardTemplatesByKey: [String: AwardTemplate] = [:]

        for award in awards {
            guard let name = award.name, let field = award.gameField else { continue }
            let key = referenceKey(name: name, field: field)

            if awardTemplatesByKey[key] == nil {
                awardTemplatesByKey[key] = award
            } else {
                viewContext.delete(award)
                removedDuplicatesCount += 1
            }
        }

        for field in GameField.allCases.map(\.rawValue) {
            for name in GameData.achievements(for: field) {
                let key = referenceKey(name: name, field: field)
                guard achievementTemplatesByKey[key] == nil else { continue }

                let achievement = AchievementTemplate(context: viewContext)
                achievement.name = name
                achievement.gameField = field
                addedCount += 1
            }

            for name in GameData.awards(for: field) {
                let key = referenceKey(name: name, field: field)
                guard awardTemplatesByKey[key] == nil else { continue }

                let award = AwardTemplate(context: viewContext)
                award.name = name
                award.gameField = field
                addedCount += 1
            }
        }

        guard viewContext.hasChanges else { return }

        try viewContext.save()
        print("Справочные данные синхронизированы: добавлено \(addedCount), удалено дубликатов \(removedDuplicatesCount).")
    } catch {
        print("Ошибка синхронизации справочных данных: \(error.localizedDescription)")
    }
}

private func normalizedReferenceName(_ name: String) -> String {
    name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func referenceKey(name: String, field: String) -> String {
    "\(normalizedReferenceName(field))|\(normalizedReferenceName(name))"
}
