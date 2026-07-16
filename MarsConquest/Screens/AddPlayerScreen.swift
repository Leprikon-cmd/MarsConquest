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
  @State private var showFirstProloguePicker = false
  @State private var showSecondProloguePicker = false

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

  @ViewBuilder
  private func savedPlayersSection() -> some View {
    if !savedPlayers.isEmpty {
      Section(header: Text("Сохранённые игроки")) {
        Picker("Выберите игрока", selection: $selectedSavedPlayerID) {
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
        savedPlayersSection()

        Section(header: Text("Имя игрока")) {
          TextField("Введите имя CEO", text: $name)
            .autocapitalization(.words)
            .disabled(selectedSavedPlayer != nil)
        }

        Section(header: Text("Цвет фишки")) {
          HStack(spacing: 16) {
            Spacer(minLength: 0)
            ForEach(availableColors, id: \.self) { color in
              Button {
                selectedColor = color
              } label: {
                Circle()
                  .fill(Color.named(color))
                  .frame(width: 44, height: 44)
                  .overlay {
                    Circle()
                      .stroke(
                        selectedColor == color ? Color.primary : Color.white.opacity(0.45),
                        lineWidth: selectedColor == color ? 3 : 1
                      )
                  }
                  .overlay {
                    if selectedColor == color {
                      Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(color == "Желтый" ? .black : .white)
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

        Section(header: Text("Корпорация")) {
          Button {
            showCorporationPicker = true
          } label: {
            HStack {
              Text(corporation.isEmpty ? "Выберите корпорацию" : corporation)
                .foregroundStyle(corporation.isEmpty ? .secondary : .primary)
              Spacer()
              Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
        }

        if localGame.expansions.hasPrelude {
          Section(header: Text("Первый пролог")) {
            Button {
              showFirstProloguePicker = true
            } label: {
              HStack {
                Text(prologue1.isEmpty ? "Выберите первый пролог" : prologue1)
                  .foregroundStyle(prologue1.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
              }
            }
            .buttonStyle(.plain)
          }

          Section(header: Text("Второй пролог")) {
            Button {
              showSecondProloguePicker = true
            } label: {
              HStack {
                Text(prologue2.isEmpty ? "Выберите второй пролог" : prologue2)
                  .foregroundStyle(prologue2.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
              }
            }
            .buttonStyle(.plain)
          }
        }

      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Добавить", systemImage: "person.badge.plus") {
            addPlayer()
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
      .sheet(isPresented: $showFirstProloguePicker) {
        PreludeCardPickerView(
          prologues: availableFirstPrologues,
          selection: $prologue1
        )
      }
      .sheet(isPresented: $showSecondProloguePicker) {
        PreludeCardPickerView(
          prologues: availableSecondPrologues,
          selection: $prologue2
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
    let usedCorporations = localGame.players.map { $0.corporation }
    return corporations.filter {
      GameData.isCorporationAvailable(named: $0, for: localGame.expansions)
        && !usedCorporations.contains($0)
    }
  }

  /// Возвращает список свободных прологов,
  /// которые ещё не выбраны другими игроками текущей партии.
  private var availablePrologues: [String] {
    let usedPrologues = localGame.players.flatMap { [$0.prologue1, $0.prologue2] }
    return prologues.filter { !usedPrologues.contains($0) }
  }

  private var availableFirstPrologues: [String] {
    availablePrologues.filter { $0 != prologue2 }
  }

  private var availableSecondPrologues: [String] {
    availablePrologues.filter { $0 != prologue1 }
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

  /// Создаёт нового локального игрока и добавляет его в текущую игру,
  /// если входные данные прошли валидацию.
  private func addPlayer() {
    guard validateInput() else { return }

    // Для сохранённого игрока используем постоянный UUID его профиля.
    // Это одновременно не даёт добавить профиль дважды и позволяет
    // в будущем считать статистику по человеку, а не по тексту имени.
    let playerID = selectedSavedPlayer?.id ?? UUID()

    guard !localGame.players.contains(where: { $0.id == playerID }) else {
      errorMessage = "Этот игрок уже добавлен в текущую партию."
      showError = true
      return
    }

    let newPlayer = LocalPlayer(
      id: playerID,
      name: trimmedName,
      color: selectedColor,
      corporation: corporation,
      prologue1: localGame.expansions.hasPrelude ? prologue1 : "",
      prologue2: localGame.expansions.hasPrelude ? prologue2 : "",
      score: LocalScore()
    )

    localGame.players.append(newPlayer)
    if selectedSavedPlayer == nil {
      SavedPlayerManager.savePlayerIfNeeded(
        id: playerID,
        name: newPlayer.name,
        color: newPlayer.color,
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
      savedPlayers.contains(where: { namesMatch($0.name ?? "", trimmedName) })
    {
      errorMessage =
        "Игрок с таким именем уже существует. Выберите его из списка или добавьте уточнение к имени."
      showError = true
      return false
    }

    if localGame.players.contains(where: { namesMatch($0.name, trimmedName) }) {
      errorMessage = "Игрок с таким именем уже добавлен в текущую партию."
      showError = true
      return false
    }

    if localGame.players.contains(where: { $0.corporation == corporation }) {
      errorMessage = "Корпорация уже занята другим игроком."
      showError = true
      return false
    }

    if localGame.expansions.hasPrelude,
      localGame.players.contains(where: { $0.prologue1 == prologue1 || $0.prologue2 == prologue1 })
    {
      errorMessage = "Первый пролог уже занят другим игроком."
      showError = true
      return false
    }

    if localGame.expansions.hasPrelude,
      localGame.players.contains(where: { $0.prologue1 == prologue2 || $0.prologue2 == prologue2 })
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
