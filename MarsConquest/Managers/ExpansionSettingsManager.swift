//
//  ExpansionSettingsManager.swift
//
//  Зачем:
//  Хранит глобальные настройки дополнений по умолчанию
//  через UserDefaults.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation

struct ExpansionSettingsManager {

    static let settingsChangedNotification = Notification.Name("ExpansionSettingsChanged")

    private enum Keys {
        static let hasPrelude = "expansion.hasPrelude"
        static let hasVenus = "expansion.hasVenus"
        static let hasColonies = "expansion.hasColonies"
        static let hasHellasElysium = "expansion.hasHellasElysium"
        static let hasTurmoil = "expansion.hasTurmoil"
    }

    static func load() -> GameExpansions {
        let defaults = UserDefaults.standard

        return GameExpansions(
            hasPrelude: defaults.object(forKey: Keys.hasPrelude) as? Bool ?? true,
            hasVenus: defaults.object(forKey: Keys.hasVenus) as? Bool ?? true,
            hasColonies: defaults.object(forKey: Keys.hasColonies) as? Bool ?? true,
            hasHellasElysium: defaults.object(forKey: Keys.hasHellasElysium) as? Bool ?? true,
            hasTurmoil: defaults.object(forKey: Keys.hasTurmoil) as? Bool ?? true
        )
    }

    static func save(_ expansions: GameExpansions) {
        let defaults = UserDefaults.standard

        defaults.set(expansions.hasPrelude, forKey: Keys.hasPrelude)
        defaults.set(expansions.hasVenus, forKey: Keys.hasVenus)
        defaults.set(expansions.hasColonies, forKey: Keys.hasColonies)
        defaults.set(expansions.hasHellasElysium, forKey: Keys.hasHellasElysium)
        defaults.set(expansions.hasTurmoil, forKey: Keys.hasTurmoil)

        NotificationCenter.default.post(
            name: settingsChangedNotification,
            object: nil
        )
    }
}
