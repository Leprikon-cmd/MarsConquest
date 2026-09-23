//
//  NewExpeditionView.swift
//
//  Зачем:
//  Оформляет выбор места высадки и запуск новой экспедиции.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - изображения посадочных площадок, размеры рамки и интервалы; имена Assets указаны в свойствах экрана.
//  - проверка черновика сверяет его с архивом, чтобы записанная партия не предлагалась к продолжению.
//  - смена поля до старта сохраняет команду и регламент; после старта место высадки блокируется.
//
import CoreData
import SwiftUI
import UIKit

/// Бывший главный экран: выбор места высадки перед началом новой экспедиции.
struct NewExpeditionView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale

  @State private var expansions = ExpansionSettingsManager.load()
  @State private var gameField = GameField.farsida.rawValue
  @State private var showGameSetup = false
  @State private var navigateToGame: Game?
  @State private var localGame = LocalGameData.empty(field: GameField.farsida.rawValue)
  /// Незавершённая партия ведущего предлагается к продолжению после перезапуска приложения.
  @State private var resumableHostGame: LocalGameData?
  @State private var landingBackgroundName = "Tarsis_BG1"
  @State private var didSetupNotificationObserver = false
  @State private var showHostResumePrompt = false
  /// Восстанавливает навигационную цепочку команды, регламента и центра управления.
  @State private var resumesHostExpedition = false
  /// Не открывает карточку владельца повторно при возврате к незавершённой команде.
  @State private var resumesTeamDraft = false
  @AppStorage("landingSiteSwipeHintSeen") private var hasSeenLandingSiteSwipeHint = false

  private var gameFields: [GameField] {
    expansions.hasHellasElysium ? GameField.allCases : [.farsida]
  }

  private var selectedGameField: GameField {
    GameField(rawValue: gameField) ?? .farsida
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var selectedGameFieldFrameName: String {
    switch selectedGameField {
    case .farsida:
      return "tharsis-blank"
    case .hellas:
      return "hellas-blank"
    case .elysium:
      return "elysium-blank"
    }
  }

  private var selectedGameFieldTitleFont: Font {
    switch selectedGameField {
    case .farsida:
      return .custom("RussoOne-Regular", size: 24).weight(.bold)
    case .hellas:
      return .custom("Forum", size: 28).weight(.bold)
    case .elysium:
      return .custom("Jura-Bold", size: 25)
    }
  }

  private var selectedGameFieldSubtitleFont: Font {
    switch selectedGameField {
    case .farsida:
      return .custom("RussoOne-Regular", size: 9)
    case .hellas:
      return .custom("Forum", size: 10)
    case .elysium:
      return .custom("Jura-Regular", size: 9)
    }
  }

  private var isPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
  }

  /// До старта можно сменить только поле и фон, не теряя собранную команду.
  private var canEditLandingSiteForDraft: Bool {
    !localGame.players.isEmpty && localGame.hostSession?.isStarted != true
  }

  private var isLandingSiteLocked: Bool {
    localGame.hostSession?.isStarted == true
  }

  private var landingTitle: String {
    if canEditLandingSiteForDraft {
      return isEnglish ? "Change Landing Site" : "Изменить место высадки"
    }
    return isEnglish ? "Landing Site" : "Место высадки"
  }

  private var landingActionTitle: String {
    if isLandingSiteLocked { return isEnglish ? "Expedition Already Started" : "Экспедиция уже начата" }
    if canEditLandingSiteForDraft { return isEnglish ? "Confirm New Board" : "Подтвердить новое поле" }
    return isEnglish ? "Land!" : "Высадка!"
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Image(landingBackgroundName)
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()
          .id(landingBackgroundName)
          .transition(.opacity)

        Group {
          if isPhone {
            GeometryReader { proxy in
              phoneExpeditionControls(in: proxy.size)
            }
          } else {
            ScrollView(showsIndicators: false) {
              expeditionControls
                .padding()
            }
          }
        }
        .accessibilityIdentifier("new-expedition-screen")
      }
      .navigationDestination(item: $navigateToGame) { game in
        GameDetailView(game: game)
      }
    }
    .onAppear {
      expansions = ExpansionSettingsManager.load()
      if canEditLandingSiteForDraft {
        // Возвращаем исходный фон черновика: без выбора другого поля ничего не меняется.
        gameField = localGame.gameField
        landingBackgroundName = localGame.backgroundImageName
      } else {
        landingBackgroundName = randomBackgroundName(for: selectedGameField)
      }
      prepareNotificationObserver()
      presentSavedHostGameIfNeeded()
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: ExpansionSettingsManager.settingsChangedNotification)
    ) { _ in
      expansions = ExpansionSettingsManager.load()

      if !gameFields.contains(where: { $0.rawValue == gameField }) {
        gameField = GameField.farsida.rawValue
        landingBackgroundName = randomBackgroundName(for: .farsida)
      }
    }
    .fullScreenCover(isPresented: $showGameSetup, onDismiss: {
      // При возврате к высадке снова показываем выбор действий с сохранённым черновиком.
      resumesHostExpedition = false
      resumesTeamDraft = false
      resumableHostGame = nil
    }) {
      AddPlayersView(
        localGame: $localGame,
        opensFirstPlayerOnAppear: !resumesHostExpedition && !resumesTeamDraft,
        resumesHostExpedition: resumesHostExpedition
      )
    }
    .alert(isEnglish ? "Unfinished expedition" : "Незавершённая экспедиция", isPresented: $showHostResumePrompt) {
      Button(isEnglish ? "Resume expedition" : "Продолжить экспедицию") {
        guard let resumableHostGame else { return }
        localGame = resumableHostGame
        resumesHostExpedition = true
        showGameSetup = true
      }
      Button(isEnglish ? "Discard draft" : "Убрать черновик", role: .destructive) {
        ActiveExpeditionStore.clear()
        resumableHostGame = nil
      }
      Button(isEnglish ? "Later" : "Позже", role: .cancel) {}
    } message: {
      Text(isEnglish
        ? "The journal has saved the turn order, generations, and participant clocks. You can continue from the same point."
        : "В журнале сохранены порядок хода, поколения и время участников. Их можно продолжить с того же места.")
    }
  }

  private var expeditionControls: some View {
    VStack(spacing: 16) {
      Spacer(minLength: 16)

      Text(landingTitle)
        .font(AppFont.font(.title2))
        .foregroundColor(.white)

      landingSiteTitleFrame()

      landingSiteSelector()

      if canEditLandingSiteForDraft {
        Text("Состав команды и регламент сохранятся")
          .font(AppFont.font(.footnote))
          .foregroundStyle(.white.opacity(0.9))
      }

      Button(action: startNewGame) {
        Text(landingActionTitle)
          .font(AppFont.font(.title2))
          .frame(maxWidth: 340, minHeight: 68)
          .gameFieldButtonStyle(for: gameField, fontSize: 26)
          .shadow(radius: 5)
      }
      .disabled(isLandingSiteLocked)
      .opacity(isLandingSiteLocked ? 0.55 : 1)
      .padding(.top, 32)
      .accessibilityIdentifier("start-expedition-button")

      Spacer(minLength: 16)
    }
    .adaptiveContentWidth(640)
  }

  /// Телефонная композиция: название в верхней безопасной зоне, планета по
  /// центру экрана, а кнопка ниже неё с исходной пропорцией фоновой картинки.
  private func phoneExpeditionControls(in size: CGSize) -> some View {
    let screenWidth = validDimension(size.width)
    let screenHeight = validDimension(size.height)
    let availableWidth = max(screenWidth - 36, 0)
    let planetSize = min(availableWidth, 350)
    let planetTopOffset = max(142, screenHeight / 2 - planetSize / 2)

    return ZStack(alignment: .top) {
      VStack(spacing: 0) {
        Spacer().frame(height: planetTopOffset)

        landingSiteSelector(size: planetSize)

        if canEditLandingSiteForDraft {
          Text("Состав команды и регламент сохранятся")
            .font(AppFont.font(.footnote))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.top, 8)
        }

        Button(action: startNewGame) {
          Text(landingActionTitle)
            .frame(width: 320, height: 60)
            .gameFieldButtonStyle(for: gameField, fontSize: 26)
            .shadow(radius: 5)
        }
        .disabled(isLandingSiteLocked)
        .opacity(isLandingSiteLocked ? 0.55 : 1)
        .padding(.top, canEditLandingSiteForDraft ? 12 : 34)
        .accessibilityIdentifier("start-expedition-button")

        Spacer(minLength: 0)
      }

      VStack(spacing: 6) {
        Text(landingTitle)
          .font(AppFont.fixed(30))
          .foregroundStyle(.white)

        landingSiteTitleFrame(width: min(availableWidth, 350))
      }
      .padding(.top, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func landingSiteTitleFrame(width: CGFloat = 350) -> some View {
    let safeWidth = validDimension(width)

    return Image(selectedGameFieldFrameName)
      .resizable()
      .scaledToFill()
      .frame(width: safeWidth, height: 72)
      .clipped()
      .overlay {
        VStack(spacing: 1) {
          Text(selectedGameField.localizedName(for: locale).uppercased(with: locale))
            .font(selectedGameFieldTitleFont)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .shadow(color: .black.opacity(0.28), radius: 1, y: 1)

          Text(selectedGameField.localizedSubtitle(for: locale))
            .font(selectedGameFieldSubtitleFont)
            .tracking(2.2)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
        .foregroundStyle(.black)
        .frame(width: max(safeWidth - 108, 0), height: 58, alignment: .center)
      }
      .accessibilityHidden(true)
  }

  private func landingSiteSelector(size: CGFloat = 330) -> some View {
    let safeSize = validDimension(size)

    return ZStack {
      Image(selectedGameField.imageName)
        .resizable()
        .scaledToFill()
    }
    .clipShape(Circle())
    .frame(width: safeSize, height: safeSize)
    .overlay(alignment: .bottom) {
      if gameFields.count > 1 && !hasSeenLandingSiteSwipeHint {
        Label("Листайте, чтобы выбрать место высадки", systemImage: "hand.draw.fill")
          .font(AppFont.font(.subheadline))
          .foregroundStyle(.primary)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial, in: Capsule())
          .padding(.bottom, 18)
          .allowsHitTesting(false)
          .transition(.opacity)
      }
    }
    .gesture(
      DragGesture().onEnded { gesture in
        let currentIndex = gameFields.firstIndex(where: { $0.rawValue == gameField }) ?? 0

        if gesture.translation.width < -50 {
          withAnimation {
            selectGameField(gameFields[(currentIndex + 1) % gameFields.count])
          }
          hasSeenLandingSiteSwipeHint = true
        } else if gesture.translation.width > 50 {
          withAnimation {
            selectGameField(gameFields[(currentIndex - 1 + gameFields.count) % gameFields.count])
          }
          hasSeenLandingSiteSwipeHint = true
        }
      }
    )
    .accessibilityIdentifier("landing-site-selector")
  }

  /// GeometryReader может кратковременно передавать нечисловой размер во время
  /// перестройки представления. SwiftUI не принимает такой размер для frame.
  private func validDimension(_ value: CGFloat) -> CGFloat {
    value.isFinite ? max(value, 0) : 0
  }

  private func selectGameField(_ field: GameField) {
    gameField = field.rawValue
    landingBackgroundName = randomBackgroundName(for: field)
  }

  private func randomBackgroundName(for field: GameField) -> String {
    let number = Int.random(in: 1...6)

    switch field {
    case .farsida:
      return "Tarsis_BG\(number)"
    case .hellas:
      return "Hellas\(number)"
    case .elysium:
      return "Elysium\(number)"
    }
  }

private func startNewGame() {
  guard !isLandingSiteLocked else { return }

  // Возврат со страницы команды — это пауза настройки, а не отмена партии.
  // Новое поле применяется только после явного подтверждения этой кнопкой.
  if canEditLandingSiteForDraft {
    applyLandingSiteToDraft()
    resumesTeamDraft = true
    showGameSetup = true
    return
  }

  var newGame = LocalGameData.empty(
    field: gameField,
    backgroundImageName: landingBackgroundName
  )

  if let owner = OwnerProfileManager.makeOwnerPlayer(
    for: newGame.expansions,
    in: viewContext
  ) {
    newGame.players = [owner]
  }

  localGame = newGame
  resumesTeamDraft = false
  showGameSetup = true
}

private func applyLandingSiteToDraft() {
  guard localGame.gameField != gameField || localGame.backgroundImageName != landingBackgroundName else {
    return
  }

  localGame.gameField = gameField
  localGame.backgroundImageName = landingBackgroundName
  // Достижения и награды принадлежат игровому полю. До записи их можно выбрать заново.
  localGame.achievements = []
  localGame.awards = []

  if localGame.hostSession != nil {
    ActiveExpeditionStore.save(localGame)
  }
}


  private func prepareNotificationObserver() {
    guard !didSetupNotificationObserver else { return }

    NotificationCenter.default.addObserver(
      forName: Notification.Name("NavigateToStatistics"),
      object: nil,
      queue: .main
    ) { notification in
      guard let game = notification.object as? Game else { return }
      navigateToGame = game
      showGameSetup = false
      resumableHostGame = nil
    }

    didSetupNotificationObserver = true
  }

  private func presentSavedHostGameIfNeeded() {
    guard resumableHostGame == nil,
          let savedGame = ActiveExpeditionStore.load()
    else { return }

    // Второй предохранитель: если запись уже находится в Core Data, черновик
    // не имеет права вернуть пользователя в завершённую экспедицию.
    guard !isArchived(savedGame) else {
      ActiveExpeditionStore.clear()
      return
    }

    // До первого старта это ещё редактируемый черновик команды и регламента.
    // Возвращаем его на посадочную страницу без принудительного прыжка в центр управления.
    if savedGame.hostSession?.isStarted != true {
      localGame = savedGame
      resumesTeamDraft = true
      gameField = savedGame.gameField
      landingBackgroundName = savedGame.backgroundImageName
      return
    }

    resumableHostGame = savedGame
    showHostResumePrompt = true
  }

  private func isArchived(_ localGame: LocalGameData) -> Bool {
    let request = NSFetchRequest<Game>(entityName: "Game")
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", localGame.id as CVarArg)
    return ((try? viewContext.count(for: request)) ?? 0) > 0
  }
}
