//
//  AddPlayersView.swift
//  MarsConquest
//
//  Зачем:
//  Формирует команду новой экспедиции и открывает карточку владельца сразу после высадки.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - порядок карточек, интервалы и фон экрана; правила состава команды не менять без проверки запуска.
//  - при восстановлении черновика автоматически возвращается путь к регламенту, а не создаётся новая партия.
//

import SwiftUI

struct AddPlayersView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  /// Локальная модель текущей создаваемой игры.
  @Binding var localGame: LocalGameData

  /// Показывает форму добавления нового игрока.
  @State private var showAddPlayer = false

  /// Игрок, которого пользователь открыл для редактирования.
  @State private var playerToEdit: LocalPlayer?
  @State private var showPlayerEditor = false
  /// Отличает автоматическое первое открытие владельца от обычного редактирования карточки.
  @State private var isPresentingInitialOwner = false

  /// В сценарии новой экспедиции сразу открываем карточку первого игрока.
  let opensFirstPlayerOnAppear: Bool
  /// Восстанавливает путь «команда → регламент → центр управления» для черновика.
  let resumesHostExpedition: Bool

  @State private var didPresentInitialPlayer = false
  @State private var didRestoreHostSetup = false

  /// Показывает настройки дополнений для текущей незавершённой партии.
  @State private var showSettings = false

  /// Показывает выбор доступных для партии колоний.
  @State private var showColonyPicker = false

  /// Флаг перехода на экран ввода очков.
  @State private var navigateToScoreScreen = false
  /// Экран настройки очередности и регламента для необязательного режима ведущего.
  @State private var navigateToHostSetup = false

  /// Доступные цвета игроков.
  private let colors = GameData.colors

  private var availableColors: [String] {
    let usedColors = Set(localGame.players.map(\.color))
    return colors.filter { !usedColors.contains($0) }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Image(localGame.backgroundImageName)
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        VStack(spacing: 0) {
          addPlayerButton
          playersListView
            .frame(maxHeight: .infinity)
          bottomControls
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: teamContentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .accessibilityIdentifier("expedition-team-screen")
      .navigationTitle("Команда экспедиции")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            // Возврат к месту высадки не удаляет сохранённый черновик экспедиции.
            dismiss()
          } label: {
            Image(systemName: "chevron.backward")
              .font(AppFont.font(.body))
              .frame(width: 44, height: 44)
          }
          .accessibilityLabel("Вернуться к выбору игрового поля")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showSettings = true
          } label: {
            Image(systemName: "gearshape.fill")
              .font(AppFont.font(.body))
              .frame(width: 44, height: 44)
          }
          .accessibilityLabel("Настройки дополнений")
        }
      }
      .navigationDestination(isPresented: $showAddPlayer) {
        AddPlayerScreen(
          availableColors: availableColors,
          localGame: $localGame,
          editingPlayer: nil,
          isInitialOwnerEditor: false
        )
      }
      .navigationDestination(isPresented: $showPlayerEditor) {
        if let player = playerToEdit {
          AddPlayerScreen(
            availableColors: availableColors(for: player),
            localGame: $localGame,
            editingPlayer: player,
            isInitialOwnerEditor: isPresentingInitialOwner
          )
          .onDisappear {
            playerToEdit = nil
            isPresentingInitialOwner = false
          }
        }
      }
      .sheet(isPresented: $showSettings) {
        SettingsScreen(
          onExpansionsChanged: { updatedExpansions in
          localGame.expansions = updatedExpansions

          localGame.players = localGame.players.map { player in
            var updatedPlayer = player

            if !GameData.isCorporationAvailable(
              named: updatedPlayer.corporation,
              for: updatedExpansions
            ) {
              updatedPlayer.corporation = TestModeSettings.isEnabled
                ? GameData.beginnerCorporation
                : ""
            }

            if !updatedExpansions.hasPrelude {
              updatedPlayer.prologue1 = ""
              updatedPlayer.prologue2 = ""
            }

            return updatedPlayer
          }

            if !updatedExpansions.hasColonies {
              localGame.colonies = []
            }
          },
          initialHostConfiguration: localGame.hostConfiguration,
          onHostConfigurationChanged: { updatedConfiguration in
            localGame.hostConfiguration = updatedConfiguration
          }
        )
      }
      .sheet(isPresented: $showColonyPicker) {
        ColonyCardPickerView(
          colonies: GameData.colonies,
          selection: $localGame.colonies,
          maximumSelection: colonyLimit
        )
      }
      .navigationDestination(isPresented: $navigateToScoreScreen) {
        ScoreScreen(localGame: $localGame)
      }
      .navigationDestination(isPresented: $navigateToHostSetup) {
        HostGameSetupView(
          localGame: $localGame,
          resumesExistingSession: resumesHostExpedition
        )
      }
      // `AddPlayersView` появляется внутри fullScreenCover. Открываем карточку
      // после завершения анимации этого перехода — иначе iOS игнорирует второй
      // запрос на модальное представление.
      .task(id: opensFirstPlayerOnAppear) {
        guard opensFirstPlayerOnAppear else { return }

        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        presentInitialPlayerIfNeeded()
      }
      .task(id: resumesHostExpedition) {
        guard resumesHostExpedition,
              !didRestoreHostSetup,
              localGame.hostSession != nil
        else { return }

        didRestoreHostSetup = true
        // Переход выполняется после показа экрана команды, чтобы SwiftUI сохранил
        // настоящий стек навигации и кнопки «Назад» на каждом уровне.
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        navigateToHostSetup = true
      }
      .onChange(of: localGame.players.count) { _, _ in
        localGame.colonies = Array(localGame.colonies.prefix(colonyLimit))
      }
    }
    .ignoresSafeArea(.keyboard)
  }

  private var addPlayerButton: some View {
    Button {
      showAddPlayer = true
    } label: {
      Label("Добавить игрока", systemImage: "person.badge.plus")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .gameFieldButtonStyle(for: localGame.gameField)
    }
    .buttonStyle(.plain)
    .disabled(availableColors.isEmpty)
    .opacity(availableColors.isEmpty ? 0.55 : 1)
    .padding(.horizontal, 20)
    .padding(.top, addPlayerTopPadding)
    .padding(.bottom, 8)
    .accessibilityHint(
      availableColors.isEmpty ? "Свободных цветов не осталось" : "Открыть форму нового игрока")
    .accessibilityIdentifier("add-player-button")
  }

  /// Навигационная панель занимает собственную безопасную зону на всех устройствах.
  private var addPlayerTopPadding: CGFloat {
    25
  }

  /// Не растягиваем список команды на всю ширину планшета.
  private var teamContentMaxWidth: CGFloat {
    horizontalSizeClass == .regular ? 720 : .infinity
  }

  private var playersListView: some View {
    List {
      ForEach(localGame.players) { player in
        Button {
          playerToEdit = player
          isPresentingInitialOwner = false
          showPlayerEditor = true
        } label: {
          playerRowView(player: player)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .onDelete(perform: deletePlayer)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private var bottomControls: some View {
    VStack(spacing: 10) {
      if localGame.expansions.hasColonies {
        coloniesButton
      }

      startGameButton
    }
    .padding(.horizontal, 20)
  }

  private var startGameButton: some View {
    Button {
      if localGame.hostConfiguration.isEnabled {
        navigateToHostSetup = true
      } else {
        navigateToScoreScreen = true
      }
    } label: {
      Text("Начать партию")
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 16)
        .gameFieldButtonStyle(for: localGame.gameField)
    }
    .buttonStyle(.plain)
    .contentShape(RoundedRectangle(cornerRadius: 8))
    .disabled(localGame.players.isEmpty)
    .opacity(localGame.players.isEmpty ? 0.55 : 1)
    .accessibilityIdentifier("start-game-button")
  }

  private var colonyLimit: Int {
    switch localGame.players.count {
    case 0:
      return 0
    case 1:
      return 3
    case 2:
      return 5
    default:
      return min(localGame.players.count + 2, GameData.colonies.count)
    }
  }

  /// Для редактируемого игрока его текущий цвет остаётся доступным.
  private func availableColors(for player: LocalPlayer) -> [String] {
    let usedColors = Set(
      localGame.players
        .filter { $0.id != player.id }
        .map(\.color)
    )
    return colors.filter { !usedColors.contains($0) }
  }

  private var coloniesButton: some View {
    Button {
      showColonyPicker = true
    } label: {
      HStack {
        Label("Добавить колонии", systemImage: "globe.americas.fill")
        Spacer()
        Text("\(localGame.colonies.count)/\(colonyLimit)")
          .monospacedDigit()
      }
      .frame(maxWidth: .infinity, minHeight: 64)
      .padding(.horizontal, 16)
      .gameFieldButtonStyle(for: localGame.gameField)
    }
    .buttonStyle(.plain)
    .contentShape(RoundedRectangle(cornerRadius: 8))
    .disabled(colonyLimit == 0)
    .opacity(colonyLimit == 0 ? 0.55 : 1)
    .accessibilityHint(
      colonyLimit == 0
        ? "Сначала добавьте участника экспедиции"
        : "Выбрать до \(colonyLimit) колоний для партии"
    )
  }

  private func playerRowView(player: LocalPlayer) -> some View {
    HStack(spacing: 10) {
      PlayerCubeImage(colorName: player.color)
        .frame(width: 30, height: 30)
        .accessibilityLabel("Фишка: \(player.color)")

      Text(player.name)
        .font(AppFont.font(.headline))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      CorporationCardImage(corporationName: player.corporation)
        .frame(width: 99, height: 69)

      if !player.prologue1.isEmpty || !player.prologue2.isEmpty {
        VStack(spacing: 3) {
          if !player.prologue1.isEmpty {
            PreludeCardImage(prologueName: player.prologue1)
              .frame(width: 49, height: 33)
          }

          if !player.prologue2.isEmpty {
            PreludeCardImage(prologueName: player.prologue2)
              .frame(width: 49, height: 33)
          }
        }
      }
    }
    .padding(10)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(playerSummary(for: player))
  }

  private func playerSummary(for player: LocalPlayer) -> String {
    let prologues = [player.prologue1, player.prologue2]
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
    return [player.name, player.corporation, prologues]
      .filter { !$0.isEmpty }
      .joined(separator: ". ")
  }

  private func deletePlayer(at offsets: IndexSet) {
    localGame.players.remove(atOffsets: offsets)
  }

  private func presentInitialPlayerIfNeeded() {
    guard !didPresentInitialPlayer,
          let owner = localGame.players.first
    else {
      return
    }
    didPresentInitialPlayer = true
    playerToEdit = owner
    isPresentingInitialOwner = true
    showPlayerEditor = true
  }

}
