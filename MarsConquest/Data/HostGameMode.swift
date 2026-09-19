//
//  HostGameMode.swift
//
//  Зачем:
//  Описывает состояние режима ведущего, спортивный регламент и сохранение
//  незавершённой экспедиции на одном iPhone.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - подписи правил и значения предлагаемых лимитов;
//  - порядок участников, время и итог регламента нельзя менять после старта партии.
//

import Foundation

/// Правило для случая, когда время превысили все участники спортивной экспедиции.
enum SportsAllTimedOutRule: String, Codable, CaseIterable, Identifiable {
  case smallestOvertime
  case classicalScore
  case allLose

  var id: String { rawValue }

  func title(for locale: Locale) -> String {
    switch self {
    case .smallestOvertime:
      return HostModeText.value("Наименьшее превышение", "Smallest overtime", locale: locale)
    case .classicalScore:
      return HostModeText.value("Классические очки", "Classic score", locale: locale)
    case .allLose:
      return HostModeText.value("Проиграли все", "Everyone loses", locale: locale)
    }
  }
}

/// Итог спортивного регламента не заменяет классический результат партии.
enum SportsOutcome: String, Codable {
  case marsTerraformed
  case generationLimitReached
}

/// Настройки ведущего до старта. После старта копируются в неизменяемую сессию.
struct HostGameConfiguration: Codable, Equatable {
  var isEnabled = false
  var usesTimer = false
  var timeLimitSeconds = 30 * 60
  var generationLimit: Int?
  var allTimedOutRule: SportsAllTimedOutRule = .allLose

  var isSportsMode: Bool {
    usesTimer || generationLimit != nil
  }
}

/// Состояние одного участника в порядке ведущего.
struct HostParticipantState: Codable, Equatable, Identifiable {
  let id: UUID
  var elapsedSeconds = 0
  var didPass = false

  init(id: UUID) {
    self.id = id
  }
}

/// Фаза за столом. Межпоколенческий перерыв не идёт в зачёт времени игроков.
enum HostGamePhase: String, Codable {
  case turns
  case intermission
}

/// Направление физической передачи карт: приложение только напоминает его ведущему.
enum DraftDirection: String, Codable, CaseIterable, Identifiable {
  case left
  case right

  var id: String { rawValue }

  func title(for locale: Locale) -> String {
    switch self {
    case .left: return HostModeText.value("Налево", "Left", locale: locale)
    case .right: return HostModeText.value("Направо", "Right", locale: locale)
    }
  }
}

/// Помощник драфта не хранит карты — только шаг, число оставшихся карт и направление передачи.
struct DraftAssistantState: Codable, Equatable {
  var cardsAtStart = 4
  var currentStep = 1
  var direction: DraftDirection = .left

  var cardsToPass: Int {
    max(cardsAtStart - currentStep, 0)
  }

  var isFinished: Bool {
    currentStep >= cardsAtStart
  }

  mutating func advance() {
    guard !isFinished else { return }
    currentStep += 1
  }
}

/// Снимок до последней команды ведущего — позволяет безопасно исправить случайный тап.
private struct HostGameSnapshot: Codable, Equatable {
  let participants: [HostParticipantState]
  let generation: Int
  let firstPlayerIndex: Int
  let activePlayerIndex: Int
  let phase: HostGamePhase
  let isStarted: Bool
  let isPaused: Bool
  let sportsOutcome: SportsOutcome?

  private enum CodingKeys: String, CodingKey {
    case participants, generation, firstPlayerIndex, activePlayerIndex
    case phase, isStarted, isPaused, sportsOutcome
  }

