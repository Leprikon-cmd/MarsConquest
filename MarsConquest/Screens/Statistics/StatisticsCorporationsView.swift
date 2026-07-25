//
//  StatisticsCorporationsView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//
import SwiftUI
import CoreData
import UIKit

struct StatisticsCorporationsView: View {
    @Environment(\.locale) private var locale

    let games: [Game]

    var body: some View {

        let stats = StatisticsCalculator.corporationStats(from: games, locale: locale)

        return List {
            Section(header: Text("Корпорации")) {

                if stats.isEmpty {
                    Text("Пока нет данных по корпорациям")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stats) { corp in

                        VStack(alignment: .leading, spacing: 4) {

                            Text(corp.name)
                                .font(AppFont.font(.headline))

                            Text("Игр: \(corp.games) • Побед: \(corp.wins)")
                                .font(AppFont.font(.subheadline))

                            Text("Средний счёт: \(corp.averageScore.formatted(.number.precision(.fractionLength(1)))) • Лучший: \(corp.bestScore)")
                                .font(AppFont.font(.caption))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .safeAreaPadding(.bottom, journalNavigationClearance)
    }

    private var journalNavigationClearance: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 84 : 0
    }
}
