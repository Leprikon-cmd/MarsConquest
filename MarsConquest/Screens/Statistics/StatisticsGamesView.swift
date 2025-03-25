//
//  StatisticsGamesView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//

import SwiftUI
import CoreData

struct StatisticsGamesView: View {
    let games: [Game]
    let onDelete: (IndexSet) -> Void
    let onDeleteSelected: (Set<NSManagedObjectID>) -> Void
    
    @State private var selectedGames = Set<NSManagedObjectID>()
    @Environment(\.editMode) private var editMode

    var body: some View {
        List(selection: $selectedGames) {
            Section(header: Text("Общая статистика")) {
                Text("Количество сыгранных игр: \(games.count)")

                if let lastGame = games.first {
                    Text("Последняя игра: \(StatisticsCalculator.formattedDate(lastGame.date))")
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
    }

    private func gameRow(index: Int, game: Game) -> some View {
        VStack(alignment: .leading) {
            Text("Игра №\(index + 1)")
                .font(.headline)

            Text("Поле: \(game.gameField ?? UIStrings.unknown)")
            Text("Дата: \(StatisticsCalculator.formattedDate(game.date))")

            if let winner = StatisticsCalculator.winner(of: game) {
                Text("Победитель: \(winner.name) — \(winner.score)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
