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
import UIKit

struct AddPlayerScreen: View {
  /// Современный механизм SwiftUI для закрытия текущего экрана после добавления игрока.
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale
  @AppStorage(TestModeSettings.isEnabledKey) private var isTestModeEnabled = false
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

  /// Аватар и отдельное селфи участника текущей партии.
  @State private var avatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @State private var avatarImageData: Data?
  @State private var showAvatarPicker = false
  @FocusState private var isNameFocused: Bool

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
  @State private var showColorPicker = false
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

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background {
        Image(localGame.backgroundImageName)
          .resizable()
          .scaledToFill()
          .clipped()
          .ignoresSafeArea()
      }
      .overlay(alignment: .top) {
        playerPreviewCard
          .padding(.horizontal, 18)
          .padding(.top, 33)
          .frame(maxWidth: .infinity, alignment: .top)
      }
      .ignoresSafeArea(.keyboard)
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Готово") {
            isNameFocused = false
          }
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
      .sheet(isPresented: $showColorPicker) {
        PlayerColorPickerView(
          colors: availableColors,
          selection: $selectedColor
        )
        .presentationDetents([.medium])
      }
      .sheet(isPresented: $showPreludePicker) {
        PreludeCardPickerView(
          prologues: availablePrologues,
          selections: selectedProloguesBinding
        )
      }
      .sheet(isPresented: $showAvatarPicker) {
        PlayerAvatarPickerView(
          selection: $avatarStyleRawValue,
          selfieData: $avatarImageData
        )
      }
      .onAppear {
        setInitialValues()
      }
  }

  private var playerPreviewCard: some View {
    PlayerEditorCardView(
      name: $name,
      selectedColor: $selectedColor,
      corporation: $corporation,
      avatarStyleRawValue: $avatarStyleRawValue,
      avatarImageData: $avatarImageData,
      selectedPrologues: selectedPrologues,
      availableSavedPlayers: availableSavedPlayers,
      hasSavedPlayers: !savedPlayers.isEmpty,
      hasSelectedSavedPlayer: selectedSavedPlayer != nil,
      isEditing: isEditing,
      hasPrelude: localGame.expansions.hasPrelude,
      isInputValid: isInputValid,
      gameField: localGame.gameField,
      locale: locale,
      nameFocus: $isNameFocused,
      onSelectNewPlayer: {
        selectedSavedPlayerID = nil
        name = ""
      },
      onSelectSavedPlayer: selectSavedPlayer,
      onChooseAvatar: {
        showAvatarPicker = true
      },
      onChooseColor: {
        showColorPicker = true
      },
      onChooseCorporation: {
        showCorporationPicker = true
      },
      onChoosePreludes: {
        showPreludePicker = true
      },
      onSave: savePlayer
    )
  }

  private var avatarStyle: OwnerAvatarStyle {
    OwnerAvatarStyle(rawValue: avatarStyleRawValue) ?? .commander
  }

  private func selectSavedPlayer(_ savedPlayer: SavedPlayer) {
    selectedSavedPlayerID = savedPlayer.objectID
    name = savedPlayer.name ?? ""

    if let preferredColor = savedPlayer.favoriteColor,
      availableColors.contains(preferredColor)
    {
      selectedColor = preferredColor
    }
  }

  /// Устанавливает стартовые значения полей выбора
  /// при первом открытии экрана.
  private func setInitialValues() {
    if let editingPlayer {
      selectedColor = editingPlayer.color
      avatarStyleRawValue = editingPlayer.avatarStyle
      avatarImageData = editingPlayer.avatarImageData
      name = editingPlayer.name
      corporation = editingPlayer.corporation
      prologue1 = editingPlayer.prologue1
      prologue2 = editingPlayer.prologue2
      return
    }

    if isTestModeEnabled, selectedColor.isEmpty {
      selectedColor = availableColors.first ?? ""
    }
    if isTestModeEnabled, corporation.isEmpty {
      corporation = availableCorporations.first {
        $0 != GameData.beginnerCorporation
      } ?? availableCorporations.first ?? ""
    }
    if isTestModeEnabled, localGame.expansions.hasPrelude {
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
      avatarStyle: avatarStyleRawValue,
      avatarImageData: avatarImageData,
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
        errorMessage = String(localized: "Этот игрок уже добавлен в текущую партию.", locale: locale)
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
    if let validationError = AddPlayerValidator.errorMessage(
      name: trimmedName,
      corporation: corporation,
      prologue1: prologue1,
      prologue2: prologue2,
      hasPrelude: localGame.expansions.hasPrelude,
      editingPlayerID: editingPlayer?.id,
      isUsingSavedPlayer: selectedSavedPlayer != nil,
      savedPlayers: Array(savedPlayers),
      localPlayers: localGame.players,
      locale: locale
    ) {
      errorMessage = validationError
      showError = true
      return false
    }

    return true
  }
}
