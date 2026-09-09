//
//  TestModeSettings.swift
//
//  Зачем:
//  Хранит локальный переключатель тестового режима для быстрого заполнения новой партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - только ключ UserDefaults; менять его без миграции сбросит настройку на устройствах.
//
import Foundation

/// Локальный режим для быстрого заполнения тестовых партий.
enum TestModeSettings {
  static let isEnabledKey = "testModeEnabled"

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: isEnabledKey)
  }
}
