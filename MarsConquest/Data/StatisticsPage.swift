//
//  StatisticsPage.swift
//  MarsConquest
//
//  Зачем:
//  Перечисляет разделы статистики и их локализованные заголовки.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - порядок и названия вкладок; новый раздел требует отдельного экрана статистики.
//
import SwiftUI

enum StatisticsPage: CaseIterable {
    case games
    case players
    case corporations
    case prologues

    var title: LocalizedStringKey {
        switch self {
        case .games: "Игры"
        case .players: "Игроки"
        case .corporations: "Корпорации"
        case .prologues: "Прологи"
        }
    }
}
