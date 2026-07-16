//
//  AddPlayersView.swift
//  MarsConquest
//
//  Экран формирования команды новой экспедиции.
//

import SwiftUI

struct AddPlayersView: View {
  @Environment(\.dismiss) private var dismiss

  /// Локальная модель текущей создаваемой игры.
  @Binding var localGame: LocalGameData

  /// Выбранный фон команды. Новый создаётся при каждом новом входе в настройку партии.
  @State private var backgroundImageName = "bg_Mars\(Int.random(in: 1...11))"

  /// Показывает форму добавления нового игрока.
  @State private var showAddPlayer = false

  /// Игрок, которого пользователь открыл для редактирования.
  @State private var playerToEdit: LocalPlayer?

  /// Показывает настройки дополнений для текущей незавершённой партии.
  @State private var showSettings = false

  /// Показывает выбор доступных для партии колоний.
  @State private var showColonyPicker = false

  /// Флаг перехода на экран ввода очков.
  @State private var navigateToScoreScreen = false

  /// Подтверждение отмены незавершённой партии.
  @State private var showDiscardConfirmation = false

  /// Доступные цвета игроков.
  private let colors = GameData.colors

  private var availableColors: [String] {
    let usedColors = Set(localGame.players.map(\.color))
    return colors.filter { !usedColors.contains($0) }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Image(backgroundImageName)
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        VStack(spacing: 0) {
          addPlayerButton
          playersListView
        }

        VStack {
          Spacer()
          bottomControls
        }
        .padding(.bottom, 12)
      }
      .navigationTitle("Команда экспедиции")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            discardGame()
          } label: {
            Image(systemName: "xmark")
              .font(.body.weight(.semibold))
              .frame(width: 36, height: 36)
              .background(.ultraThinMaterial, in: Circle())
          }
          .accessibilityLabel("Отменить создание партии")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showSettings = true
          } label: {
            Image(systemName: "gearshape.fill")
              .font(.body.weight(.semibold))
              .frame(width: 36, height: 36)
              .background(.ultraThinMaterial, in: Circle())
          }
          .accessibilityLabel("Настройки дополнений")
        }
      }
      .sheet(isPresented: $showAddPlayer) {
        AddPlayerScreen(
          availableColors: availableColors,
          localGame: $localGame,
          editingPlayer: nil
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
      .sheet(item: $playerToEdit) { player in
        AddPlayerScreen(
          availableColors: availableColors(for: player),
          localGame: $localGame,
          editingPlayer: player
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showSettings) {
        SettingsScreen { updatedExpansions in
          localGame.expansions = updatedExpansions

          localGame.players = localGame.players.map { player in
            var updatedPlayer = player

            if !GameData.isCorporationAvailable(
              named: updatedPlayer.corporation,
              for: updatedExpansions
            ) {
              updatedPlayer.corporation = ""
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
        }
      }
      .sheet(isPresented: $showColonyPicker) {
        ColonyCardPickerView(
          colonies: GameData.colonies,
          selection: $localGame.colonies,
          maximumSelection: colonyLimit
        )
      }
      .alert("Отменить создание партии?", isPresented: $showDiscardConfirmation) {
        Button("Продолжить настройку", role: .cancel) {}
        Button("Отменить партию", role: .destructive) {
          dismiss()
        }
      } message: {
        Text("Добавленные игроки будут удалены из незавершённой партии.")
      }
      .navigationDestination(isPresented: $navigateToScoreScreen) {
        ScoreScreen(localGame: $localGame)
      }
      .onChange(of: localGame.players.count) { _, _ in
        localGame.colonies = Array(localGame.colonies.prefix(colonyLimit))
      }
    }
  }

  private var addPlayerButton: some View {
    Button {
      showAddPlayer = true
    } label: {
      Label("Добавить игрока", systemImage: "person.badge.plus")
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
          Image("button8")
            .resizable()
            .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .disabled(availableColors.isEmpty)
    .opacity(availableColors.isEmpty ? 0.55 : 1)
    .padding(.horizontal, 20)
    .padding(.top, 25)
    .padding(.bottom, 8)
    .accessibilityHint(
      availableColors.isEmpty ? "Свободных цветов не осталось" : "Открыть форму нового игрока")
  }

  private var playersListView: some View {
    List {
      ForEach(localGame.players) { player in
        Button {
          playerToEdit = player
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
    .contentMargins(.bottom, bottomControlsHeight, for: .scrollContent)
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

  /// Высота нижнего слоя: список прокручивается выше кнопок, но экран не сжимается.
  private var bottomControlsHeight: CGFloat {
    localGame.expansions.hasColonies ? 126 : 64
  }

  private var startGameButton: some View {
    Button {
      navigateToScoreScreen = true
    } label: {
      Text("Начать партию")
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, 16)
        .background(
          Image("button8")
            .resizable()
            .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .contentShape(RoundedRectangle(cornerRadius: 8))
    .disabled(localGame.players.isEmpty)
    .opacity(localGame.players.isEmpty ? 0.55 : 1)
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
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 52)
      .padding(.horizontal, 16)
      .background(
        Image("button8")
          .resizable()
          .scaledToFill()
      )
      .clipShape(RoundedRectangle(cornerRadius: 8))
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
      Image(systemName: "cube.fill")
        .font(.title2)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(Color.named(player.color))
        .frame(width: 30)
        .accessibilityLabel("Фишка: \(player.color)")

      Text(player.name)
        .font(.headline)
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

  private func discardGame() {
    if localGame.players.isEmpty {
      dismiss()
    } else {
      showDiscardConfirmation = true
    }
  }
}
