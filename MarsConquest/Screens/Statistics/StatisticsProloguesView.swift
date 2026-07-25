//
//  StatisticsProloguesView.swift
//  MarsConquest
//
//  Created by Евгений on 12.03.2026.
//
import SwiftUI
import CoreData
import UIKit

struct StatisticsProloguesView: View {
    @Environment(\.locale) private var locale

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
                            Text(localizedPreludeName(prologue.name))
                                .font(AppFont.font(.headline))

                            Text("Игр: \(prologue.games) • Побед: \(prologue.wins)")
                                .font(AppFont.font(.subheadline))

                            Text("Средний счёт: \(prologue.averageScore.formatted(.number.precision(.fractionLength(1)))) • Лучший: \(prologue.bestScore)")
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

    private func localizedPreludeName(_ name: String) -> String {
        GameData.localizedPreludeName(
            persistedName: name,
            referenceID: GameData.preludeID(named: name),
            locale: locale
        )
    }
}
