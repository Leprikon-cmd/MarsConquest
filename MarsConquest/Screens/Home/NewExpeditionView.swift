import CoreData
import SwiftUI

/// Бывший главный экран: выбор места высадки перед началом новой экспедиции.
struct NewExpeditionView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale

  @State private var expansions = ExpansionSettingsManager.load()
  @State private var gameField = GameField.farsida.rawValue
  @State private var showGameSetup = false
  @State private var navigateToGame: Game?
  @State private var localGame = LocalGameData.empty(field: GameField.farsida.rawValue)
  @State private var didSetupNotificationObserver = false
  @AppStorage("landingSiteSwipeHintSeen") private var hasSeenLandingSiteSwipeHint = false

  private var gameFields: [GameField] {
    expansions.hasHellasElysium ? GameField.allCases : [.farsida]
  }

  private var selectedGameField: GameField {
    GameField(rawValue: gameField) ?? .farsida
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Image("fon")
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        VStack(spacing: 16) {
          Text("Место высадки")
            .font(.title2)
            .foregroundColor(.white)

          landingSiteSelector()

          Button(action: startNewGame) {
            Text("Высадка!")
              .padding()
              .frame(maxWidth: 300)
              .gameFieldButtonStyle(for: gameField)
              .shadow(radius: 5)
          }
        }
        .padding()
      }
      .navigationTitle("Новая экспедиция")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Закрыть") {
            dismiss()
          }
        }
      }
      .navigationDestination(item: $navigateToGame) { game in
        GameDetailView(game: game)
      }
    }
    .onAppear {
      expansions = ExpansionSettingsManager.load()
      prepareNotificationObserver()
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: ExpansionSettingsManager.settingsChangedNotification)
    ) { _ in
      expansions = ExpansionSettingsManager.load()

      if !gameFields.contains(where: { $0.rawValue == gameField }) {
        gameField = GameField.farsida.rawValue
      }
    }
    .fullScreenCover(isPresented: $showGameSetup) {
      AddPlayersView(localGame: $localGame)
    }
  }

  private func landingSiteSelector() -> some View {
    ZStack {
      Image(selectedGameField.imageName)
        .resizable()
        .scaledToFill()
    }
    .clipShape(Circle())
    .frame(width: 330, height: 330)
    .overlay {
      Text(selectedGameField.localizedName(for: locale))
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(.white)
    }
    .overlay(alignment: .bottom) {
      if gameFields.count > 1 && !hasSeenLandingSiteSwipeHint {
        Label("Листайте, чтобы выбрать место высадки", systemImage: "hand.draw.fill")
          .font(.subheadline.weight(.semibold))
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
            gameField = gameFields[(currentIndex + 1) % gameFields.count].rawValue
          }
          hasSeenLandingSiteSwipeHint = true
        } else if gesture.translation.width > 50 {
          withAnimation {
            gameField = gameFields[(currentIndex - 1 + gameFields.count) % gameFields.count].rawValue
          }
          hasSeenLandingSiteSwipeHint = true
        }
      }
    )
  }

private func startNewGame() {
  var newGame = LocalGameData.empty(field: gameField)

  if let owner = OwnerProfileManager.makeOwnerPlayer(
    for: newGame.expansions,
    in: viewContext
  ) {
    newGame.players = [owner]
  }

  localGame = newGame
  showGameSetup = true
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
    }

    didSetupNotificationObserver = true
  }
}
