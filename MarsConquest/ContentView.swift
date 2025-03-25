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

import SwiftUI
import CoreData

struct ContentView: View {
    /// Контекст CoreData из окружения SwiftUI.
    @Environment(\.managedObjectContext) private var viewContext
    
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

    /// Доступные игровые поля.
    private let gameFields = GameField.allCases
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

                        Text("Выбор места высадки")
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
                            Text(gameField)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .gesture(
                            DragGesture().onEnded { gesture in
                                let currentIndex = gameFields.firstIndex(where: { $0.rawValue == gameField }) ?? 0
                                
                                if gesture.translation.width < -50 {
                                    withAnimation {
                                        gameField = gameFields[(currentIndex + 1) % gameFields.count].rawValue
                                    }
                                } else if gesture.translation.width > 50 {
                                    withAnimation {
                                        gameField = gameFields[(currentIndex - 1 + gameFields.count) % gameFields.count].rawValue
                                    }
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
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        /// Скрытый переход на экран деталей игры.
                        /// Срабатывает после получения уведомления с объектом Game.
                        if let selectedGame = navigateToGame {
                            NavigationLink(
                                "",
                                destination: GameDetailView(game: selectedGame),
                                isActive: .constant(true)
                            )
                            .hidden()
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
                Label("Главная", systemImage: "house.fill")
            }

            NavigationStack {
                StatisticsScreen()
            }
            .tabItem {
                Label("Статистика", systemImage: "chart.bar.fill")
            }
        }
        .onAppear {
            /// Первичная загрузка стартовых данных в базу.
            if !UserDefaults.standard.bool(forKey: "initialDataLoaded") {
                generateInitialGameData(in: viewContext)
                UserDefaults.standard.set(true, forKey: "initialDataLoaded")
            }

            /// Отладочная проверка количества корпораций в базе.
            let fetchRequest: NSFetchRequest<Corporation> = Corporation.fetchRequest()
            if let corporations = try? viewContext.fetch(fetchRequest) {
                print("Корпораций в базе: \(corporations.count)")
            }

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
        .sheet(isPresented: $showGameSetup) {
            NavigationStack {
                AddPlayersView(localGame: $localGame)
            }
        }
    }

    /// Создаёт новую локальную игру и открывает экран добавления игроков.
    private func startNewGame() {
        self.localGame = LocalGameData.empty(field: gameField)
        self.showGameSetup = true
    }
}