  init(
    participants: [HostParticipantState],
    generation: Int,
    firstPlayerIndex: Int,
    activePlayerIndex: Int,
    phase: HostGamePhase,
    isStarted: Bool,
    isPaused: Bool,
    sportsOutcome: SportsOutcome?
  ) {
    self.participants = participants
    self.generation = generation
    self.firstPlayerIndex = firstPlayerIndex
    self.activePlayerIndex = activePlayerIndex
    self.phase = phase
    self.isStarted = isStarted
    self.isPaused = isPaused
    self.sportsOutcome = sportsOutcome
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      participants: try container.decode([HostParticipantState].self, forKey: .participants),
      generation: try container.decode(Int.self, forKey: .generation),
      firstPlayerIndex: try container.decode(Int.self, forKey: .firstPlayerIndex),
      activePlayerIndex: try container.decode(Int.self, forKey: .activePlayerIndex),
      phase: try container.decode(HostGamePhase.self, forKey: .phase),
      // Старые черновики создавались сразу после запуска пульта.
      isStarted: try container.decodeIfPresent(Bool.self, forKey: .isStarted) ?? true,
      isPaused: try container.decode(Bool.self, forKey: .isPaused),
      sportsOutcome: try container.decodeIfPresent(SportsOutcome.self, forKey: .sportsOutcome)
    )
  }
}

/// Локальный пульт ведущего. Телефон показывает порядок и время, но не заменяет стол.
struct HostGameSession: Codable, Equatable {
  var configuration: HostGameConfiguration
  var participants: [HostParticipantState]
  var generation = 1
  var firstPlayerIndex = 0
  var activePlayerIndex = 0
  var phase: HostGamePhase = .turns
  /// Пульт готов к работе, но отсчёт начинается только по явной команде ведущего.
  var isStarted = false
  var isPaused = false
  var activeTurnStartedAt: Date?
  var sportsOutcome: SportsOutcome?
  var draft: DraftAssistantState?
  private var undoSnapshot: HostGameSnapshot?

  init(configuration: HostGameConfiguration, playerIDs: [UUID]) {
    self.configuration = configuration
    self.participants = playerIDs.map(HostParticipantState.init)
    self.activeTurnStartedAt = nil
  }

  private enum CodingKeys: String, CodingKey {
    case configuration, participants, generation, firstPlayerIndex, activePlayerIndex
    case phase, isStarted, isPaused, activeTurnStartedAt, sportsOutcome, draft, undoSnapshot
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    configuration = try container.decode(HostGameConfiguration.self, forKey: .configuration)
    participants = try container.decode([HostParticipantState].self, forKey: .participants)
    generation = try container.decodeIfPresent(Int.self, forKey: .generation) ?? 1
    firstPlayerIndex = try container.decodeIfPresent(Int.self, forKey: .firstPlayerIndex) ?? 0
    activePlayerIndex = try container.decodeIfPresent(Int.self, forKey: .activePlayerIndex) ?? 0
    phase = try container.decodeIfPresent(HostGamePhase.self, forKey: .phase) ?? .turns
    isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
    activeTurnStartedAt = try container.decodeIfPresent(Date.self, forKey: .activeTurnStartedAt)
    sportsOutcome = try container.decodeIfPresent(SportsOutcome.self, forKey: .sportsOutcome)
    draft = try container.decodeIfPresent(DraftAssistantState.self, forKey: .draft)
    undoSnapshot = try container.decodeIfPresent(HostGameSnapshot.self, forKey: .undoSnapshot)
    // До появления кнопки старта пульт начинал отсчёт сразу после создания.
    isStarted = try container.decodeIfPresent(Bool.self, forKey: .isStarted) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(configuration, forKey: .configuration)
    try container.encode(participants, forKey: .participants)
    try container.encode(generation, forKey: .generation)
    try container.encode(firstPlayerIndex, forKey: .firstPlayerIndex)
    try container.encode(activePlayerIndex, forKey: .activePlayerIndex)
    try container.encode(phase, forKey: .phase)
    try container.encode(isStarted, forKey: .isStarted)
    try container.encode(isPaused, forKey: .isPaused)
    try container.encodeIfPresent(activeTurnStartedAt, forKey: .activeTurnStartedAt)
    try container.encodeIfPresent(sportsOutcome, forKey: .sportsOutcome)
    try container.encodeIfPresent(draft, forKey: .draft)
    try container.encodeIfPresent(undoSnapshot, forKey: .undoSnapshot)
  }

