//
//  MarsConquestApp.swift
//
//  Зачем:
//  Точка входа приложения MarsConquest.
//  Инициализирует CoreData и запускает основной интерфейс.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - запуск приложения
//  - инициализация CoreDataManager
//  - проверка справочных данных (корпорации, прологи)
//  - передача managedObjectContext в SwiftUI окружение
//

import SwiftUI
import CoreData

@main
struct MarsConquestApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // Используем shared экземпляр CoreDataManager
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        // Проверяем соответствие данных при запуске
        GameData.validateCorporations(with: coreDataManager.viewContext)
        GameData.validatePrologues(with: coreDataManager.viewContext)
        
        // Дополнительная настройка Core Data при необходимости
        configureCoreData()

        // Если пользователь уже включил МОКСИ, звук начнётся при открытии приложения.
        MoxieSoundManager.shared.startIfEnabled()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Передаем контекст в окружение
                .environment(\.managedObjectContext, coreDataManager.viewContext)
                // Для обработки ошибок Core Data
                .environment(\.managedObjectContextErrorHandler) { error in
                    print("Core Data error: \(error.localizedDescription)")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                MoxieSoundManager.shared.startIfEnabled()
            case .background:
                MoxieSoundManager.shared.stop()
            default:
                break
            }
        }
    }
    
    private func configureCoreData() {
        // Дополнительные настройки Core Data
        coreDataManager.viewContext.automaticallyMergesChangesFromParent = true
        coreDataManager.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Выводим путь к базе данных для отладки
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            print("Core Data Store Location: \(url)")
        }
    }
}

// Расширение для обработки ошибок Core Data
extension EnvironmentValues {
    var managedObjectContextErrorHandler: (Error) -> Void {
        get { self[CoreDataErrorHandlerKey.self] }
        set { self[CoreDataErrorHandlerKey.self] = newValue }
    }
}

struct CoreDataErrorHandlerKey: EnvironmentKey {
    static let defaultValue: (Error) -> Void = { _ in }
}
