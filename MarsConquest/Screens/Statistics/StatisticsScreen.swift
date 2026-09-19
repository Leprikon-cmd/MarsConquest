//
//  StatisticsScreen.swift
//
//  Зачем:
//  Контейнер экрана статистики с переключением между страницами.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - порядок вкладок, подписи и нижний запас под навигацию iPhone.
//

import SwiftUI
import CoreData

struct StatisticsScreen: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.locale) private var locale

    @FetchRequest(
        entity: Game.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.date, ascending: false)]
    ) private var games: FetchedResults<Game>

    @State private var selectedPage: StatisticsPage = .games
    @State private var gameFilter: GameHistoryFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statisticsPagePicker()
                gameFilterPicker()

                TabView(selection: $selectedPage) {
                    StatisticsGamesView(
                        games: filteredGames,
                        onDelete: { offsets in deleteGames(at: offsets, from: filteredGames) },
                        onDeleteSelected: deleteSelectedGames
                    )
                    .tag(StatisticsPage.games)

                    StatisticsPlayersView(
                        games: filteredGames
                    )
                    .tag(StatisticsPage.players)

                    StatisticsCorporationsView(
                        games: filteredGames
                    )
                        .tag(StatisticsPage.corporations)

                    StatisticsProloguesView(
                        games: filteredGames
                    )
                        .tag(StatisticsPage.prologues)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Статистика")
        }
    }

    private var filteredGames: [Game] {
        switch gameFilter {
        case .all:
            return Array(games)
        case .classic:
            return games.filter { !$0.isSportsMode }
        case .sports:
            return games.filter(\.isSportsMode)
        }
    }

    private func gameFilterPicker() -> some View {
        Picker("Формат партий", selection: $gameFilter) {
            ForEach(GameHistoryFilter.allCases) { filter in
                Text(filter.title(for: locale)).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func statisticsPagePicker() -> some View {
        let pages = StatisticsPage.allCases
        let currentIndex = pages.firstIndex(of: selectedPage) ?? 0

        let previousPage = currentIndex == 0
            ? pages[pages.count - 1]
            : pages[currentIndex - 1]

        let nextPage = currentIndex == pages.count - 1
            ? pages[0]
            : pages[currentIndex + 1]

        return HStack {
            Button {
                selectedPage = previousPage
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(AppFont.font(.caption))
                    Text(previousPage.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(AppFont.font(.footnote))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(selectedPage.title)
                .font(AppFont.font(.headline))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                selectedPage = nextPage
            } label: {
                HStack(spacing: 4) {
                    Text(nextPage.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.right")
                        .font(AppFont.font(.caption))
                }
                .font(AppFont.font(.footnote))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func deleteGames(at offsets: IndexSet, from displayedGames: [Game]) {
        for index in offsets {
            let game = displayedGames[index]
            viewContext.delete(game)
        }

        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления игры: \(error.localizedDescription)")
        }
    }
    private func deleteSelectedGames(_ selectedGames: Set<NSManagedObjectID>) {
        for objectID in selectedGames {
            if let game = try? viewContext.existingObject(with: objectID) as? Game {
                viewContext.delete(game)
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления выбранных игр: \(error.localizedDescription)")
        }
    }
}

/// Фильтр один для журнала и всех страниц статистики: форматы не смешиваются незаметно.
private enum GameHistoryFilter: String, CaseIterable, Identifiable {
    case all
    case classic
    case sports

    var id: String { rawValue }

    func title(for locale: Locale) -> String {
        let isEnglish = locale.identifier.lowercased().hasPrefix("en")
        switch self {
        case .all: return isEnglish ? "All" : "Все"
        case .classic: return isEnglish ? "Classic" : "Классика"
        case .sports: return isEnglish ? "Sports" : "Спортивный"
        }
    }
}
