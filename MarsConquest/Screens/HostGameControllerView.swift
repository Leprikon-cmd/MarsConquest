//
//  HostGameControllerView.swift
//
//  Зачем:
//  Даёт руководителю экспедиции один экран для порядка ходов, шахматного контроля,
//  поколений и ненавязчивого помощника физического драфта.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - компоновку карточек, подписи и цвета статусов;
//  - команды хода, паса и лимиты используют HostGameSession и не меняются отдельно от него;
//  - «Пас» оформлен непрозрачной кнопкой, чтобы читаться на любом фоне поля.
//

import SwiftUI

struct HostGameControllerView: View {
  @Binding private var localGame: LocalGameData
  @Environment(\.locale) private var locale
  @State private var now = Date()
  @State private var navigateToScore = false
  @State private var showDraftAssistant = false

  init(localGame: Binding<LocalGameData>) {
    _localGame = localGame
  }

  var body: some View {
    ZStack {
      Image(localGame.backgroundImageName)
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

      if let session = localGame.hostSession {
        ScrollView(showsIndicators: false) {
          VStack(spacing: 16) {
            header(session)
            participantBoard(session)
            controlPanel(session)
            utilityPanel(session)
          }
          .padding()
          .padding(.bottom, 24)
          .frame(maxWidth: 620)
          .frame(maxWidth: .infinity)
        }
      } else {
        ContentUnavailableView(text("Центр управления не подготовлен", "Expedition control is not ready"), systemImage: "exclamationmark.triangle")
      }
    }
    .navigationTitle(text("Центр управления", "Expedition control"))
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("host-game-controller")
    .onAppear {
      ActiveExpeditionStore.save(localGame)
    }
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
      now = date
    }
    .navigationDestination(isPresented: $navigateToScore) {
      ScoreScreen(localGame: $localGame)
    }
    .sheet(isPresented: $showDraftAssistant) {
      HostDraftAssistantView(localGame: $localGame)
    }
  }

  private func header(_ session: HostGameSession) -> some View {
    VStack(spacing: 6) {
      Text(session.isStarted
        ? text("ЭКСПЕДИЦИЯ В ПРОЦЕССЕ", "EXPEDITION IN PROGRESS")
        : text("ПУЛЬТ ГОТОВ", "CONSOLE READY"))
        .font(AppFont.font(.subheadline))
        .tracking(1.6)
        .foregroundStyle(.white.opacity(0.82))
      HStack(alignment: .firstTextBaseline) {
        Text(text("Поколение \(session.generation)", "Generation \(session.generation)"))
          .font(AppFont.font(.title2))
        Spacer()
        Text(text("Первый: \(playerName(session.firstPlayerID))", "First: \(playerName(session.firstPlayerID))"))
          .font(AppFont.font(.subheadline))
          .foregroundStyle(.white.opacity(0.9))
      }
      if session.sportsOutcome == .generationLimitReached {
        Text(text("Лимит поколений достигнут: по спортивному регламенту проиграли все. Классическая партия продолжается.", "Generation limit reached: everyone lost under the sports rules. The classic game continues."))
          .font(AppFont.font(.caption))
          .foregroundStyle(.red.opacity(0.96))
      }
    }
    .padding()
    .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .foregroundStyle(.white)
  }

  private func participantBoard(_ session: HostGameSession) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(session.configuration.usesTimer ? text("Время участников", "Participant time") : text("Очередность экспедиции", "Expedition order"))
        .font(AppFont.font(.headline))

      ForEach(Array(session.participants.enumerated()), id: \.element.id) { index, participant in
        participantRow(participant, index: index, session: session)
      }

      if !session.isStarted {
        Divider()
          .overlay(.black.opacity(0.28))
          .padding(.top, 4)

        // Подсказка относится к команде и времени, поэтому живёт в её карточке.
        Text(preparationNote(for: session))
          .font(AppFont.font(.caption))
          .foregroundStyle(.black.opacity(0.72))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func participantRow(
    _ participant: HostParticipantState,
    index: Int,
    session: HostGameSession
  ) -> some View {
    let isActive = session.phase == .turns && index == session.activePlayerIndex
    let isFirst = index == session.firstPlayerIndex
    let exceeded = session.hasExceededTime(for: participant.id, at: now)

    return HStack(spacing: 10) {
      PlayerCubeImage(colorName: player(for: participant.id)?.color ?? "")
        .frame(width: 28, height: 28)
      VStack(alignment: .leading, spacing: 2) {
        Text(playerName(participant.id))
          .font(AppFont.font(.body))
        Text(statusTitle(for: participant, isFirst: isFirst, isActive: isActive, session: session))
          .font(AppFont.font(.caption))
          .foregroundStyle(statusColor(exceeded: exceeded, isActive: isActive))
      }
      Spacer()
      if session.configuration.usesTimer {
        Text(timeTitle(for: participant.id, session: session))
          .font(AppFont.fixed(22))
          .monospacedDigit()
          .foregroundStyle(exceeded ? .red : .primary)
      } else if isFirst {
        Image(systemName: "flag.fill")
          .foregroundStyle(.red)
      }
    }
    .padding(.vertical, 7)
    .padding(.horizontal, 8)
    .background(isActive ? Color.red.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 10))
  }

  @ViewBuilder
  private func controlPanel(_ session: HostGameSession) -> some View {
    VStack(spacing: 10) {
      if !session.isStarted {
        Button {
          updateSession { $0.start(at: now) }
        } label: {
          Label(text("Начать экспедицию", "Start expedition"), systemImage: "play.fill")
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
      } else if session.phase == .intermission {
        intermissionPanel(session)
      } else if session.configuration.usesTimer {
        Button {
          updateSession { $0.endTurn(at: now) }
        } label: {
          Label(text("Завершить ход", "End turn"), systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
        .disabled(session.isPaused)

        Button {
          updateSession { $0.passCurrentPlayer(at: now) }
        } label: {
          Label(text("Пас", "Pass"), systemImage: "hand.raised.fill")
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red.opacity(0.92))
        .disabled(session.isPaused)
      } else {
        Button {
          updateSession {
            $0.finishGenerationWithoutTimer(
              recordGenerationLimitFailure: generationLimitReached(session),
              at: now
            )
          }
        } label: {
          Label(text("Завершить поколение", "End generation"), systemImage: "arrow.triangle.2.circlepath")
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .tint(.red)
  }

  private func intermissionPanel(_ session: HostGameSession) -> some View {
    VStack(spacing: 10) {
      Label(text("Межпоколенческий перерыв", "Intergeneration break"), systemImage: "leaf.arrow.circlepath")
        .font(AppFont.font(.headline))
      Text(text("Производство и добор карт происходят на столе. Когда всё готово, ведущий запускает следующее поколение.", "Production and card draws happen at the table. When ready, the host starts the next generation."))
        .font(AppFont.font(.footnote))
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)

      Button {
        updateSession {
          $0.beginNextGeneration(
            at: now,
            recordGenerationLimitFailure: generationLimitReached(session)
          )
        }
      } label: {
        Text(text("Начать следующее поколение", "Start next generation"))
          .frame(maxWidth: .infinity, minHeight: 52)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func utilityPanel(_ session: HostGameSession) -> some View {
    VStack(spacing: 10) {
      if session.isStarted, session.configuration.usesTimer, session.phase == .turns {
        Button {
          updateSession { $0.setPaused(!session.isPaused, at: now) }
        } label: {
          Label(session.isPaused ? text("Продолжить отсчёт", "Resume clock") : text("Пауза", "Pause"), systemImage: session.isPaused ? "play.fill" : "pause.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }

      HStack(spacing: 10) {
        Button {
          updateSession { $0.undoLastAction(at: now) }
        } label: {
          Label(text("Отменить", "Undo"), systemImage: "arrow.uturn.backward")
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .compactGameFieldButtonStyle(for: localGame.gameField, fontSize: 16)
        }
        .buttonStyle(.plain)
        .disabled(!session.isStarted || !session.canUndo)

        Button {
          if session.configuration.usesTimer {
            updateSession { $0.setPaused(true, at: now) }
          }
          showDraftAssistant = true
        } label: {
          Label(text("Драфт", "Draft"), systemImage: "rectangle.3.group")
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .compactGameFieldButtonStyle(for: localGame.gameField, fontSize: 16)
        }
        .buttonStyle(.plain)
      }

      Button {
        finishExpedition(outcome: session.configuration.isSportsMode ? .marsTerraformed : nil)
      } label: {
        Text(text("Марс терраформирован", "Mars terraformed"))
          // Высота соответствует пропорции рамки кнопки и не обрезает верхнюю текстуру.
          .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64)
          .gameFieldButtonStyle(for: localGame.gameField)
      }
      .buttonStyle(.plain)
      .disabled(!session.isStarted)
    }
    .padding()
  }

  private func updateSession(_ mutation: (inout HostGameSession) -> Void) {
    guard var session = localGame.hostSession else { return }
    mutation(&session)
    localGame.hostSession = session
    localGame.generation = session.generation
    ActiveExpeditionStore.save(localGame)
  }

  private func finishExpedition(outcome: SportsOutcome?) {
    updateSession { session in
      if let outcome, session.sportsOutcome == nil {
        session.markSportsOutcome(outcome, at: now)
      } else {
        session.finish(at: now)
      }
    }
    navigateToScore = true
  }

  private func player(for id: UUID?) -> LocalPlayer? {
    guard let id else { return nil }
    return localGame.players.first { $0.id == id }
  }

  private func playerName(_ id: UUID?) -> String {
    player(for: id)?.name ?? text("Участник", "Participant")
  }

  private func statusTitle(
    for participant: HostParticipantState,
    isFirst: Bool,
    isActive: Bool,
    session: HostGameSession
  ) -> String {
    if participant.didPass { return text("Пас", "Passed") }
    if isActive && !session.isPaused { return text("Ходит сейчас", "Playing now") }
    if isFirst { return text("Первый игрок", "First player") }
    return text("Ожидание", "Waiting")
  }

  private func statusColor(exceeded: Bool, isActive: Bool) -> Color {
    if exceeded { return .red }
    return isActive ? .red : .secondary
  }

  private func timeTitle(for playerID: UUID, session: HostGameSession) -> String {
    let remaining = session.remainingSeconds(for: playerID, at: now) ?? 0
    let absoluteValue = abs(remaining)
    let minutes = absoluteValue / 60
    let seconds = absoluteValue % 60
    return String(format: remaining < 0 ? "+%02d:%02d" : "%02d:%02d", minutes, seconds)
  }

  private func generationLimitReached(_ session: HostGameSession) -> Bool {
    guard let limit = session.configuration.generationLimit else { return false }
    return session.generation >= limit
  }

  private func preparationNote(for session: HostGameSession) -> String {
    if session.configuration.usesTimer {
      return text(
        "Порядок подтверждён. Время участников начнётся только после команды руководителя.",
        "Turn order is confirmed. Participant time begins only when the expedition lead starts the game."
      )
    }

    return text(
      "Порядок подтверждён. Экспедиция начнётся только после команды руководителя.",
      "Turn order is confirmed. The expedition begins only when the expedition lead starts it."
    )
  }

  private func text(_ russian: String, _ english: String) -> String {
    HostModeText.value(russian, english, locale: locale)
  }
}

//
//  HostDraftAssistantView.swift
//
//  Зачем:
//  Напоминает ведущему шаг физического драфта, не собирая и не храня карты игроков.
//
//  Что можно менять руками:
//  - число карт и направление передачи; содержимое карт не добавляется в приложение.
//
private struct HostDraftAssistantView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale
  @Binding var localGame: LocalGameData

  var body: some View {
    NavigationStack {
      VStack(spacing: 22) {
        if let draft = localGame.hostSession?.draft {
          Text(text("ДРАФТ · ШАГ \(draft.currentStep)", "DRAFT · STEP \(draft.currentStep)"))
            .font(AppFont.font(.headline))
            .tracking(1.3)

          if draft.isFinished {
            Text(text("Драфт завершён", "Draft complete"))
              .font(AppFont.font(.title2))
          } else {
            Text(draftInstruction(draft))
              .font(AppFont.font(.title3))
              .multilineTextAlignment(.center)
          }

          Button(draft.isFinished ? text("Закрыть помощник", "Close assistant") : text("Карты переданы", "Cards passed")) {
            if draft.isFinished {
              dismiss()
            } else {
              updateDraft { $0.advance() }
            }
          }
          .buttonStyle(.borderedProminent)

          Divider()
          Stepper(text("Карт в серии: \(draft.cardsAtStart)", "Cards in round: \(draft.cardsAtStart)"), value: cardsAtStartBinding, in: 2...10)
          Picker(text("Передача", "Pass direction"), selection: directionBinding) {
            ForEach(DraftDirection.allCases) { direction in
              Text(direction.title(for: locale)).tag(direction)
            }
          }
        }
      }
      .padding(24)
      .navigationTitle(text("Помощник драфта", "Draft assistant"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(text("Готово", "Done")) { dismiss() }
        }
      }
    }
    .onAppear {
      if localGame.hostSession?.draft == nil {
        updateDraft { _ in }
      }
    }
  }

  private var cardsAtStartBinding: Binding<Int> {
    Binding(
      get: { localGame.hostSession?.draft?.cardsAtStart ?? 4 },
      set: { value in
        updateDraft {
          $0.cardsAtStart = value
          $0.currentStep = min($0.currentStep, value)
        }
      }
    )
  }

  private var directionBinding: Binding<DraftDirection> {
    Binding(
      get: { localGame.hostSession?.draft?.direction ?? .left },
      set: { value in updateDraft { $0.direction = value } }
    )
  }

  private func updateDraft(_ mutation: (inout DraftAssistantState) -> Void) {
    guard var session = localGame.hostSession else { return }
    var draft = session.draft ?? DraftAssistantState()
    mutation(&draft)
    session.draft = draft
    localGame.hostSession = session
    ActiveExpeditionStore.save(localGame)
  }

  private func draftInstruction(_ draft: DraftAssistantState) -> String {
    if locale.identifier.lowercased().hasPrefix("en") {
      return "Choose one card and pass \(draft.cardsToPass) \(draft.cardsToPass == 1 ? "card" : "cards") \(draft.direction == .left ? "to the left" : "to the right")."
    }
    return "Выберите одну карту и передайте \(draft.cardsToPass) \(cardsWord(draft.cardsToPass)) \(draft.direction == .left ? "налево" : "направо")."
  }

  private func cardsWord(_ count: Int) -> String {
    switch count {
    case 1: return "карту"
    case 2...4: return "карты"
    default: return "карт"
    }
  }

  private func text(_ russian: String, _ english: String) -> String {
    HostModeText.value(russian, english, locale: locale)
  }
}
