//
//  GameExpansions.swift
//
//  Зачем:
//  Хранит набор включённых дополнений для конкретной партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

//  Что можно менять руками:
//  - значения по умолчанию для новой партии; новые дополнения требуют изменений в профиле и архиве.
//
import Foundation

struct GameExpansions: Codable, Equatable {
    var hasPrelude: Bool = true
    var hasVenus: Bool = true
    var hasColonies: Bool = true
    var hasHellasElysium: Bool = true
    var hasTurmoil: Bool = true
}
