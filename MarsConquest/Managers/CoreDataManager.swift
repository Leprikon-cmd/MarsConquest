//
//  CoreDataManager.swift
//
//  Зачем:
//  Централизованное управление CoreData в приложении MarsConquest.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - инициализация CoreData (NSPersistentContainer)
//  - предоставление основного контекста данных
//  - сохранение изменений в базе данных
//
//  Что можно менять руками:
//  - имя модели и настройки хранилища только вместе с проверкой миграции сохранённых журналов.
//

import CoreData

/// Менеджер работы с CoreData.
/// Используется как Singleton, чтобы всё приложение работало
/// с одним контейнером и одним основным контекстом.
final class CoreDataManager {
    
    /// Глобальный экземпляр менеджера CoreData.
    /// Используется во всём приложении.
    static let shared = CoreDataManager()
    
    /// Основной контейнер CoreData.
    /// Загружает модель данных `GameDataModel` и создаёт хранилище SQLite.
    let persistentContainer: NSPersistentContainer

    /// Ошибка открытия постоянного хранилища. Исходный файл базы при этом не изменяется.
    private(set) var loadError: Error?

    private init() {
        let container = NSPersistentContainer(name: "GameDataModel")

        // UI-тесты получают отдельное чистое хранилище и не зависят от истории симулятора.
        if ProcessInfo.processInfo.arguments.contains(UITestDataBootstrapper.inMemoryStoreArgument) {
            let testDescription = NSPersistentStoreDescription()
            testDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [testDescription]
        }

        // Разрешаем Core Data автоматически обновить локальную базу при смене версии модели.
        // Например, при удалении устаревшего поля Game.duration.
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }
        
        persistentContainer = container

        container.loadPersistentStores { [weak self] _, error in
            self?.loadError = error
        }
    }
    
    /// Основной контекст приложения.
    /// Через него выполняются все операции чтения и записи в CoreData.
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// Сохраняет изменения в базе данных.
    /// Проверяет наличие изменений перед сохранением.
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Ошибка сохранения: \(error.localizedDescription)")
            }
        }
    }
}
