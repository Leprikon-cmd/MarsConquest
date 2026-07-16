//
//  AddPlayerScreen.swift
//
//  Зачем:
//  Экран ввода данных нового игрока перед добавлением его в локальную партию.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - ввод имени игрока
//  - выбор корпорации
//  - выбор двух прологов
//  - проверка корректности ввода
//  - добавление игрока в LocalGameData
//

import CoreData
import SwiftUI

struct AddPlayerScreen: View {
  /// Современный механизм SwiftUI для закрытия текущего экрана после добавления игрока.
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(
    entity: SavedPlayer.entity(),
    sortDescriptors: [
      NSSortDescriptor(key: "isFavorite", ascending: false),
      NSSortDescriptor(key: "name", ascending: true),
    ]
  ) private var savedPlayers: FetchedResults<SavedPlayer>

  /// Справочник корпораций. Его заполняет InitialDataLoader при запуске приложения.
  @FetchRequest(entity: Corporation.entity(), sortDescriptors: [])
  private var corporationReferences: FetchedResults<Corporation>

  /// Справочник прологов. Его заполняет InitialDataLoader при запуске приложения.
  @FetchRequest(entity: Prologue.entity(), sortDescriptors: [])
  private var prologueReferences: FetchedResults<Prologue>

  /// Свободные цвета фишек для текущей партии.
  let availableColors: [String]

  /// Локальная модель текущей создаваемой игры.
  @Binding var localGame: LocalGameData

  /// При наличии значения экран редактирует существующего игрока,
  /// а не добавляет нового.
  let editingPlayer: LocalPlayer?

  /// Цвет фишки нового игрока.
  @State private var selectedColor: String = ""

  /// Имя нового игрока.
  @State private var name: String = ""

  /// Выбранная корпорация.
  @State private var corporation: String = ""

  /// Первый выбранный пролог.
  @State private var prologue1: String = ""

  /// Второй выбранный пролог.
  @State private var prologue2: String = ""

  /// Флаг показа окна ошибки.
  @State private var showError = false

  /// Текст ошибки валидации.
  @State private var errorMessage = ""

  @State private var selectedSavedPlayerID: NSManagedObjectID?
  @State private var showCorporationPicker = false
  @State private var showPreludePicker = false

  /// Доступный список корпораций из единого справочника Core Data.
  private var corporations: [String] {
    corporationReferences
      .compactMap(\.name)
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }

  /// Доступный список прологов из единого справочника Core Data.
  private var prologues: [String] {
    prologueReferences
      .compactMap(\.name)
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }

  /// Сохранённые профили, которые ещё не участвуют в текущей партии.
  /// Сравниваем UUID профиля, а не имя: в приложении могут быть разные люди
  /// с одинаковым именем.
  private var availableSavedPlayers: [SavedPlayer] {
    savedPlayers.filter { savedPlayer in
      guard let profileID = savedPlayer.id else { return true }
      return !localGame.players.contains { $0.id == profileID }
    }
  }

  /// Профиль, выбранный в списке сохранённых игроков.
  private var selectedSavedPlayer: SavedPlayer? {
    guard let selectedSavedPlayerID else { return nil }
    return savedPlayers.first { $0.objectID == selectedSavedPlayerID }
  }

  private var isEditing: Bool {
    editingPlayer != nil
  }

