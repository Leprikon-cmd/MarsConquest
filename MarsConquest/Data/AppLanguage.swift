//
//  AppLanguage.swift
//  MarsConquest
//
//  Хранит выбранный язык интерфейса.
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
