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

                            Text("Игр: \(prologue.games) • Побед: \(prologue.wins)")
                                .font(.subheadline)

                            Text("Средний счёт: \(String(format: "%.1f", prologue.averageScore)) • Лучший: \(prologue.bestScore)")
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
