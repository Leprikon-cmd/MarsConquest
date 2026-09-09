//
//  UITestDataBootstrapper.swift
//
//  Зачем:
//  Создаёт минимальные данные только для автоматического запуска интерфейсных тестов.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - аргументы запуска и тестовые данные; обычный запуск приложения их не использует.
//
import CoreData
import Foundation

/// Готовит минимальные данные только для автоматического UI-теста.
/// Обычные запуски приложения этот код не выполняют.
enum UITestDataBootstrapper {
    static let seedOwnerArgument = "-ui-test-seed-owner"
    static let inMemoryStoreArgument = "-ui-test-in-memory-store"

  static func seedOwnerIfRequested(in context: NSManagedObjectContext) {
    guard ProcessInfo.processInfo.arguments.contains(seedOwnerArgument) else { return }
    guard OwnerProfileManager.fetch(in: context) == nil else { return }

    let ownerID = UUID()
    let owner = SavedPlayer(context: context)
    owner.id = ownerID
    owner.name = "Тестовый командир"
    owner.nickname = "Тестовый командир"
    owner.realName = "UI Test"
    owner.favoriteColor = "Красный"
    owner.isFavorite = false
    owner.createdAt = Date()
    owner.updatedAt = Date()

    do {
      _ = try OwnerProfileManager.save(
        ownerPlayerID: ownerID,
        collection: OwnerCollectionSettings(
          hasBaseGame: true,
          expansions: GameExpansions()
        ),
        in: context
      )
    } catch {
      assertionFailure("Не удалось подготовить данные UI-теста: \(error.localizedDescription)")
    }
  }
}
