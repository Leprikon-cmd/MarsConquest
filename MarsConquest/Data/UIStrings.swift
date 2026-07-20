//
//  UIStrings.swift
//
//  Общие динамические строки, которым нужен явный Locale.
//  Статические подписи SwiftUI остаются литералами и локализуются каталогом.
//

import Foundation

enum UIStrings {

    // MARK: - Общие значения

    static func unknown(locale: Locale) -> String {
        String(localized: "Неизвестно", locale: locale)
    }

    static func noName(locale: Locale) -> String {
        String(localized: "Без имени", locale: locale)
    }

    // MARK: - Игровая информация

    static func game(locale: Locale) -> String {
        String(localized: "Игра", locale: locale)
    }
    static func date(locale: Locale) -> String {
        String(localized: "Дата", locale: locale)
    }

    static func field(locale: Locale) -> String {
        String(localized: "Поле", locale: locale)
    }

    // MARK: - Награды и достижения

    static func achievements(locale: Locale) -> String {
        String(localized: "Достижения", locale: locale)
    }
    static func awards(locale: Locale) -> String {
        String(localized: "Награды", locale: locale)
    }
}
