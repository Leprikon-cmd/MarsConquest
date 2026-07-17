//
//  StatisticsProloguesView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//
import SwiftUI
import CoreData

struct StatisticsProloguesView: View {
    let games: [Game]

    var body: some View {
        let stats = StatisticsCalculator.prologueStats(from: games)

        return List {
            Section(header: Text("Прологи")) {
                if stats.isEmpty {
                    Text("Пока нет данных по прологам")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stats) { prologue in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prologue.name)
                                .font(.headline)

                            Text(String(
                                format: String(localized: "Игр: %lld • Побед: %lld"),
                                prologue.games,
                                prologue.wins
                            ))
                                .font(.subheadline)

                            Text(String(
                                format: String(localized: "Средний счёт: %@ • Лучший: %lld"),
                                prologue.averageScore.formatted(.number.precision(.fractionLength(1))),
                                prologue.bestScore
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
