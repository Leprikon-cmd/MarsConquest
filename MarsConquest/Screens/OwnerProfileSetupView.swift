import CoreData
import SwiftUI

/// Первый запуск: создаёт владельца журнала и его настройки по умолчанию.
struct OwnerProfileSetupView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale

  @FetchRequest(
    entity: SavedPlayer.entity(),
    sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
  ) private var savedPlayers: FetchedResults<SavedPlayer>

  let onCompleted: () -> Void

  @State private var selectedSavedPlayerID: NSManagedObjectID?
  @State private var nickname = ""
  @State private var realName = ""
  @State private var hasBaseGame = false
  @State private var expansions = ExpansionSettingsManager.load()
  @State private var errorMessage = ""
  @State private var showError = false

  private var selectedSavedPlayer: SavedPlayer? {
    guard let selectedSavedPlayerID else { return nil }
    return savedPlayers.first { $0.objectID == selectedSavedPlayerID }
  }

  private var trimmedNickname: String {
    nickname.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var trimmedRealName: String {
    realName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text("Создайте журнал")
            .font(.headline)
          Text("Выберите сохранённого игрока или создайте новый профиль владельца.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if !savedPlayers.isEmpty {
          Section("Сохранённый игрок") {
            Picker("Сохранённый игрок", selection: $selectedSavedPlayerID) {
              Text("Новый профиль").tag(nil as NSManagedObjectID?)
              ForEach(savedPlayers, id: \.objectID) { player in
                Text(playerTitle(for: player)).tag(player.objectID as NSManagedObjectID?)
              }
            }
          }
        }

        Section("Личный журнал") {
          TextField("Ник", text: $nickname)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          TextField("Имя (необязательно)", text: $realName)
        }

        Section("Моя коллекция") {
          Toggle("Базовая игра", isOn: $hasBaseGame)

Text("Дополнения")
  .font(.footnote.weight(.semibold))
  .foregroundStyle(.secondary)
Toggle("Прологи", isOn: expansionBinding(for: \.hasPrelude))
Toggle("Венера", isOn: expansionBinding(for: \.hasVenus))
Toggle("Колонии", isOn: expansionBinding(for: \.hasColonies))
Toggle("Эллада и Элизий", isOn: expansionBinding(for: \.hasHellasElysium))
Toggle("Кризис", isOn: expansionBinding(for: \.hasTurmoil))
        }

        Section {
          Button("Создать журнал", action: saveOwnerProfile)
            .frame(maxWidth: .infinity)
            .disabled(trimmedNickname.isEmpty)
        }
      }
      .navigationTitle("Личный журнал")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: selectedSavedPlayerID) { _, _ in
        fillProfileFieldsFromSelection()
      }
      .alert("Ошибка", isPresented: $showError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
    }
  }

  private func expansionBinding(for keyPath: WritableKeyPath<GameExpansions, Bool>) -> Binding<Bool> {
    Binding(
      get: { expansions[keyPath: keyPath] },
      set: { expansions[keyPath: keyPath] = $0 }
    )
  }

  private func fillProfileFieldsFromSelection() {
    guard let player = selectedSavedPlayer else {
      nickname = ""
      realName = ""
      return
    }

    nickname = player.nickname ?? player.name ?? ""
    realName = player.realName ?? ""
  }

  private func saveOwnerProfile() {
    guard !trimmedNickname.isEmpty else { return }

    let profileToUpdate = selectedSavedPlayer
    if savedPlayers.contains(where: { player in
      player.objectID != profileToUpdate?.objectID
        && normalized(player.nickname ?? player.name ?? "") == normalized(trimmedNickname)
        && normalized(player.realName ?? "") == normalized(trimmedRealName)
    }) {
      errorMessage = String(
        localized: "Профиль с таким ником и именем уже существует.",
        locale: locale
      )
      showError = true
      return
    }

    let player: SavedPlayer
    if let profileToUpdate {
      player = profileToUpdate
    } else {
      player = SavedPlayer(context: viewContext)
      player.id = UUID()
      player.name = trimmedNickname
      player.favoriteColor = GameData.colors.first ?? "Красный"
      player.isFavorite = false
      player.createdAt = Date()
    }

    let playerID = player.id ?? UUID()
    player.id = playerID
    player.nickname = trimmedNickname
    player.realName = trimmedRealName.isEmpty ? nil : trimmedRealName
    player.updatedAt = Date()

    do {
      _ = try OwnerProfileManager.save(
        ownerPlayerID: playerID,
        collection: OwnerCollectionSettings(hasBaseGame: hasBaseGame, expansions: expansions),
        in: viewContext
      )
      ExpansionSettingsManager.save(expansions)
      onCompleted()
    } catch {
      errorMessage = "\(String(localized: "Не удалось создать журнал:", locale: locale)) \(error.localizedDescription)"
      showError = true
    }
  }

  private func normalized(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func playerTitle(for player: SavedPlayer) -> String {
    let nickname = player.nickname ?? player.name ?? ""
    guard let realName = player.realName, !realName.isEmpty else { return nickname }
    return "\(nickname) — \(realName)"
  }
}
