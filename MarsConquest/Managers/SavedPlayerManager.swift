//
//  SavedPlayerManager.swift
//
//  Зачем:
//  Управляет сохранёнными игроками (SavedPlayer).
//  Используется для:
//  - сохранения новых игроков
//  - получения списка игроков
//

import Foundation
import CoreData

struct SavedPlayerManager {

    /// Обновляет существующий профиль после редактирования игрока в новой партии.
    static func updatePlayer(
        id: UUID,
        name: String,
        color: String,
        in context: NSManagedObjectContext
    ) {
        let request: NSFetchRequest<SavedPlayer> = SavedPlayer.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            guard let player = try context.fetch(request).first else { return }
            player.name = name
            player.favoriteColor = color
            player.updatedAt = Date()
            try context.save()
        } catch {
            print("Ошибка обновления игрока: \(error.localizedDescription)")
        }
    }

    /// Сохраняет новый профиль игрока.
    /// Имя уникально: статистика использует его как понятный человеку идентификатор.
    static func savePlayerIfNeeded(
        id: UUID,
        name: String,
        color: String,
        in context: NSManagedObjectContext
    ) {

        let request: NSFetchRequest<SavedPlayer> = SavedPlayer.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@ OR name =[c] %@",
            id as CVarArg,
            name.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            let existing = try context.fetch(request)

            if existing.isEmpty {
                let player = SavedPlayer(context: context)
                player.id = id
                player.name = name
                player.favoriteColor = color
                player.isFavorite = false
                player.createdAt = Date()
                player.updatedAt = Date()

                try context.save()
            }

        } catch {
            print("Ошибка сохранения игрока: \(error.localizedDescription)")
        }
    }

    /// Получает всех сохранённых игроков
    static func fetchPlayers(in context: NSManagedObjectContext) -> [SavedPlayer] {

        let request: NSFetchRequest<SavedPlayer> = SavedPlayer.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isFavorite", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка загрузки игроков: \(error.localizedDescription)")
            return []
        }
    }
}
