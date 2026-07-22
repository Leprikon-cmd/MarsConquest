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

  private var wins: Int {
    ownerGames.reduce(into: 0) { result, game in
      let players = game.players?.allObjects as? [Player] ?? []
      guard let ownerPlayer = players.first(where: isOwner) else {
        return
      }

      let ownerScore = StatisticsCalculator.totalScore(for: ownerPlayer, in: game)
      let bestScore = players.map { StatisticsCalculator.totalScore(for: $0, in: game) }.max()
      if ownerScore == bestScore {
        result += 1
      }
    }
  }

  private var winRate: Int {
    guard !ownerGames.isEmpty else { return 0 }
    return Int((Double(wins) / Double(ownerGames.count) * 100).rounded())
  }

  private var averageScore: Int {
    let scores = ownerScores
    guard !scores.isEmpty else { return 0 }
    return Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
  }

  private var bestScore: Int {
    ownerScores.max() ?? 0
  }

  private var ownerScores: [Int] {
    ownerGames.compactMap { game in
      guard let ownerPlayer = (game.players?.allObjects as? [Player])?.first(where: isOwner) else {
        return nil
      }

      return StatisticsCalculator.totalScore(for: ownerPlayer, in: game)
    }
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
              colorName: owner?.favoriteColor ?? "Синий",
              games: ownerGames.count,
              wins: wins,
              winRate: winRate,
              averageScore: averageScore,
              bestScore: bestScore
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
