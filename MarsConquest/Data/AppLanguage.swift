//
//  AppLanguage.swift
//  MarsConquest
//
//  Зачем:
//  Хранит выбранный язык интерфейса и его локаль.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - список поддерживаемых языков; новый язык требует перевода String Catalog.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
  case automatic
  case russian = "ru"
  case english = "en"

  static let storageKey = "app.language"

  var id: String { rawValue }

  var locale: Locale {
    switch self {
    case .automatic:
      return .autoupdatingCurrent
    case .russian:
      return Locale(identifier: "ru")
    case .english:
      return Locale(identifier: "en")
    }
  }

  var title: LocalizedStringKey {
    switch self {
    case .automatic:
      return "Автоматически"
    case .russian:
      return "Русский"
    case .english:
      return "English"
    }
  }
}
