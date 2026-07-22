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
    @Environment(\.locale) private var locale

    /// Текущая локальная игра, собранная в интерфейсе до сохранения в базу.
    @Binding var localGame: LocalGameData

    /// Состояния для отображения ошибок и модальных окон выбора.
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var activeSelectionSheet: SelectionSheet?
    /// Не позволяет сохранить одну и ту же партию повторным быстрым нажатием.
    @State private var isSaving = false

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
            rewardsSection()
            ScoreSummaryView(localGame: localGame)
            TieBreakerSectionView(localGame: $localGame)
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
            ScoreTableView(localGame: $localGame)
        }
    }

    /// Секция кнопок открытия экранов выбора наград и достижений.
    private func rewardsSection() -> some View {
        Section {
            HStack(spacing: 12) {
                Button(action: {
                    activeSelectionSheet = .achievements
                }) {
                    Text("Достижения")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                        .padding(.horizontal, 10)
                        .gameFieldButtonStyle(for: localGame.gameField)
                }
                // Form иначе может объединить обе кнопки строки в одну область тапа.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())

                Button(action: {
                    activeSelectionSheet = .awards
                }) {
                    Text("Награды")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                        .padding(.horizontal, 10)
                        .gameFieldButtonStyle(for: localGame.gameField)
                }
                // У наград своя независимая область нажатия.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
            }
            .padding(.vertical, 4)
        }
    }

    /// Кнопка сохранения итогов партии.
    private func saveButton() -> some View {
        Button(action: {
            saveGameResults()
        }) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.black)
                }
                Text(isSaving ? "Сохранение..." : "Сохранить результаты")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 10)
            .gameFieldButtonStyle(for: localGame.gameField)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
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
            errorMessage = String(
                format: String(localized: "Ошибка сохранения: %@", locale: locale),
                locale: locale,
                error.localizedDescription
            )
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
