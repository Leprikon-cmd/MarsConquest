//
//  HostGameSetupView.swift
//
//  Зачем:
//  Экран регламента: руководитель устанавливает порядок игроков и спортивные правила.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - варианты времени, лимита поколений и подписи правил;
//  - запущенный регламент не изменяется: для него создаётся снимок внутри партии;
//  - фон и кнопка открытия берут оформление выбранного игрового поля;
//  - при восстановлении черновика сам возвращает пользователя в центр управления,
//    сохраняя путь назад к команде и месту высадки.
//

import SwiftUI

struct HostGameSetupView: View {
  @Binding private var localGame: LocalGameData
  @Environment(\.locale) private var locale
  @State private var orderedPlayers: [LocalPlayer]
  @State private var configuration: HostGameConfiguration
  @State private var navigateToController = false
  /// Восстановленный черновик должен открыть центр управления поверх этого экрана.
  let resumesExistingSession: Bool
  @State private var didRestoreController = false

  init(localGame: Binding<LocalGameData>, resumesExistingSession: Bool = false) {
    let game = localGame.wrappedValue
    let playerIDs = game.hostSession?.participants.map(\.id) ?? game.players.map(\.id)
    let playersInHostOrder = playerIDs.compactMap { id in
      game.players.first { $0.id == id }
    }
    _localGame = localGame
    _orderedPlayers = State(initialValue: playersInHostOrder.isEmpty ? game.players : playersInHostOrder)
    _configuration = State(initialValue: game.hostSession?.configuration ?? game.hostConfiguration)
    self.resumesExistingSession = resumesExistingSession
  }

  var body: some View {
    ZStack {
      Image(localGame.backgroundImageName)
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

      Form {
        Section {
          Text(text("Порядок экспедиции", "Expedition order"))
            .font(AppFont.font(.headline))
            .foregroundStyle(.black)

          Text(text("Первым ходит верхний участник. Удерживайте строку и расставьте команду так, как решил руководитель экспедиции.", "The top participant goes first. Reorder the team as decided by the expedition lead."))
            .font(AppFont.font(.footnote))
            .foregroundStyle(.black.opacity(0.72))

          ForEach(Array(orderedPlayers.enumerated()), id: \.element.id) { index, player in
            HStack(spacing: 12) {
              Text("\(index + 1)")
                .font(AppFont.font(.headline))
                .foregroundStyle(.red)
                .frame(width: 24)
              PlayerCubeImage(colorName: player.color)
                .frame(width: 28, height: 28)
              Text(player.name)
                .font(AppFont.font(.body))
            }
          }
          .onMove { source, destination in
            orderedPlayers.move(fromOffsets: source, toOffset: destination)
          }
        }
        .listRowBackground(regulationPanelBackground)

        Section {
          Text(text("Регламент экспедиции", "Expedition rules"))
            .font(AppFont.font(.headline))
            .foregroundStyle(.black)

          Toggle(text("Шахматный контроль", "Chess clock"), isOn: $configuration.usesTimer)

          if configuration.usesTimer {
            VStack(alignment: .leading, spacing: 6) {
              Text(text("Время на участника", "Time per participant"))
                .font(AppFont.font(.body))
              HStack(spacing: 0) {
                Picker(text("Часы", "Hours"), selection: selectedHours) {
                  ForEach(0...8, id: \.self) { hours in
                    Text(text("\(hours) ч.", "\(hours) hr")).tag(hours)
                  }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker(text("Минуты", "Minutes"), selection: selectedMinutes) {
                  ForEach(0..<60, id: \.self) { minutes in
                    Text(text("\(minutes) мин.", "\(minutes) min")).tag(minutes)
                  }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
              }
              .frame(height: 150)
              .clipped()
            }

            Picker(text("Если время превысили все", "If everyone exceeds time"), selection: $configuration.allTimedOutRule) {
              ForEach(SportsAllTimedOutRule.allCases) { rule in
                Text(rule.title(for: locale)).tag(rule)
              }
            }
          }

          Toggle(
            text("Ограничить поколения", "Limit generations"),
            isOn: Binding(
              get: { configuration.generationLimit != nil },
              set: { enabled in configuration.generationLimit = enabled ? 14 : nil }
            )
          )

          if configuration.generationLimit != nil {
            Stepper(
              text("Не позднее поколения \(configuration.generationLimit ?? 14)", "No later than generation \(configuration.generationLimit ?? 14)"),
              value: generationLimitBinding,
              in: 5...30
            )
            Text(text("Если Марс не терраформирован к концу указанного поколения, по спортивному регламенту проигрывают все.", "If Mars is not terraformed by the end of this generation, everyone loses under the sports regulation."))
              .font(AppFont.font(.footnote))
              .foregroundStyle(.secondary)
          }
        }
        .listRowBackground(regulationPanelBackground)

        Section {
          Button {
            startHostedExpedition()
          } label: {
            Text(text("Открыть центр управления", "Open expedition control"))
              .frame(maxWidth: .infinity, minHeight: 64)
              .padding(.horizontal, 16)
              .gameFieldButtonStyle(for: localGame.gameField)
          }
          .buttonStyle(.plain)
          .shadow(radius: 5)
          .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
          .listRowBackground(Color.clear)
        }
      }
      .scrollContentBackground(.hidden)
      .safeAreaPadding(.bottom, 16)
    }
    .navigationTitle(text("Регламент экспедиции", "Expedition rules"))
    .navigationDestination(isPresented: $navigateToController) {
      HostGameControllerView(localGame: $localGame)
    }
    .task(id: resumesExistingSession) {
      guard resumesExistingSession,
            !didRestoreController,
            localGame.hostSession != nil
      else { return }

      didRestoreController = true
      // После появления регламента пушим центр управления, а не показываем его модально.
      // Поэтому у восстановленного черновика сохраняется обычная кнопка «Назад».
      try? await Task.sleep(for: .milliseconds(250))
      guard !Task.isCancelled else { return }
      navigateToController = true
    }
  }

  private var generationLimitBinding: Binding<Int> {
    Binding(
      get: { configuration.generationLimit ?? 14 },
      set: { configuration.generationLimit = $0 }
    )
  }

  /// Тот же материал, что у карточки «Время участников» в центре управления.
  /// Без собственного скругления: Form сам объединяет строки в один цельный блок.
  private var regulationPanelBackground: some View {
    Rectangle()
      .fill(.ultraThinMaterial)
  }

  private var selectedHours: Binding<Int> {
    Binding(
      get: { configuration.timeLimitSeconds / 3_600 },
      set: { updateTimeLimit(hours: $0, minutes: configuration.timeLimitSeconds % 3_600 / 60) }
    )
  }

  private var selectedMinutes: Binding<Int> {
    Binding(
      get: { configuration.timeLimitSeconds % 3_600 / 60 },
      set: { updateTimeLimit(hours: configuration.timeLimitSeconds / 3_600, minutes: $0) }
    )
  }

  private func updateTimeLimit(hours: Int, minutes: Int) {
    configuration.timeLimitSeconds = max(hours * 3_600 + minutes * 60, 60)
  }

  private func startHostedExpedition() {
    configuration.isEnabled = true
    localGame.hostConfiguration = configuration
    localGame.hostSession = HostGameSession(
      configuration: configuration,
      playerIDs: orderedPlayers.map(\.id)
    )
    localGame.generation = 1
    ActiveExpeditionStore.save(localGame)
    navigateToController = true
  }

  private func text(_ russian: String, _ english: String) -> String {
    HostModeText.value(russian, english, locale: locale)
  }
}
