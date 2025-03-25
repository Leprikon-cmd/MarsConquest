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

import SwiftUI
import CoreData

struct StatisticsScreen: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Game.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.date, ascending: false)]
    ) private var games: FetchedResults<Game>

    @State private var selectedPage: StatisticsPage = .games

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statisticsPagePicker()

                TabView(selection: $selectedPage) {
                    StatisticsGamesView(
                        games: Array(games),
                        onDelete: deleteGames,
                        onDeleteSelected: deleteSelectedGames
                    )
                    .tag(StatisticsPage.games)

                    StatisticsPlayersView(
                        games: Array(games)
                    )
                    .tag(StatisticsPage.players)

                    StatisticsCorporationsView(
                        games: Array(games)
                    )
                        .tag(StatisticsPage.corporations)

                    StatisticsProloguesView(
                        games: Array(games)
                    )
                        .tag(StatisticsPage.prologues)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Статистика")
        }
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
                        .font(.caption)
                    Text(previousPage.rawValue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(selectedPage.rawValue)
                .font(.headline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                selectedPage = nextPage
            } label: {
                HStack(spacing: 4) {
                    Text(nextPage.rawValue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let game = games[index]
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
