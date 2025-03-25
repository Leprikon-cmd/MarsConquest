//
//  StatisticsCorporationsView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//
import SwiftUI
import CoreData

struct StatisticsCorporationsView: View {

    let games: [Game]

    var body: some View {

        let stats = StatisticsCalculator.corporationStats(from: games)

        return List {
            Section(header: Text("Корпорации")) {

                if stats.isEmpty {
                    Text("Пока нет данных по корпорациям")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stats) { corp in

                        VStack(alignment: .leading, spacing: 4) {

                            Text(corp.name)
                                .font(.headline)

                            Text("Игр: \(corp.games) • Побед: \(corp.wins)")
                                .font(.subheadline)

                            Text("Средний счёт: \(String(format: "%.1f", corp.averageScore)) • Лучший: \(corp.bestScore)")
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
