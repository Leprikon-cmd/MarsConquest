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

    var body: some View {
        List {
            Section(header: Text("Общая статистика")) {
                Text("Количество сыгранных игр: \(games.count)")

                if let lastGame = games.first {
                    Text("Последняя игра: \(StatisticsCalculator.formattedDate(lastGame.date))")
                }
            }

            Section(header: Text("Список игр")) {
                ForEach(games, id: \.objectID) { game in
                    NavigationLink(destination: GameDetailView(game: game)) {
                        VStack(alignment: .leading) {
                            Text("Игра №\(game.gameNumber)")
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
                .onDelete(perform: onDelete)
            }
        }
    }
}
