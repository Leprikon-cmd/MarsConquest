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
                        onDelete: deleteGames
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
        HStack(spacing: 12) {
            ForEach(StatisticsPage.allCases, id: \.self) { page in
                Button {
                    selectedPage = page
                } label: {
                    HStack(spacing: 4) {
                        if page != .games {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                                .opacity(page == selectedPage ? 0.8 : 0.4)
                        }

                        Text(page.rawValue)
                            .font(.subheadline)
                            .bold()

                        if page != .prologues {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .opacity(page == selectedPage ? 0.8 : 0.4)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(selectedPage == page ? Color.blue.opacity(0.15) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
}
