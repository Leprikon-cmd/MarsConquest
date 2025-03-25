//
//  AddPlayersView.swift
//
//  Зачем:
//  Экран добавления участников новой партии перед вводом очков.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - выбор цветов игроков
//  - открытие формы добавления игрока
//  - отображение списка добавленных игроков
//  - удаление игроков из локальной партии
//  - переход к экрану ввода очков
//

import SwiftUI

struct AddPlayersView: View {
    /// Локальная модель текущей создаваемой игры.
    @Binding var localGame: LocalGameData
    
    /// Показывает sheet добавления нового игрока.
    @State private var showAddPlayer = false
    
    /// Цвет, который выбран для нового игрока.
    @State private var selectedColor: String = ""
    
    /// Флаг перехода на экран ввода очков.
    @State private var navigateToScoreScreen = false
    
    /// Доступные цвета игроков.
    private let colors = GameData.colors
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerView
                colorButtonsView
                playersListView

                Button(action: {
                    navigateToScoreScreen = true
                }) {
                    Text("Поехали👋")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            Image("button8")
                                .resizable()
                                .scaledToFill()
                        )
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .disabled(localGame.players.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .background(
                Image("bgi")
                    .resizable()
                    .scaledToFill()
            )
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerScreen(selectedColor: selectedColor, localGame: $localGame)
            }
            .navigationTitle("Добавить игроков")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToScoreScreen) {
                ScoreScreen(localGame: $localGame)
            }
        }
    }
    
    /// Верхний заголовок экрана.
    private var headerView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.red, .orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .edgesIgnoringSafeArea(.top)
            
            Text("Добавить участников терраформирования")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    /// Блок кнопок выбора свободного цвета игрока.
    /// Уже занятые цвета не показываются.
    private var colorButtonsView: some View {
        HStack(spacing: 16) {
            ForEach(colors, id: \.self) { color in
                if !localGame.players.contains(where: { $0.color == color }) {
                    Button(action: {
                        selectedColor = color
                        showAddPlayer = true
                    }) {
                        Text(colorIcon(for: color))
                            .font(.title)
                            .padding()
                            .background(selectedColor == color ? Color.gray.opacity(0.3) : Color.clear)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    /// Список уже добавленных игроков.
    private var playersListView: some View {
        List {
            ForEach(localGame.players) { player in
                playerRowView(player: player)
            }
            .onDelete(perform: deletePlayer)
        }
        .background(Color.white)
        .listStyle(PlainListStyle())
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    /// Одна строка списка игроков.
    /// Показывает цвет, имя, корпорацию и прологи игрока.
    private func playerRowView(player: LocalPlayer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
    
    /// Удаляет игрока из локального списка по свайпу.
    private func deletePlayer(at offsets: IndexSet) {
        localGame.players.remove(atOffsets: offsets)
    }
    
    /// Возвращает эмодзи-иконку для строкового названия цвета.
    private func colorIcon(for color: String) -> String {
        switch color {
        case "Красный": return "🟥"
        case "Желтый": return "🟨"
        case "Зеленый": return "🟩"
        case "Синий": return "🟦"
        case "Черный": return "⬛️"
        default: return "❓"
        }
    }
}
