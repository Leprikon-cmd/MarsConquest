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

enum GameField: String, CaseIterable {
    var imageName: String {
        switch self {
        case .farsida: return "farsida"
        case .hellas: return "ellada"
        case .elysium: return "elizium"
        }
    }
    
    /// Классическое поле Tharsis.
    case farsida = "Фарсида"
    
    /// Поле Hellas.
    case hellas = "Эллада"
    
    /// Поле Elysium.
    case elysium = "Элизий"
}
