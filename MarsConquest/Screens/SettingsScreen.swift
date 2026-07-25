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

import CoreData
import SwiftUI
import UIKit

struct SettingsScreen: View {
  /// Вызывается, когда настройки открыты во время создания конкретной партии.
  var onExpansionsChanged: ((GameExpansions) -> Void)?

  /// Профиль нужен только в настройках из бортового журнала — для проверки старых партий.
  var ownerProfile: OwnerProfile?

  @State private var expansions = ExpansionSettingsManager.load()
  @AppStorage(MoxieSoundManager.isEnabledKey) private var isMoxieSoundEnabled = false
  @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.automatic.rawValue
  @AppStorage(OwnerAvatarStyle.storageKey) private var ownerAvatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @AppStorage(TestModeSettings.isEnabledKey) private var isTestModeEnabled = false
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale
  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>
  @State private var importMessage = ""
  @State private var showImportAlert = false

  private var journalNavigationClearance: CGFloat {
    UIDevice.current.userInterfaceIdiom == .phone ? 84 : 0
  }

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

        Section(header: Text(testModeSectionTitle)) {
          Toggle(testModeToggleTitle, isOn: $isTestModeEnabled)
          Text(testModeDescription)
            .font(AppFont.font(.footnote))
            .foregroundStyle(.secondary)
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

        if hasHistoricalParticipationsToReview, let ownerProfile {
          Section(header: Text("Бортовой журнал")) {
            NavigationLink {
              HistoricalParticipationLinkView(ownerProfile: ownerProfile)
            } label: {
              Label("Проверить прошлые партии", systemImage: "person.text.rectangle")
            }
          }
        }
      }
      .navigationTitle("Настройки")
      // Form не знает о нижней навигации родительского журнала.
      // Добавляем резерв только для iPhone, не меняя iPad-разметку.
      .safeAreaPadding(.bottom, journalNavigationClearance)
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

  private var hasHistoricalParticipationsToReview: Bool {
    guard let ownerID = ownerProfile?.savedPlayerID else { return false }

    return games.contains { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains {
        ($0.savedPlayerID == nil || $0.savedPlayerID == ownerID) && $0.id != ownerID
      }
    }
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var avatarStyleSectionTitle: String {
    isEnglish ? "Personal avatar" : "Аватар пользователя"
  }

  private var avatarStylePickerTitle: String {
    isEnglish ? "Avatar" : "Аватар"
  }

  private var testModeSectionTitle: String {
    isEnglish ? "Testing" : "Тестирование"
  }

  private var testModeToggleTitle: String {
    isEnglish ? "Test mode" : "Тестовый режим"
  }

  private var testModeDescription: String {
    isEnglish
      ? "Automatically fills a color, corporation, and two preludes when adding players."
      : "Автоматически подставляет цвет, корпорацию и два пролога при добавлении игроков."
  }
}
