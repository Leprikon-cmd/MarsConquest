//
//  StatisticsCorporationsView.swift
//  MarsConquest
//
//  Зачем:
//  Показывает статистику корпораций по сохранённым экспедициям.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - сортировку, подписи, интервалы и оформление строк; формулы находятся в StatisticsCalculator.
//
import SwiftUI
import CoreData

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
        .safeAreaPadding(.bottom, JournalNavigationLayout.contentBottomClearance)
    }
}
