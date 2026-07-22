import CoreData
import SwiftUI

/// Главный экран личного журнала владельца.
struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext

  let ownerProfile: OwnerProfile

  var body: some View {
    TabView {
      OwnerDashboardView(ownerProfile: ownerProfile)
        .tabItem {
          Label("Бортовой журнал", systemImage: "person.text.rectangle.fill")
        }

      NavigationStack {
        SettingsScreen()
      }
      .tabItem {
        Label("Настройки", systemImage: "gearshape.fill")
      }
    }
    .tabViewStyle(.tabBarOnly)
    .onAppear {
      generateInitialGameData(in: viewContext)
    }
  }
}

private struct OwnerDashboardView: View {
  @Environment(\.managedObjectContext) private var viewContext

  let ownerProfile: OwnerProfile

  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>

  @State private var showNewExpedition = false

private func isOwner(_ player: Player) -> Bool {
  guard let ownerID = ownerProfile.savedPlayerID else { return false }
  return player.savedPlayerID == ownerID || player.id == ownerID
}

private var owner: SavedPlayer? {

    guard let ownerID = ownerProfile.savedPlayerID else { return nil }
    return OwnerProfileManager.fetchSavedPlayer(with: ownerID, in: viewContext)
  }

  private var ownerGames: [Game] {
    guard ownerProfile.savedPlayerID != nil else { return [] }

    return games.filter { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains { isOwner($0) }
    }
  }

private var journalStats: StatisticsCalculator.OwnerJournalStats {
  guard let ownerID = ownerProfile.savedPlayerID else { return .empty }
  return StatisticsCalculator.ownerJournalStats(ownerID: ownerID, from: ownerGames)
}


  private var hasHistoricalParticipationsToReview: Bool {
    guard let ownerID = ownerProfile.savedPlayerID else { return false }

    return games.contains { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains {
        ($0.savedPlayerID == nil || $0.savedPlayerID == ownerID) && $0.id != ownerID
      }
    }
  }
  var body: some View {
    NavigationStack {
      ZStack {
        Image("fon")
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 18) {
OwnerProfileBadgeView(
  nickname: owner?.nickname ?? owner?.name ?? "Личный журнал",
  realName: owner?.realName,
  colorName: journalStats.favoriteColor ?? owner?.favoriteColor ?? "Синий",
  games: journalStats.games,
  wins: journalStats.wins,
  winRate: journalStats.games > 0
    ? Int((Double(journalStats.wins) / Double(journalStats.games) * 100).rounded())
    : 0,
  averageScore: journalStats.averageScore,
  bestScore: journalStats.bestScore,
  averagePlace: journalStats.averagePlace,
  maxGeneration: journalStats.maxGeneration,
  frequentCorporation: journalStats.frequentCorporation,
  successfulField: journalStats.successfulField,
  fastestWinGeneration: journalStats.fastestWinGeneration
)

            if ownerGames.isEmpty {
              Text("Новые партии, где вы участвуете, появятся здесь после сохранения результата.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.78))
                .padding(.vertical, 4)
            } else if let ownerID = ownerProfile.savedPlayerID {
              RecentExpeditionsView(
                games: Array(ownerGames.prefix(5)),
                ownerID: ownerID
              )
            }

            Button {
              showNewExpedition = true
            } label: {
              Label("Новая экспедиция", systemImage: "rocket.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            NavigationLink {
              StatisticsScreen()
            } label: {
              Label("Открыть общую статистику", systemImage: "chart.bar.xaxis")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            if hasHistoricalParticipationsToReview {
              NavigationLink {
                HistoricalParticipationLinkView(ownerProfile: ownerProfile)
              } label: {
                Label("Проверить прошлые партии", systemImage: "person.text.rectangle")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 13)
              }
              .buttonStyle(.bordered)
              .tint(.white)
            }
          }
          .padding()
        }
      }
      .navigationTitle("Бортовой журнал")
      .navigationBarTitleDisplayMode(.inline)
    }
    .fullScreenCover(isPresented: $showNewExpedition) {
      NewExpeditionView()
    }
  }
}
