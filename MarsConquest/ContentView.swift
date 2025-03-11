import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Game.date, order: .reverse) private var games: [Game]
    @Environment(\.modelContext) private var modelContext
    @State private var gameField: String = "Фарсида"
    @State private var showAddPlayersView = false
    
    // Список игровых полей
    private let gameFields = ["Фарсида", "Эллада", "Элизий"]
    
    // Индекс текущего игрового поля
    private var currentGameFieldIndex: Int {
        gameFields.firstIndex(of: gameField) ?? 0
    }
    
    // Цвета для текста кнопки выбора игрового поля
    private var buttonTextColor: Color {
        switch gameField {
        case "Фарсида": return .white
        case "Эллада": return .white
        case "Элизий": return .white
        default: return .black
        }
    }
    
    private var buttonBackground: some View {
        Group {
            if gameField == "Фарсида" {
                Image("farsida")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if gameField == "Эллада" {
                Image("ellada")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if gameField == "Элизий" {
                Image("elizium")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.clear)
            }
        }
    }
    
    var body: some View {
        TabView {
            // Главная страница
            ZStack {
                // Фон-картинка
                Image("fon")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                // Основной контент
                VStack(spacing: 16) {
                    // Заголовок "Покорение Марса"
                    Text("Покорение Марса")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    // Подпись "Выбор места высадки"
                    Text("Выбор места высадки")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Круглая кнопка выбора игрового поля
                    ZStack {
                        buttonBackground
                        Text(gameField)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(buttonTextColor)
                    }
                    .frame(width: 360, height: 360)
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if gesture.translation.width < -50 {
                                    withAnimation {
                                        let nextIndex = (currentGameFieldIndex + 1) % gameFields.count
                                        gameField = gameFields[nextIndex]
                                    }
                                } else if gesture.translation.width > 50 {
                                    withAnimation {
                                        let previousIndex = (currentGameFieldIndex - 1 + gameFields.count) % gameFields.count
                                        gameField = gameFields[previousIndex]
                                    }
                                }
                            }
                    )
                    .padding(.vertical, 10)
                    
                    // Кнопка "Высадка!"
                    Button(action: {
                        showAddPlayersView = true
                    }) {
                        Text("Высадка!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
            }
            .tabItem {
                Image(systemName: "house.fill") // Иконка для главной страницы
                Text("Главная")
            }
            
            // Статистика
            StatisticsScreen()
                .tabItem {
                    Image(systemName: "chart.bar.fill") // Иконка для статистики
                    Text("Статистика")
                }
            
            // Настройки (заглушка)
            Text("Настройки")
                .tabItem {
                    Image(systemName: "gearshape.fill") // Иконка для настроек
                    Text("Настройки")
                }
            
            // Калькулятор (заглушка)
            Text("Калькулятор")
                .tabItem {
                    Image(systemName: "plusminus.circle.fill") // Иконка для калькулятора
                    Text("Калькулятор")
                }
        }
        .sheet(isPresented: $showAddPlayersView) {
            AddPlayersView(gameField: gameField)
        }
    }
}