  @ViewBuilder
  private func savedPlayersSection() -> some View {
    if !savedPlayers.isEmpty {
      Section(header: Text("Выбрать сохранённого CEO")) {
        Picker("Сохранённый CEO", selection: $selectedSavedPlayerID) {
          Text("Новый игрок").tag(nil as NSManagedObjectID?)

          ForEach(availableSavedPlayers, id: \.objectID) { savedPlayer in
            let displayName = savedPlayer.name ?? UIStrings.noName
            Text(displayName).tag(savedPlayer.objectID as NSManagedObjectID?)
          }
        }
        .onChange(of: selectedSavedPlayerID) { _, newValue in
          guard let newValue,
            let savedPlayer = availableSavedPlayers.first(where: { $0.objectID == newValue })
          else {
            return
          }

          name = savedPlayer.name ?? ""
        }
      }
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Цвет фишки")) {
          HStack(spacing: 16) {
            Spacer(minLength: 0)
            ForEach(availableColors, id: \.self) { color in
              Button {
                selectedColor = color
              } label: {
                Image(systemName: "cube.fill")
                  .font(.system(size: 38, weight: .medium))
                  .symbolRenderingMode(.hierarchical)
                  .foregroundStyle(Color.named(color))
                  .frame(width: 48, height: 48)
                  .overlay {
                    RoundedRectangle(cornerRadius: 10)
                      .stroke(
                        selectedColor == color ? Color.primary : Color.white.opacity(0.45),
                        lineWidth: selectedColor == color ? 3 : 1
                      )
                  }
                  .overlay {
                    if selectedColor == color {
                      Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color == "Желтый" ? .black : .white)
                        .padding(3)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: 13, y: -13)
                    }
                  }
              }
              .buttonStyle(.plain)
              .accessibilityLabel("Фишка: \(color)")
            }
            Spacer(minLength: 0)
          }
          .padding(.vertical, 4)
        }

        Section(header: Text("Имя игрока")) {
          TextField("Введите имя CEO", text: $name)
            .autocapitalization(.words)
            .disabled(selectedSavedPlayer != nil)
        }

        if !isEditing {
          savedPlayersSection()
        }

        Section(header: Text("Корпорация")) {
          Button {
            showCorporationPicker = true
          } label: {
            HStack {
              Text(corporation.isEmpty ? "Выберите корпорацию" : corporation)
                .foregroundStyle(corporation.isEmpty ? .secondary : .primary)
              Spacer()
              Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityHint("Открывает выбор корпорации")
        }

        if localGame.expansions.hasPrelude {
          Section(header: Text("Прологи")) {
            Button {
              showPreludePicker = true
            } label: {
              HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(selectedPrologues.isEmpty ? "Выберите два пролога" : "Выбрано: \(selectedPrologues.count) из 2")
                    .foregroundStyle(selectedPrologues.isEmpty ? .secondary : .primary)

                  if !selectedPrologues.isEmpty {
                    Text(selectedPrologues.joined(separator: " • "))
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                      .lineLimit(2)
                  }
                }
                Spacer()
                Image(systemName: "rectangle.stack.fill")
                  .font(.title3)
                  .foregroundStyle(.secondary)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Открывает выбор прологов")
          }
        }

      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(isEditing ? "Сохранить" : "Добавить", systemImage: isEditing ? "checkmark" : "person.badge.plus") {
            savePlayer()
          }
          .disabled(!isInputValid)
        }
      }
      .alert(isPresented: $showError) {
        Alert(
          title: Text("Ошибка"),
          message: Text(errorMessage),
          dismissButton: .default(Text("OK"))
        )
      }
      .sheet(isPresented: $showCorporationPicker) {
        CorporationCardPickerView(
          corporations: availableCorporations,
          selection: $corporation
        )
      }
      .sheet(isPresented: $showPreludePicker) {
        PreludeCardPickerView(
          prologues: availablePrologues,
          selections: selectedProloguesBinding
        )
      }
      .onAppear {
        setInitialValues()
      }
    }
  }

  /// Устанавливает стартовые значения полей выбора
  /// при первом открытии экрана.
  private func setInitialValues() {
    if let editingPlayer {
      selectedColor = editingPlayer.color
      name = editingPlayer.name
      corporation = editingPlayer.corporation
      prologue1 = editingPlayer.prologue1
      prologue2 = editingPlayer.prologue2
      return
    }

    if selectedColor.isEmpty {
      selectedColor = availableColors.first ?? ""
    }
    if corporation.isEmpty {
      corporation = availableCorporations.first ?? ""
    }
    if localGame.expansions.hasPrelude {
      if prologue1.isEmpty {
        prologue1 = availablePrologues.first ?? ""
      }
      if prologue2.isEmpty {
        prologue2 = availablePrologues.first { $0 != prologue1 } ?? ""
      }
    }
  }

  /// Возвращает список свободных корпораций,
  /// которые ещё не выбраны другими игроками текущей партии.
  private var availableCorporations: [String] {
    let usedCorporations = localGame.players
      .filter { $0.id != editingPlayer?.id }
      .map(\.corporation)
    return corporations.filter {
      GameData.isCorporationAvailable(named: $0, for: localGame.expansions)
        && !usedCorporations.contains($0)
    }
  }

  /// Возвращает список свободных прологов,
  /// которые ещё не выбраны другими игроками текущей партии.
  private var availablePrologues: [String] {
    let usedPrologues = localGame.players
      .filter { $0.id != editingPlayer?.id }
      .flatMap { [$0.prologue1, $0.prologue2] }
    return prologues.filter { !usedPrologues.contains($0) }
  }

  /// Два выбранных пролога отображаются и редактируются как единый набор,
  /// но сохраняются в существующие поля локальной модели.
  private var selectedPrologues: [String] {
    [prologue1, prologue2].filter { !$0.isEmpty }
  }

  private var selectedProloguesBinding: Binding<[String]> {
    Binding(
      get: { selectedPrologues },
      set: { newSelection in
        prologue1 = newSelection.first ?? ""
        prologue2 = newSelection.dropFirst().first ?? ""
      }
    )
  }

  /// Проверяет, заполнены ли обязательные поля формы
  /// и не совпадают ли два пролога у одного игрока.
  private var isInputValid: Bool {
    guard !trimmedName.isEmpty,
      !selectedColor.isEmpty,
      !corporation.isEmpty
    else {
      return false
    }

    guard localGame.expansions.hasPrelude else {
      return true
    }

    return !prologue1.isEmpty && !prologue2.isEmpty && prologue1 != prologue2
  }

  /// Имя без случайных пробелов в начале и конце.
  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Добавляет нового игрока или сохраняет изменения открытого игрока.
  private func savePlayer() {
    guard validateInput() else { return }

    let playerID = editingPlayer?.id ?? selectedSavedPlayer?.id ?? UUID()

    let player = LocalPlayer(
      id: playerID,
      name: trimmedName,
      color: selectedColor,
      corporation: corporation,
      prologue1: localGame.expansions.hasPrelude ? prologue1 : "",
      prologue2: localGame.expansions.hasPrelude ? prologue2 : "",
      score: LocalScore()
    )

    if let editingPlayer,
      let index = localGame.players.firstIndex(where: { $0.id == editingPlayer.id })
    {
      localGame.players[index] = player
      SavedPlayerManager.updatePlayer(
        id: playerID,
        name: player.name,
        color: player.color,
        in: viewContext
      )
    } else {
      guard !localGame.players.contains(where: { $0.id == playerID }) else {
        errorMessage = "Этот игрок уже добавлен в текущую партию."
        showError = true
        return
      }

      localGame.players.append(player)
    }

    if !isEditing && selectedSavedPlayer == nil {
      SavedPlayerManager.savePlayerIfNeeded(
        id: playerID,
        name: player.name,
        color: player.color,
        in: viewContext
      )
    }
    dismiss()

  }

  /// Выполняет дополнительную проверку уникальности корпорации и прологов
  /// среди уже добавленных игроков.
  ///
  /// - Returns: true, если данные корректны и игрок может быть добавлен
  private func validateInput() -> Bool {
    guard !trimmedName.isEmpty else {
      errorMessage = "Введите имя игрока."
      showError = true
      return false
    }

    // Новое имя должно быть уникально во всём списке сохранённых профилей.
    // Это не даст статистике смешать двух разных людей с одним именем.
    if selectedSavedPlayer == nil,
      savedPlayers.contains(where: {
        $0.id != editingPlayer?.id && namesMatch($0.name ?? "", trimmedName)
      })
    {
      errorMessage =
        "Игрок с таким именем уже существует. Выберите его из списка или добавьте уточнение к имени."
      showError = true
      return false
    }

    if localGame.players.contains(where: {
      $0.id != editingPlayer?.id && namesMatch($0.name, trimmedName)
    }) {
      errorMessage = "Игрок с таким именем уже добавлен в текущую партию."
      showError = true
      return false
    }

    if localGame.players.contains(where: {
      $0.id != editingPlayer?.id && $0.corporation == corporation
    }) {
      errorMessage = "Корпорация уже занята другим игроком."
      showError = true
      return false
    }

    if localGame.expansions.hasPrelude,
      localGame.players.contains(where: {
        $0.id != editingPlayer?.id && ($0.prologue1 == prologue1 || $0.prologue2 == prologue1)
      })
    {
      errorMessage = "Первый пролог уже занят другим игроком."
      showError = true
      return false
    }

    if localGame.expansions.hasPrelude,
      localGame.players.contains(where: {
        $0.id != editingPlayer?.id && ($0.prologue1 == prologue2 || $0.prologue2 == prologue2)
      })
    {
      errorMessage = "Второй пролог уже занят другим игроком."
      showError = true
      return false
    }

    return true
  }

  /// Сравнивает имена без учёта регистра и лишних пробелов по краям.
  private func namesMatch(_ first: String, _ second: String) -> Bool {
    first.trimmingCharacters(in: .whitespacesAndNewlines)
      .caseInsensitiveCompare(second.trimmingCharacters(in: .whitespacesAndNewlines))
      == .orderedSame
  }
}
