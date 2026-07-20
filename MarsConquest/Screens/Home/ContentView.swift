//
//  ContentView.swift
//
//  Зачем:
//  Главный экран приложения MarsConquest.
//  Отсюда пользователь выбирает игровое поле, начинает новую игру
//  и переходит к основным разделам приложения.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - отображение главного экрана
//  - выбор карты Марса
//  - запуск новой игры
//  - открытие экрана добавления игроков
//  - переход к статистике
//

import CoreData
import SwiftUI

struct ContentView: View {
  /// Контекст CoreData из окружения SwiftUI.
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale

  /// Настройки
  @State private var expansions = ExpansionSettingsManager.load()

  /// Текущая выбранная карта Марса.
  @State private var gameField = GameField.farsida.rawValue

  /// Флаг открытия окна настройки новой игры.
  @State private var showGameSetup = false

  /// Выбранная игра для перехода на экран деталей.
  @State private var navigateToGame: Game? = nil

  /// Локальная модель новой игры, которая заполняется до сохранения в CoreData.
  @State private var localGame = LocalGameData.empty(field: GameField.farsida.rawValue)

  /// Подписываемся один раз
  @State private var didSetupNotificationObserver = false

  /// Подсказка о горизонтальном свайпе нужна только при первом знакомстве с выбором поля.
  @AppStorage("landingSiteSwipeHintSeen") private var hasSeenLandingSiteSwipeHint = false

  /// Доступные игровые поля.
  private var gameFields: [GameField] {
    expansions.hasHellasElysium ? GameField.allCases : [.farsida]
  }
  private var selectedGameField: GameField {
    GameField(rawValue: gameField) ?? .farsida
  }

  var body: some View {
    TabView {
      NavigationStack {
        ZStack {
          Image("fon")
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)

          VStack(spacing: 16) {
            Text("Покорение Марса")
              .font(.largeTitle)
              .bold()
              .foregroundColor(.white)
              .padding(.top, 20)

            Text("Место высадки")
              .font(.title2)
              .foregroundColor(.white)

            ZStack {
              Image(selectedGameField.imageName)
                .resizable()
                .scaledToFill()
            }
            .clipShape(Circle())
            .frame(width: 360, height: 360)
            .overlay(
              Text(selectedGameField.localizedName(for: locale))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            )
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
                    gameField =
                      gameFields[(currentIndex - 1 + gameFields.count) % gameFields.count].rawValue
                  }
                  hasSeenLandingSiteSwipeHint = true
                }
              }
            )
            .padding(.vertical, 20)

            Button(action: startNewGame) {
              Text("Высадка!")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 300)
                .background(
                  Image("button7")
                    .resizable()
                    .scaledToFill()
                )
                .cornerRadius(10)
                .shadow(radius: 5)
            }

          }
          .padding()
        }
        .navigationTitle("Главная")
        .navigationBarHidden(true)
        .navigationDestination(item: $navigateToGame) { game in
          GameDetailView(game: game)
        }
      }
      .tabItem {
        Label("Главная", systemImage: "globe.americas.fill")
          .labelStyle(.iconOnly)
      }

      NavigationStack {
        StatisticsScreen()
      }
      .tabItem {
        Label("Статистика", systemImage: "chart.bar.fill")
          .labelStyle(.iconOnly)
      }

      NavigationStack {
        SettingsScreen()
      }
      .tabItem {
        Label("Настройки", systemImage: "gearshape.fill")
          .labelStyle(.iconOnly)
      }
    }
    .onAppear {
      expansions = ExpansionSettingsManager.load()

      if !gameFields.contains(where: { $0.rawValue == gameField }) {
        gameField = GameField.farsida.rawValue
      }

      /// Синхронизация встроенных справочников без создания дубликатов.
      /// Это также добавит данные, появившиеся в следующих версиях приложения.
      generateInitialGameData(in: viewContext)

      /// Подписка на уведомление для перехода к сохранённой игре.
      if !didSetupNotificationObserver {
        NotificationCenter.default.addObserver(
          forName: Notification.Name("NavigateToStatistics"),
          object: nil,
          queue: .main
        ) { notification in
          if let game = notification.object as? Game {
            self.navigateToGame = game
            self.showGameSetup = false
          }
        }

        didSetupNotificationObserver = true
      }
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

  /// Создаёт новую локальную игру и открывает экран добавления игроков.
  private func startNewGame() {
    self.localGame = LocalGameData.empty(field: gameField)
    self.showGameSetup = true
  }
}