  var currentPlayerID: UUID? {
    guard participants.indices.contains(activePlayerIndex) else { return nil }
    return participants[activePlayerIndex].id
  }

  var firstPlayerID: UUID? {
    guard participants.indices.contains(firstPlayerIndex) else { return nil }
    return participants[firstPlayerIndex].id
  }

  var allPlayersPassed: Bool {
    !participants.isEmpty && participants.allSatisfy(\.didPass)
  }

  var canUndo: Bool {
    undoSnapshot != nil
  }

  func elapsedSeconds(for playerID: UUID, at now: Date = .now) -> Int {
    guard let index = participants.firstIndex(where: { $0.id == playerID }) else { return 0 }
    var elapsed = participants[index].elapsedSeconds

    if isStarted,
       configuration.usesTimer,
       !isPaused,
       phase == .turns,
       index == activePlayerIndex,
       let activeTurnStartedAt {
      elapsed += max(0, Int(now.timeIntervalSince(activeTurnStartedAt)))
    }
    return elapsed
  }

  func remainingSeconds(for playerID: UUID, at now: Date = .now) -> Int? {
    guard configuration.usesTimer else { return nil }
    return configuration.timeLimitSeconds - elapsedSeconds(for: playerID, at: now)
  }

  func hasExceededTime(for playerID: UUID, at now: Date = .now) -> Bool {
    guard configuration.usesTimer else { return false }
    return elapsedSeconds(for: playerID, at: now) > configuration.timeLimitSeconds
  }

  /// Официальный старт экспедиции: только здесь запускаются часы первого участника.
  mutating func start(at now: Date = .now) {
    guard !isStarted else { return }
    rememberState()
    isStarted = true
    isPaused = false
    phase = .turns
    activeTurnStartedAt = configuration.usesTimer ? now : nil
  }

  mutating func endTurn(at now: Date = .now) {
    guard isStarted, configuration.usesTimer, phase == .turns, !isPaused else { return }
    rememberState()
    commitActiveTimer(at: now)
    guard let nextIndex = nextActiveIndex(after: activePlayerIndex) else { return }
    activePlayerIndex = nextIndex
    activeTurnStartedAt = now
  }

  mutating func passCurrentPlayer(at now: Date = .now) {
    guard isStarted, configuration.usesTimer, phase == .turns, !isPaused,
          participants.indices.contains(activePlayerIndex)
    else { return }

    rememberState()
    commitActiveTimer(at: now)
    participants[activePlayerIndex].didPass = true

    if allPlayersPassed {
      phase = .intermission
      activeTurnStartedAt = nil
      return
    }

    if let nextIndex = nextActiveIndex(after: activePlayerIndex) {
      activePlayerIndex = nextIndex
      activeTurnStartedAt = now
    }
  }

  /// Завершает поколение и при необходимости отмечает спортивный проигрыш,
  /// не прерывая классическую партию.
  mutating func finishGenerationWithoutTimer(
    recordGenerationLimitFailure: Bool = false,
    at now: Date = .now
  ) {
    guard isStarted, !configuration.usesTimer, phase == .turns else { return }
    beginNextGeneration(at: now, recordGenerationLimitFailure: recordGenerationLimitFailure)
  }

  /// Между поколениями фиксирует только спортивный статус; сам журнал продолжает игру.
  mutating func beginNextGeneration(
    at now: Date = .now,
    recordGenerationLimitFailure: Bool = false
  ) {
    guard isStarted else { return }
    rememberState()
    if recordGenerationLimitFailure, sportsOutcome == nil {
      sportsOutcome = .generationLimitReached
    }
    generation += 1
    firstPlayerIndex = nextIndex(after: firstPlayerIndex)
    activePlayerIndex = firstPlayerIndex
    participants = participants.map { participant in
      var updated = participant
      updated.didPass = false
      return updated
    }
    phase = .turns
    isPaused = false
    activeTurnStartedAt = configuration.usesTimer ? now : nil
  }

