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

/// Тип списка, открываемого поверх экрана подсчёта.
/// В каждый момент может быть открыт только один список.
private enum SelectionSheet: String, Identifiable {
    case achievements
    case awards

    var id: String { rawValue }
}

struct ScoreScreen: View {
    /// Контекст CoreData для сохранения результатов игры.
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Современный механизм SwiftUI для закрытия текущего экрана после сохранения.
    @Environment(\.dismiss) private var dismiss

    /// Текущая локальная игра, собранная в интерфейсе до сохранения в базу.
    @Binding var localGame: LocalGameData

    /// Состояния для отображения ошибок и модальных окон выбора.
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var activeSelectionSheet: SelectionSheet?
    /// Не позволяет сохранить одну и ту же партию повторным быстрым нажатием.
    @State private var isSaving = false

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
            ScoreSummaryView(localGame: localGame)
            saveButton()
        }
        .navigationTitle("Подсчет очков")
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $activeSelectionSheet) { sheet in
            SelectionSheetContent(sheet: sheet, localGame: $localGame)
                // Не даём SwiftUI сохранить экран предыдущего типа.
                .id(sheet.id)
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
                    let isFirstPlace = localGame.awards[index].firstPlacePlayerIDs.contains(player.id)
                    
                    circleButton(
                        systemName: isSelected ? "2.circle.fill" : "2.circle",
                        color: isFirstPlace ? .gray : .orange
                    ) {
                        toggleAwardSecondPlace(awardIndex: index, playerID: player.id)
                    }
                    .disabled(isFirstPlace)
                    .opacity(isFirstPlace ? 0.4 : 1)
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
            HStack(spacing: 12) {
                Button(action: {
                    activeSelectionSheet = .achievements
                }) {
                    Text("Достижения")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                // Form иначе может объединить обе кнопки строки в одну область тапа.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())

                Button(action: {
                    activeSelectionSheet = .awards
                }) {
                    Text("Награды")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                // У наград своя независимая область нажатия.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
            }
            .padding(.vertical)
        }
    }

    /// Кнопка сохранения итогов партии.
    private func saveButton() -> some View {
        Button(action: {
            saveGameResults()
        }) {
            if isSaving {
                ProgressView()
                Text("Сохранение...")
            } else {
                Text("Сохранить результаты")
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .disabled(isSaving)
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
        guard !localGame.awards[awardIndex].firstPlacePlayerIDs.contains(playerID) else { return }

        if localGame.awards[awardIndex].secondPlacePlayerIDs.contains(playerID) {
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll { $0 == playerID }
        } else {
            localGame.awards[awardIndex].secondPlacePlayerIDs.append(playerID)
        }
    }

    // MARK: - Сохранение игры

    /// Сохраняет игру через GameSaver и после этого отправляет пользователя
    /// к экрану статистики / сохранённой партии.
    private func saveGameResults() {
        guard !isSaving else { return }
        isSaving = true

        do {
            let savedGame = try GameSaver().save(localGame: localGame, in: viewContext)
            
            DispatchQueue.main.async {
                dismiss()
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToStatistics"),
                    object: savedGame
                )
            }
        } catch {
            // Не оставляем в контексте недосохранённую партию перед повторной попыткой.
            viewContext.rollback()
            isSaving = false
            print("Ошибка сохранения: \(error.localizedDescription)")
            errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            showError = true
        }
    }
}

/// Отдельный контейнер для содержимого модального окна.
/// Он нужен, чтобы экраны наград и достижений не делили состояние SwiftUI.
private struct SelectionSheetContent: View {
    let sheet: SelectionSheet
    @Binding var localGame: LocalGameData

    var body: some View {
        NavigationStack {
            switch sheet {
            case .achievements:
                AchievementsListView(
                    selectedItems: $localGame.achievements,
                    gameField: localGame.gameField,
                    hasVenus: localGame.expansions.hasVenus
                )
            case .awards:
                AwardsListView(
                    selectedItems: $localGame.awards,
                    gameField: localGame.gameField,
                    hasVenus: localGame.expansions.hasVenus
                )
            }
        }
    }
}
