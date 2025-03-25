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

    /// Сохраняет игрока в базе, если его ещё нет.
    static func savePlayerIfNeeded(name: String, color: String, in context: NSManagedObjectContext) {

        let request: NSFetchRequest<SavedPlayer> = SavedPlayer.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)

        do {
            let existing = try context.fetch(request)

            if existing.isEmpty {
                let player = SavedPlayer(context: context)
                player.id = UUID()
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
