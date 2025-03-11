import SwiftUI
import SwiftData

struct AddPlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player] // Запрос для получения игроков
    
    @State private var showGameScreen = false
    @State private var showAddPlayer = false
    @State private var selectedColor: String = ""
    
    let gameField: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Заголовок с красным фоном
                headerView
                
                // Кнопки выбора цвета
                colorButtonsView
                
                // Список игроков
                playersListView
                
                // Кнопка "Поехали👋"
                Button("Поехали👋") {
                    showGameScreen = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.white)
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerScreen(color: selectedColor) { player in
                    addPlayer(player)
                }
            }
            .navigationDestination(isPresented: $showGameScreen) {
                ScoreScreen(game: createGame())
            }
        }
    }
    
    // Создание новой игры
    private func createGame() -> Game {
        let game = Game(gameNumber: players.count + 1, date: Date(), gameField: gameField, players: players)
        modelContext.insert(game)
        return game
    }
    
    // Добавление игрока
    private func addPlayer(_ player: Player) {
        modelContext.insert(player)
    }
    
    // Удаление игрока
    private func deletePlayer(at offsets: IndexSet) {
        for index in offsets {
            let player = players[index]
            modelContext.delete(player)
        }
    }
    
    // Заголовок
    private var headerView: some View {
        ZStack {
            Color.red
                .frame(height: 100)
                .edgesIgnoringSafeArea(.top)
            
            Text("Добавить участников терраформирования")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // Кнопки выбора цвета
    private var colorButtonsView: some View {
        HStack(spacing: 16) {
            ForEach(["Красный", "Желтый", "Зеленый", "Синий", "Черный"], id: \.self) { color in
                if !players.contains(where: { $0.color == color }) {
                    ColorButton(color: color, action: {
                        selectedColor = color
                        showAddPlayer = true
                    })
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Список игроков
    private var playersListView: some View {
        List {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                playerRowView(index: index, player: player)
            }
            .onDelete(perform: deletePlayer)
        }
        .background(Color.white)
        .listStyle(PlainListStyle())
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Строка игрока
    private func playerRowView(index: Int, player: Player) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1).")
                    .frame(width: 15, alignment: .leading)
                    .foregroundColor(.black)
                Text(colorIcon(for: player.color))
                Text(player.name)
                    .foregroundColor(.black)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Корпорация: \(player.corporation)")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.9))
                Text("Прологи: \(player.prologue1), \(player.prologue2)")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowBackground(Color.clear)
    }
    
    // Функция для отображения иконки цвета
    func colorIcon(for color: String) -> String {
        switch color {
        case "Красный": return "🟥"
        case "Желтый": return "🟨"
        case "Зеленый": return "🟩"
        case "Синий": return "🟦"
        case "Черный": return "⬛️"
        default: return ""
        }
    }
}
