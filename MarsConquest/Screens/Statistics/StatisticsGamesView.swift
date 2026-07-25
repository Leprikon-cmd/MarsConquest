//
//  StatisticsGamesView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//

import SwiftUI
import CoreData
import UIKit

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
        .safeAreaPadding(.bottom, journalNavigationClearance)
    }

    private var journalNavigationClearance: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 84 : 0
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
}
