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
//  Что можно менять руками:
//  - реквизиты, интервалы, прозрачность плашек и подпись «Внести в журнал»;
//    правила полноты записи и сохранение находятся в GameSaver.
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

/// Реквизит, который архив уточняет перед внесением записи.
private enum ArchiveDetailRequest: String, Identifiable {
    case generation
    case venusTerraforming

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
    @State private var archiveDetailRequest: ArchiveDetailRequest?
    @State private var showArchiveConfirmation = false
    @State private var showArchiveRecorded = false
    @State private var archivedGame: Game?
    /// Не позволяет сохранить одну и ту же партию повторным быстрым нажатием.
    @State private var isSaving = false

    /// Упрощённый доступ к списку игроков текущей партии.
    private var players: [LocalPlayer] {
        localGame.players
    }

    /// Единый материал карточек: совпадает с блоками центра управления экспедицией.
    /// Углы оставляет Form, чтобы связанные строки выглядели единым блоком.
    private var scorePanelBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
    }

    private var isEnglish: Bool {
        locale.identifier.lowercased().hasPrefix("en")
    }

    var body: some View {
        ZStack {
            Image(localGame.backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Form {
                GameInfoView(
                    date: localGame.date,
                    gameField: localGame.gameField,
                    generation: $localGame.generation,
                    isGenerationLocked: localGame.hostSession != nil,
                    hasVenus: localGame.expansions.hasVenus,
                    venusTerraformingScale: $localGame.venusTerraformingScale
                )
                .listRowBackground(scorePanelBackground)

                playersTable()
                    .listRowBackground(scorePanelBackground)
                rewardsSection()
                    .listRowBackground(Color.clear)
                TieBreakerSectionView(localGame: $localGame)
                    .listRowBackground(scorePanelBackground)
                sportsRegulationSection()
                    .listRowBackground(scorePanelBackground)
                ScoreSummaryView(localGame: localGame)
                    .listRowBackground(scorePanelBackground)
                saveButton()
                    .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .accessibilityIdentifier("score-screen")
        .navigationTitle("")
        .alert("Архив временно недоступен", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Подтверждение записи", isPresented: $showArchiveConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Внести в журнал") {
                saveGameResults()
            }
        } message: {
            Text(archiveConfirmationMessage)
        }
        .alert("Запись внесена в архив.", isPresented: $showArchiveRecorded) {
            Button("Продолжить") {
                completeArchive()
            }
        }
        .sheet(item: $activeSelectionSheet) { sheet in
            SelectionSheetContent(sheet: sheet, localGame: $localGame)
                // Не даём SwiftUI сохранить экран предыдущего типа.
                .id(sheet.id)
        }
        .sheet(item: $archiveDetailRequest) { request in
            ArchiveDetailRequestView(
                request: request,
                generation: $localGame.generation,
                venusTerraformingScale: $localGame.venusTerraformingScale,
                onDetailRecorded: continueArchivePreparation
            )
            .presentationDetents([.height(230)])
            .presentationDragIndicator(.visible)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .compactGameFieldButtonStyle(for: localGame.gameField)
                }
                // Form иначе может объединить обе кнопки строки в одну область тапа.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())

                Button(action: {
                    activeSelectionSheet = .awards
                }) {
                    Text("Награды")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .compactGameFieldButtonStyle(for: localGame.gameField)
                }
                // У наград своя независимая область нажатия.
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    /// Кнопка сохранения итогов партии.
    private func saveButton() -> some View {
        Button(action: {
            prepareArchiveEntry()
        }) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.black)
                }
                Text(isSaving ? "Внесение записи…" : "Внести в журнал")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 10)
            .gameFieldButtonStyle(for: localGame.gameField)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityIdentifier("archive-entry-button")
    }

    // MARK: - Архивирование экспедиции

    private var archiveConfirmationMessage: String {
        let name = players.first?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let addressee = (name?.isEmpty == false ? name! : "руководитель")
        return "Мистер \(addressee),\n\nВы подтверждаете достоверность сведений, указанных в журнале экспедиции?"
    }

    /// Сначала спокойно уточняем только отсутствующие реквизиты, затем просим подтверждение.
    private func prepareArchiveEntry() {
        guard !isSaving else { return }

        if localGame.generation == nil {
            archiveDetailRequest = .generation
        } else if localGame.expansions.hasVenus, localGame.venusTerraformingScale == nil {
            archiveDetailRequest = .venusTerraforming
        } else {
            showArchiveConfirmation = true
        }
    }

    private func continueArchivePreparation() {
        archiveDetailRequest = nil
        DispatchQueue.main.async {
            prepareArchiveEntry()
        }
    }

    /// Вносит подтверждённую экспедицию в архив и показывает спокойное подтверждение.
    private func saveGameResults() {
        guard !isSaving else { return }
        isSaving = true

        do {
            archivedGame = try GameSaver().save(localGame: localGame, in: viewContext)
            ActiveExpeditionStore.clear()
            DispatchQueue.main.async {
                showArchiveRecorded = true
            }
        } catch {
            isSaving = false
            errorMessage = String(
                format: String(localized: "Не удалось внести запись: %@", locale: locale),
                locale: locale,
                error.localizedDescription
            )
            showError = true
        }
    }

    private func completeArchive() {
        guard let archivedGame else { return }
        // Сбрасываем локальную сессию до возврата на предыдущий экран: иначе
        // его onAppear может снова записать уже внесённую экспедицию в черновик.
        localGame.hostSession = nil
        ActiveExpeditionStore.clear()
        dismiss()
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToStatistics"),
            object: archivedGame
        )
    }

    @ViewBuilder
    private func sportsRegulationSection() -> some View {
        if let session = localGame.hostSession, session.configuration.isSportsMode {
            Section {
                Text(isEnglish ? "Sports mode" : "Спортивный режим")
                    .font(AppFont.font(.headline))
                    .foregroundStyle(.black)
                if session.configuration.usesTimer {
                    Text(
                        isEnglish
                          ? "Limit: \(session.configuration.timeLimitSeconds / 60) min per participant"
                          : "Лимит: \(session.configuration.timeLimitSeconds / 60) мин. на участника"
                    )
                }
                if let generationLimit = session.configuration.generationLimit {
                    Text(isEnglish ? "Generation limit: \(generationLimit)" : "Лимит поколений: \(generationLimit)")
                }
                if session.sportsOutcome == .generationLimitReached {
                    Text(isEnglish ? "Sports outcome: generation limit reached, no winner." : "По регламенту: лимит поколений достигнут, победителя нет.")
                        .foregroundStyle(.red)
                } else if let winnerID = SportsRegulationCalculator.winnerID(in: localGame),
                          let winner = localGame.players.first(where: { $0.id == winnerID }) {
                    Text(isEnglish ? "Sports winner: \(winner.name)" : "Победитель по регламенту: \(winner.name)")
                        .foregroundStyle(.green)
                } else {
                    Text(isEnglish ? "Sports outcome: everyone loses." : "По регламенту: проиграли все.")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

/// Небольшой архивный запрос: выбор реквизита сразу продолжает оформление записи.
private struct ArchiveDetailRequestView: View {
    @Environment(\.dismiss) private var dismiss

    let request: ArchiveDetailRequest
    @Binding var generation: Int?
    @Binding var venusTerraformingScale: Int?
    let onDetailRecorded: () -> Void

    private let venusValues = Array(stride(from: 0, through: 30, by: 2))

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Уточнение записи")
                .font(AppFont.font(.headline))

            Text(prompt)
                .font(AppFont.font(.body))

            Picker(selectionTitle, selection: selection) {
                Text("—").tag(nil as Int?)
                ForEach(values, id: \.self) { value in
                    Text(valueLabel(value)).tag(Optional(value))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .onChange(of: selectedValue) { _, value in
            guard value != nil else { return }
            dismiss()
            onDetailRecorded()
        }
    }

    private var prompt: String {
        switch request {
        case .generation:
            return "Прежде чем принять запись, позвольте уточнить: на каком поколении был завершён проект?"
        case .venusTerraforming:
            return "Не могли бы вы уточнить, до какого уровня удалось терраформировать Венеру?"
        }
    }

    private var selectionTitle: String {
        request == .generation ? "Поколение" : "Шкала Венеры"
    }

    private var selection: Binding<Int?> {
        request == .generation ? $generation : $venusTerraformingScale
    }

    private var selectedValue: Int? {
        request == .generation ? generation : venusTerraformingScale
    }

    private var values: [Int] {
        request == .generation ? Array(5...20) : venusValues
    }

    private func valueLabel(_ value: Int) -> String {
        request == .generation ? "\(value)" : "\(value)%"
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
