import Foundation

/// Локальный режим для быстрого заполнения тестовых партий.
enum TestModeSettings {
  static let isEnabledKey = "testModeEnabled"

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: isEnabledKey)
  }
}
