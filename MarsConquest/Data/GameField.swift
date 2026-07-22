//
//  GameField.swift
//
//  Зачем:
//  Единый список игровых полей Марса.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation
import SwiftUI

enum GameField: String, CaseIterable {
    /// Постоянный ключ поля, не зависящий от языка интерфейса.
    var referenceID: String {
        switch self {
        case .farsida: return "board.tharsis"
        case .hellas: return "board.hellas"
        case .elysium: return "board.elysium"
        }
    }

    var imageName: String {
        switch self {
        case .farsida: return "farsida"
        case .hellas: return "ellada"
        case .elysium: return "elizium"
        }
    }

    /// Отображаемое название зависит только от языка интерфейса.
    /// `rawValue` остаётся русским, потому что используется в старых записях и Core Data.
    func localizedName(for locale: Locale) -> String {
        guard locale.identifier.lowercased().hasPrefix("en") else {
            return rawValue
        }

        switch self {
        case .farsida:
            return "Tharsis"
        case .hellas:
            return "Hellas"
        case .elysium:
            return "Elysium"
        }
    }

    /// Находит поле по новому ключу или по сохранённому в старых партиях русскому названию.
    static func localizedName(
        persistedName: String?,
        referenceID: String?,
        locale: Locale
    ) -> String {
        let field = resolve(persistedName: persistedName, referenceID: referenceID)

        return field?.localizedName(for: locale)
            ?? persistedName
            ?? UIStrings.unknown(locale: locale)
    }

    /// Распознаёт постоянный ключ, текущее и старые написания названий поля.
    static func resolve(persistedName: String?, referenceID: String?) -> GameField? {
        if let referenceID, let field = allCases.first(where: { $0.referenceID == referenceID }) {
            return field
        }

        let normalizedName = persistedName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalizedName {
        case farsida.rawValue.lowercased(), "tharsis":
            return .farsida
        case hellas.rawValue.lowercased(), "элада", "hellas":
            return .hellas
        case elysium.rawValue.lowercased(), "elysium":
            return .elysium
        default:
            return nil
        }
    }
    
    /// Классическое поле Tharsis.
    case farsida = "Фарсида"
    
    /// Поле Hellas.
    case hellas = "Эллада"
    
    /// Поле Elysium.
    case elysium = "Элизий"
}
