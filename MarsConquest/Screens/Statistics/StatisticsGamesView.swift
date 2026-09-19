//
//  StatisticsGamesView.swift
//  MarsConquest
//
//  Зачем:
//  Показывает список сохранённых экспедиций и действия с записями.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - внешний вид строк, подписи и отступы; удаление записей — осознанное действие владельца.
//

import SwiftUI
import CoreData

struct StatisticsGamesView: View {
    let games: [Game]
    let onDelete: (IndexSet) -> Void
    let onDeleteSelected: (Set<NSManagedObjectID>) -> Void
    
    @State private var selectedGames = Set<NSManagedObjectID>()
    @Environment(\.editMode) private var editMode
    @Environment(\.locale) private var locale

    var body: some View {
        List(selection: $selectedGames) {
            Section(header: Text("Общая статистика")) {
                Text("Количество сыгранных игр: \(games.count)")

                if let lastGame = games.first {
                Text("Последняя игра: \(StatisticsCalculator.formattedDate(lastGame.date, locale: locale))")
                }
            }

            if !sportsGames.isEmpty {
                Section(header: Text(isEnglish ? "Sports mode" : "Спортивный режим")) {
                    Text(isEnglish ? "Sports expeditions: \(sportsGames.count)" : "Спортивных экспедиций: \(sportsGames.count)")
                    Text(isEnglish ? "Time limits exceeded: \(sportsTimeExceededCount)" : "Превышений времени: \(sportsTimeExceededCount)")
                    Text(isEnglish ? "Generation limit reached: \(generationLimitReachedCount)" : "Лимит поколений достигнут: \(generationLimitReachedCount)")
                }
            }

            Section(header: Text("Список игр")) {
                ForEach(Array(games.enumerated()), id: \.element.objectID) { index, game in
                    if editMode?.wrappedValue.isEditing == true {
                        gameRow(index: index, game: game)
                            .tag(game.objectID)
                    } else {
                        NavigationLink(destination: GameDetailView(game: game, gameNumber: index + 1)) {
                            gameRow(index: index, game: game)
                        }
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }

            ToolbarItem(placement: .navigationBarLeading) {
                if editMode?.wrappedValue.isEditing == true && !selectedGames.isEmpty {
                    Button("Удалить") {
                        onDeleteSelected(selectedGames)
                        selectedGames.removeAll()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .safeAreaPadding(.bottom, JournalNavigationLayout.contentBottomClearance)
    }

    private func gameRow(index: Int, game: Game) -> some View {
        let localizedGameField = GameField.localizedName(
            persistedName: game.gameField,
            referenceID: game.gameFieldID,
            locale: locale
        )

        return VStack(alignment: .leading) {
            Text(isEnglish ? "Game #\(index + 1)" : "Игра №\(index + 1)")
                .font(AppFont.font(.headline))

            Text("Поле: \(localizedGameField)")
            Text("Дата: \(StatisticsCalculator.formattedDate(game.date, locale: locale))")

            if game.isSportsMode {
                Text(isEnglish ? "Sports mode" : "Спортивный режим")
                    .font(AppFont.font(.subheadline))
                    .foregroundStyle(.red)
            }

            let colonies = colonyNames(for: game)
            if !colonies.isEmpty {
                Text("Колонии: \(colonies.joined(separator: ", "))")
                    .font(AppFont.font(.subheadline))
                    .foregroundColor(.secondary)
            }

            if let winner = StatisticsCalculator.winner(of: game, locale: locale) {
                Text("Победитель: \(winner.name) — \(winner.score)")
                    .font(AppFont.font(.subheadline))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func colonyNames(for game: Game) -> [String] {
        guard let colonies = game.colonies?.allObjects as? [Colony] else { return [] }
        return colonies
            .map {
                GameData.localizedColonyName(
                    persistedName: $0.name,
                    referenceID: $0.referenceID,
                    locale: locale
                )
            }
            .sorted()
    }

    private var isEnglish: Bool {
        locale.identifier.lowercased().hasPrefix("en")
    }

    private var sportsGames: [Game] {
        games.filter(\.isSportsMode)
    }

    private var sportsTimeExceededCount: Int {
        sportsGames.reduce(0) { result, game in
            result + ((game.players?.allObjects as? [Player] ?? []).filter(\.sportsTimeExceeded).count)
        }
    }

    private var generationLimitReachedCount: Int {
        sportsGames.filter {
            $0.sportsOutcome == SportsOutcome.generationLimitReached.rawValue
        }.count
    }
}
