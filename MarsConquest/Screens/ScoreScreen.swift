//
//  ScoreScreen.swift
//
//  Зачем:
//  Основной экран подсчёта очков партии перед сохранением результата.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - ввод и отображение очков игроков
//  - выбор наград и достижений
//  - назначение наград и достижений игрокам
//  - показ итогов партии
//  - сохранение результатов игры в CoreData
//

import SwiftUI
import CoreData

struct ScoreScreen: View {
    /// Контекст CoreData для сохранения результатов игры.
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Среда для закрытия текущего экрана после сохранения.
    @Environment(\.presentationMode) var presentationMode

    /// Текущая локальная игра, собранная в интерфейсе до сохранения в базу.
    @Binding var localGame: LocalGameData

    /// Состояния для отображения ошибок и модальных окон выбора.
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAchievementsSheet = false
    @State private var showAwardsSheet = false

    /// Менеджер для расчётов итоговых очков и связанных функций.
    private let scoreManager = ScoreManager()

    /// Форматтер для числовых значений очков.
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.zeroSymbol = "0"
        return formatter
    }()

    /// Упрощённый доступ к списку игроков текущей партии.
    private var players: [LocalPlayer] {
        localGame.players
    }

    var body: some View {
        Form {
            GameInfoView(
                date: localGame.date,
                gameField: localGame.gameField,
                generation: $localGame.generation
            )

            playersTable()
            bonusPointsSection()
            rewardsSection()
            scoreManager.totalScoresSection(localGame: localGame)
            saveButton()
        }
        .navigationTitle("Подсчет очков")
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showAwardsSheet) {
            NavigationStack {
                AwardsListView(
                    selectedItems: $localGame.awards,
                    gameField: localGame.gameField,
                    hasVenus: localGame.expansions.hasVenus
                )
            }
        }
        .sheet(isPresented: $showAchievementsSheet) {
            NavigationStack {
                AchievementsListView(
                    selectedItems: $localGame.achievements,
                    gameField: localGame.gameField,
                    hasVenus: localGame.expansions.hasVenus
                )
            }
        }
    }

    // MARK: - Секции

    /// Таблица очков игроков по основным категориям.
    private func playersTable() -> some View {
        Section {
            ScoreTableView(localGame: $localGame, numberFormatter: numberFormatter)
        }
    }

    /// Секция назначения наград и достижений игрокам.
    private func bonusPointsSection() -> some View {
        Section(header: Text("Доп. очки: награды и достижения")) {
            VStack(alignment: .leading, spacing: 12) {
                
                if !localGame.achievements.isEmpty {
                    Text("Достижения")
                        .font(.headline)
                    
                    ForEach(localGame.achievements.indices, id: \.self) { index in
                        achievementRow(index: index)
                    }
                }
                
                if !localGame.awards.isEmpty {
                    Text("Награды")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ForEach(localGame.awards.indices, id: \.self) { index in
                        awardRow(index: index)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Отдельная маленькая кнопка-кружок.
    /// Важно: fixed frame + plain style, чтобы не вся строка была кнопкой.
    private func circleButton(
        systemName: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Строка назначения победителей достижения.
    private func achievementRow(index: Int) -> some View {
        let achievement = localGame.achievements[index]
        
        return HStack(alignment: .center) {
            Text(achievement.name)
                .frame(width: 140, alignment: .leading)
            
            ForEach(players, id: \.id) { player in
                let isSelected = localGame.achievements[index].winnerPlayerIDs.contains(player.id)
                
                circleButton(
                    systemName: isSelected ? "checkmark.circle.fill" : "circle",
                    color: .green
                ) {
                    toggleAchievementWinner(achievementIndex: index, playerID: player.id)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 2)
    }

    /// Строка назначения первого и второго места по награде.
    private func awardRow(index: Int) -> some View {
        let award = localGame.awards[index]
        let hasTieForFirst = award.firstPlacePlayerIDs.count > 1
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(award.name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center) {
                Text("1 место")
                    .frame(width: 140, alignment: .leading)
                
                ForEach(players, id: \.id) { player in
                    let isSelected = localGame.awards[index].firstPlacePlayerIDs.contains(player.id)
                    
                    circleButton(
                        systemName: isSelected ? "1.circle.fill" : "1.circle",
                        color: .yellow
                    ) {
                        toggleAwardFirstPlace(awardIndex: index, playerID: player.id)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            if players.count >= 3 && !hasTieForFirst {
                HStack(alignment: .center) {
                    Text("2 место")
                        .frame(width: 140, alignment: .leading)
                    
                    ForEach(players, id: \.id) { player in
                        let isSelected = localGame.awards[index].secondPlacePlayerIDs.contains(player.id)
                        
                        circleButton(
                            systemName: isSelected ? "2.circle.fill" : "2.circle",
                            color: .orange
                        ) {
                            toggleAwardSecondPlace(awardIndex: index, playerID: player.id)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Секция кнопок открытия экранов выбора наград и достижений.
    private func rewardsSection() -> some View {
        Section(header: Text("Награды и достижения")) {
            VStack(spacing: 12) {
                Button(action: {
                    showAwardsSheet = true
                }) {
                    Text("Добавить награды")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    showAchievementsSheet = true
                }) {
                    Text("Добавить достижения")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.vertical)
        }
    }

    /// Кнопка сохранения итогов партии.
    private func saveButton() -> some View {
        Button("Сохранить результаты") {
            saveGameResults()
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Логика назначения бонусов

    private func toggleAchievementWinner(achievementIndex: Int, playerID: UUID) {
        if localGame.achievements[achievementIndex].winnerPlayerIDs.contains(playerID) {
            localGame.achievements[achievementIndex].winnerPlayerIDs.removeAll()
        } else {
            localGame.achievements[achievementIndex].winnerPlayerIDs = [playerID]
        }
    }

    private func toggleAwardFirstPlace(awardIndex: Int, playerID: UUID) {
        if localGame.awards[awardIndex].firstPlacePlayerIDs.contains(playerID) {
            localGame.awards[awardIndex].firstPlacePlayerIDs.removeAll { $0 == playerID }
        } else {
            guard localGame.awards[awardIndex].firstPlacePlayerIDs.count < 2 else { return }
            localGame.awards[awardIndex].firstPlacePlayerIDs.append(playerID)
            // Один и тот же игрок не должен одновременно быть и на 1, и на 2 месте
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll { $0 == playerID }
        }

        if localGame.awards[awardIndex].firstPlacePlayerIDs.count > 1 {
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll()
        }
    }

    private func toggleAwardSecondPlace(awardIndex: Int, playerID: UUID) {
        guard players.count >= 3 else { return }
        guard localGame.awards[awardIndex].firstPlacePlayerIDs.count == 1 else { return }

        if localGame.awards[awardIndex].secondPlacePlayerIDs.contains(playerID) {
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll { $0 == playerID }
        } else {
            guard localGame.awards[awardIndex].secondPlacePlayerIDs.count < 2 else { return }
            localGame.awards[awardIndex].secondPlacePlayerIDs.append(playerID)
            // Один и тот же игрок не должен одновременно быть и на 1, и на 2 месте
            localGame.awards[awardIndex].firstPlacePlayerIDs.removeAll { $0 == playerID }
        }
    }

    // MARK: - Сохранение игры

    /// Сохраняет игру через GameSaver и после этого отправляет пользователя
    /// к экрану статистики / сохранённой партии.
    private func saveGameResults() {
        do {
            let savedGame = try GameSaver().save(localGame: localGame, in: viewContext)
            
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToStatistics"),
                    object: savedGame
                )
            }
        } catch {
            print("Ошибка сохранения: \(error.localizedDescription)")
            errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            showError = true
        }
    }
}
