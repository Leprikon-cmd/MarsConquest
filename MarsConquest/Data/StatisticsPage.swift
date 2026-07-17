//
//  StatisticsPage.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
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
