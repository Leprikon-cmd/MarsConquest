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

import CoreData

/// Менеджер работы с CoreData.
/// Используется как Singleton, чтобы всё приложение работало
/// с одним контейнером и одним основным контекстом.
class CoreDataManager {
    
    /// Глобальный экземпляр менеджера CoreData.
    /// Используется во всём приложении.
    static let shared = CoreDataManager()
    
    /// Основной контейнер CoreData.
    /// Загружает модель данных `GameDataModel` и создаёт хранилище SQLite.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GameDataModel")

        // Разрешаем Core Data автоматически обновить локальную базу при смене версии модели.
        // Например, при удалении устаревшего поля Game.duration.
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Не удалось загрузить хранилище: \(error)")
            }
        }
        
        return container
    }()
    
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
