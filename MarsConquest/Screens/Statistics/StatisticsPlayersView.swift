//
//  StatisticsPlayersView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//
import SwiftUI
import CoreData

struct StatisticsPlayersView: View {
    let games: [Game]

    var body: some View {
        let stats = StatisticsCalculator.playerStats(from: games)

        return List {
            Section(header: Text("Игроки")) {
                if stats.isEmpty {
                    Text("Пока нет данных по игрокам")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stats) { player in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.name)
                                .font(.headline)

                            Text(String(
                                format: String(localized: "Игр: %lld • Побед: %lld"),
                                player.games,
                                player.wins
                            ))
                                .font(.subheadline)

                            Text(String(
                                format: String(localized: "Средний счёт: %@ • Лучший: %lld"),
                                player.averageScore.formatted(.number.precision(.fractionLength(1))),
                                player.bestScore
                            ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
