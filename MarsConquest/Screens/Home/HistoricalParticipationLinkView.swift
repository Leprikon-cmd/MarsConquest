import CoreData
import SwiftUI

/// Ручная привязка старых записей к профилю владельца журнала.
/// Старые партии группируются по имени: одно имя связывает все одноимённые записи.
struct HistoricalParticipationLinkView: View {
  @Environment(\.managedObjectContext) private var viewContext

  let ownerProfile: OwnerProfile

  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>

  @State private var selectedNames = Set<String>()
  @State private var searchText = ""
  @State private var unlinkingName: String?
  @State private var showError = false
  @State private var errorMessage = ""

  private var ownerID: UUID? {
    ownerProfile.savedPlayerID
  }

  private var allPlayers: [Player] {
    games.flatMap { $0.players?.allObjects as? [Player] ?? [] }
  }

  /// Имя служит ключом для импортированных партий, где ещё не было SavedPlayer.
  private var candidateNames: [HistoricalPlayerName] {
    groupedNames(
      from: allPlayers.filter { $0.savedPlayerID == nil && $0.id != ownerID }
    )
  }

  /// Показываем связанные ранее имена, чтобы связь можно было исправить целиком.
  private var linkedNames: [HistoricalPlayerName] {
    guard let ownerID else { return [] }

    return groupedNames(
      from: allPlayers.filter { $0.savedPlayerID == ownerID && $0.id != ownerID }
    )
  }

  private var visibleCandidateNames: [HistoricalPlayerName] {
    candidateNames.filter { name in
      searchText.isEmpty || name.displayName.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var unlinkingGroup: HistoricalPlayerName? {
    guard let unlinkingName else { return nil }
    return linkedNames.first { $0.id == unlinkingName }
  }

  var body: some View {
    List {
      if visibleCandidateNames.isEmpty && linkedNames.isEmpty {
        ContentUnavailableView(
          "Нет записей для привязки",
          systemImage: "checkmark.circle",
          description: Text("Все доступные записи уже проверены.")
        )
      }

      if !visibleCandidateNames.isEmpty {
        Section("Имена из прошлых партий") {
          ForEach(visibleCandidateNames) { name in
            Button {
              toggleSelection(for: name)
            } label: {
              nameRow(name, isSelected: selectedNames.contains(name.id))
            }
            .buttonStyle(.plain)
          }
        }
      }

      if !linkedNames.isEmpty {
        Section("Уже связанные имена") {
          ForEach(linkedNames) { name in
            Button {
              unlinkingName = name.id
            } label: {
              nameRow(name, isSelected: true)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .navigationTitle("Прошлые партии")
    .searchable(text: $searchText, prompt: "Поиск по имени")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Привязать", action: linkSelectedNames)
          .disabled(selectedNames.isEmpty)
      }
    }
    .alert("Убрать связь?", isPresented: Binding(
      get: { unlinkingGroup != nil },
      set: { isPresented in
        if !isPresented {
          unlinkingName = nil
        }
      }
    )) {
      Button("Отвязать", role: .destructive) {
        if let unlinkingGroup {
          unlink(group: unlinkingGroup)
        }
      }
      Button("Отмена", role: .cancel) {
        unlinkingName = nil
      }
    } message: {
      Text("Все старые записи с этим именем перестанут учитываться в личном журнале.")
    }
    .alert("Ошибка", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  private func nameRow(_ name: HistoricalPlayerName, isSelected: Bool) -> some View {
    HStack(spacing: 12) {
      Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        .font(.title3)

      Text(name.displayName)
        .font(.body.weight(.semibold))

      Spacer()
    }
    .contentShape(Rectangle())
  }

  private func groupedNames(from players: [Player]) -> [HistoricalPlayerName] {
    let groupedPlayers = Dictionary(grouping: players) { normalizedName($0.name) }

    return groupedPlayers.compactMap { normalizedName, players in
      guard !normalizedName.isEmpty, let displayName = players.first?.name else { return nil }
      return HistoricalPlayerName(
        id: normalizedName,
        displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
        players: players
      )
    }
    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
  }

  private func normalizedName(_ name: String?) -> String {
    (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func toggleSelection(for name: HistoricalPlayerName) {
    if selectedNames.contains(name.id) {
      selectedNames.remove(name.id)
    } else {
      selectedNames.insert(name.id)
    }
  }

  private func linkSelectedNames() {
    guard let ownerID else { return }

    for group in candidateNames where selectedNames.contains(group.id) {
      for player in group.players {
        player.savedPlayerID = ownerID
      }
    }

    saveChanges {
      selectedNames.removeAll()
    }
  }

  private func unlink(group: HistoricalPlayerName) {
    for player in group.players {
      player.savedPlayerID = nil
    }

    saveChanges {
      unlinkingName = nil
    }
  }

  private func saveChanges(onSuccess: @escaping () -> Void) {
    do {
      try viewContext.save()
      onSuccess()
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
  }
}

private struct HistoricalPlayerName: Identifiable {
  let id: String
  let displayName: String
  let players: [Player]
}