  mutating func setPaused(_ paused: Bool, at now: Date = .now) {
    guard isStarted, configuration.usesTimer, phase == .turns, paused != isPaused else { return }
    rememberState()

    if paused {
      commitActiveTimer(at: now)
      activeTurnStartedAt = nil
    } else {
      activeTurnStartedAt = now
    }
    isPaused = paused
  }

  mutating func markSportsOutcome(_ outcome: SportsOutcome, at now: Date = .now) {
    guard isStarted, sportsOutcome == nil else { return }
    rememberState()
    commitActiveTimer(at: now)
    sportsOutcome = outcome
    isPaused = true
    activeTurnStartedAt = nil
  }

  /// Останавливает часы при переходе к оформлению результатов.
  mutating func finish(at now: Date = .now) {
    guard isStarted else { return }
    rememberState()
    commitActiveTimer(at: now)
    isPaused = true
    activeTurnStartedAt = nil
  }

  mutating func undoLastAction(at now: Date = .now) {
    guard let undoSnapshot else { return }
    let currentSnapshot = snapshot
    participants = undoSnapshot.participants
    generation = undoSnapshot.generation
    firstPlayerIndex = undoSnapshot.firstPlayerIndex
    activePlayerIndex = undoSnapshot.activePlayerIndex
    phase = undoSnapshot.phase
    isStarted = undoSnapshot.isStarted
    isPaused = undoSnapshot.isPaused
    sportsOutcome = undoSnapshot.sportsOutcome
    activeTurnStartedAt = isStarted && configuration.usesTimer && !isPaused && phase == .turns ? now : nil
    self.undoSnapshot = currentSnapshot
  }

  /// Фиксирует текущее время перед уходом с экрана результатов или сохранением черновика.
  mutating func commitCurrentTime(at now: Date = .now) {
    commitActiveTimer(at: now)
  }

  private mutating func commitActiveTimer(at now: Date) {
    guard configuration.usesTimer,
          !isPaused,
          phase == .turns,
          participants.indices.contains(activePlayerIndex),
          let activeTurnStartedAt
    else { return }

    participants[activePlayerIndex].elapsedSeconds += max(0, Int(now.timeIntervalSince(activeTurnStartedAt)))
    self.activeTurnStartedAt = now
  }

  private func nextActiveIndex(after index: Int) -> Int? {
    guard !participants.isEmpty else { return nil }

    for step in 1...participants.count {
      let candidate = (index + step) % participants.count
      if !participants[candidate].didPass {
        return candidate
      }
    }
    return nil
  }

  private func nextIndex(after index: Int) -> Int {
    guard !participants.isEmpty else { return 0 }
    return (index + 1) % participants.count
  }

  private var snapshot: HostGameSnapshot {
    HostGameSnapshot(
      participants: participants,
      generation: generation,
      firstPlayerIndex: firstPlayerIndex,
      activePlayerIndex: activePlayerIndex,
      phase: phase,
      isStarted: isStarted,
      isPaused: isPaused,
      sportsOutcome: sportsOutcome
    )
  }

  private mutating func rememberState() {
    undoSnapshot = snapshot
  }
}

/// Постоянный ключ и формат спортивного регламента для будущего переноса в сеть.
enum SportsRegulationMetadata {
  static let ruleID = "marslogbook.sports"
  static let ruleVersion = "1"
}

/// Новые P5-экраны не должны показывать русский текст в английском журнале.
enum HostModeText {
  static func value(_ russian: String, _ english: String, locale: Locale) -> String {
    locale.identifier.lowercased().hasPrefix("en") ? english : russian
  }
}

/// Сохраняет только незавершённый пульт ведущего. История игр остаётся в Core Data.
enum ActiveExpeditionStore {
  private static let storageKey = "active-host-expedition-v1"

  static func save(_ game: LocalGameData) {
    guard game.hostSession != nil,
          let data = try? JSONEncoder().encode(game)
    else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }

  static func load() -> LocalGameData? {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
          let game = try? JSONDecoder().decode(LocalGameData.self, from: data),
          game.hostSession != nil
    else { return nil }
    return game
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: storageKey)
  }
}
