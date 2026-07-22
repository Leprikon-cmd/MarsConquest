//
//  SettingsScreen.swift
//
//  Зачем:
//  Экран глобальных настроек приложения.
//  Здесь задаются дополнения, включённые по умолчанию для новых партий.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import SwiftUI

struct SettingsScreen: View {
  /// Вызывается, когда настройки открыты во время создания конкретной партии.
  var onExpansionsChanged: ((GameExpansions) -> Void)?

  @State private var expansions = ExpansionSettingsManager.load()
  @AppStorage(MoxieSoundManager.isEnabledKey) private var isMoxieSoundEnabled = false
  @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.automatic.rawValue
  @AppStorage(OwnerBadgeStyle.storageKey) private var ownerBadgeStyleRawValue = OwnerBadgeStyle.marsFrontier.rawValue
  @AppStorage(OwnerAvatarStyle.storageKey) private var ownerAvatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale
  @State private var importMessage = ""
  @State private var showImportAlert = false

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Язык")) {
          Picker("Язык интерфейса", selection: $appLanguageRawValue) {
            ForEach(AppLanguage.allCases) { language in
              Text(language.title)
                .tag(language.rawValue)
            }
          }
        }

        Section(header: Text(badgeStyleSectionTitle)) {
          Picker(badgeStylePickerTitle, selection: $ownerBadgeStyleRawValue) {
            ForEach(OwnerBadgeStyle.allCases) { style in
              Text(style.title)
                .tag(style.rawValue)
            }
          }
        }

        Section(header: Text(avatarStyleSectionTitle)) {
          Picker(avatarStylePickerTitle, selection: $ownerAvatarStyleRawValue) {
            ForEach(OwnerAvatarStyle.builtInCases) { style in
              Text(style.title)
                .tag(style.rawValue)
            }
          }
        }

        Section(header: Text("Дополнения по умолчанию")) {
          Toggle("Прологи", isOn: binding(for: \.hasPrelude))
          Toggle("Венера", isOn: binding(for: \.hasVenus))
          Toggle("Колонии", isOn: binding(for: \.hasColonies))
          Toggle("Эллада и Элизий", isOn: binding(for: \.hasHellasElysium))
          Toggle("Кризис", isOn: binding(for: \.hasTurmoil))
        }

        Section(header: Text("Звук")) {
          Toggle("Звук МОКСИ", isOn: $isMoxieSoundEnabled)
            .onChange(of: isMoxieSoundEnabled) { _, isEnabled in
              MoxieSoundManager.shared.setEnabled(isEnabled)
            }
        }

        Section(header: Text("Импорт")) {
          Button("Импортировать игры из JSON") {
            do {
              let count = try GameImportManager.importFromBundle(
                filename: "mars_import", in: viewContext)
              importMessage = "\(String(localized: "Импортировано игр:", locale: locale)) \(count)"
              showImportAlert = true
            } catch {
              importMessage = "\(String(localized: "Ошибка импорта:", locale: locale)) \(error.localizedDescription)"
              showImportAlert = true
            }
          }
        }
      }
      .navigationTitle("Настройки")
      .alert("Импорт JSON", isPresented: $showImportAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(importMessage)
      }
    }
  }

  private func binding(for keyPath: WritableKeyPath<GameExpansions, Bool>) -> Binding<Bool> {
    Binding(
      get: { expansions[keyPath: keyPath] },
      set: { newValue in
        expansions[keyPath: keyPath] = newValue
        ExpansionSettingsManager.save(expansions)
        onExpansionsChanged?(expansions)
      }
    )
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var badgeStyleSectionTitle: String {
    isEnglish ? "Personal badge style" : "Стиль личного бейджа"
  }

  private var badgeStylePickerTitle: String {
    isEnglish ? "Style" : "Стиль"
  }

  private var avatarStyleSectionTitle: String {
    isEnglish ? "Personal avatar" : "Аватар пользователя"
  }

  private var avatarStylePickerTitle: String {
    isEnglish ? "Avatar" : "Аватар"
  }
}
