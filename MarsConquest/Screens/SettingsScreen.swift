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
  @Environment(\.managedObjectContext) private var viewContext
  @State private var importMessage = ""
  @State private var showImportAlert = false

  var body: some View {
    NavigationStack {
      Form {
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
      }
      Section(header: Text("Импорт")) {
        Button("Импортировать игры из JSON") {
          do {
            let count = try GameImportManager.importFromBundle(
              filename: "mars_import", in: viewContext)
            importMessage = "Импортировано игр: \(count)"
            showImportAlert = true
          } catch {
            importMessage = "Ошибка импорта: \(error.localizedDescription)"
            showImportAlert = true
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
}
