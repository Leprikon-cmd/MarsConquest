//
//  HostModeSettingsManager.swift
//
//  Зачем:
//  Хранит настройку режима ведущего, выбранную для следующих экспедиций.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - ключ хранилища меняется только вместе с планом переноса старых настроек;
//  - стартовые значения режима находятся в HostGameConfiguration.
//

import Foundation

/// Отдельное хранилище не смешивает общую привычку ведущего с данными уже начатой партии.
enum HostModeSettingsManager {
  private static let storageKey = "host-mode-default-configuration-v1"

  static func load() -> HostGameConfiguration {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
          let configuration = try? JSONDecoder().decode(HostGameConfiguration.self, from: data)
    else {
      return HostGameConfiguration()
    }

    return configuration
  }

  static func save(_ configuration: HostGameConfiguration) {
    guard let data = try? JSONEncoder().encode(configuration) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
