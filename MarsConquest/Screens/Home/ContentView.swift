//
//  ContentView.swift
//
//  Зачем:
//  Собирает главный экран личного журнала и нижнюю навигацию iPhone.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - состав разделов, подписи и иконки нижней навигации; порядок влияет на привычный маршрут владельца.
//
import CoreData
import SwiftUI

/// Главный экран личного журнала владельца.
struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext

  let ownerProfile: OwnerProfile

  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>

  @State private var selectedSection: JournalSection = .journal

  var body: some View {
    ZStack {
      switch selectedSection {
      case .journal:
        OwnerDashboardView(ownerProfile: ownerProfile)
      case .newGame:
        NewExpeditionView()
      case .regalia:
        RegaliaView(ownerProfile: ownerProfile)
      case .statistics:
        StatisticsScreen()
      case .settings:
        SettingsScreen(ownerProfile: ownerProfile)
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      journalNavigation
    }
    .onAppear {
      generateInitialGameData(in: viewContext)
    }
  }

  private var journalNavigation: some View {
    HStack(spacing: 8) {
      navigationButton(
        title: "Бортовой журнал",
        imageName: "journal",
        section: .journal
      )

      newExpeditionButton

      navigationButton(title: "Статистика", imageName: "statistics", section: .statistics)

      if hasVisibleRegalia {
        navigationButton(title: "Регалии", imageName: "achievements", section: .regalia)
      }
      navigationButton(title: "Настройки", imageName: "settings", section: .settings)
    }
    .padding(8)
    .background(.ultraThinMaterial, in: Capsule(style: .continuous))
    .overlay {
      Capsule(style: .continuous)
        .strokeBorder(.white.opacity(0.32), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    .padding(.horizontal, 14)
    .padding(.bottom, 6)
    .accessibilityIdentifier("root-navigation")
  }

  private var hasVisibleRegalia: Bool {
    guard let ownerID = ownerProfile.savedPlayerID else { return false }
    let ownerGames = games.filter { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains { $0.savedPlayerID == ownerID || $0.id == ownerID }
    }
    let calculator = CareerProgressCalculator()
    let progress = calculator.calculate(ownerID: ownerID, from: ownerGames)
    return calculator.hasVisibleRegalia(for: progress)
      || !calculator.professionalTitles(ownerID: ownerID, from: ownerGames).isEmpty
  }

  private func navigationButton(
    title: String,
    imageName: String,
    section: JournalSection
  ) -> some View {
    Button {
      selectedSection = section
    } label: {
      Image(imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 42, height: 42)
        .frame(maxWidth: .infinity, minHeight: 42)
        .opacity(selectedSection == section ? 1 : 0.72)
        .background(selectedSection == section ? .white.opacity(0.16) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityIdentifier("root-navigation-\(section.rawValue)")
  }

  private var newExpeditionButton: some View {
    Button {
      selectedSection = .newGame
    } label: {
      Image("new-game")
        .resizable()
        .scaledToFit()
        .frame(width: 42, height: 42)
        .frame(maxWidth: .infinity, minHeight: 42)
        .opacity(selectedSection == .newGame ? 1 : 0.72)
        .background(selectedSection == .newGame ? .white.opacity(0.16) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Новая игра")
    .accessibilityIdentifier("root-navigation-new-game")
  }
}

private enum JournalSection: String {
  case journal
  case newGame
  case regalia
  case statistics
  case settings
}

private struct OwnerDashboardView: View {
  @Environment(\.managedObjectContext) private var viewContext

  let ownerProfile: OwnerProfile

  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>

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

private var careerLevel: Int {
  guard let ownerID = ownerProfile.savedPlayerID else { return 0 }
  let calculator = CareerProgressCalculator()
  return calculator.level(for: calculator.calculate(ownerID: ownerID, from: ownerGames))
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
  careerLevel: careerLevel,
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
                .font(AppFont.font(.footnote))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.vertical, 4)
            } else if let ownerID = ownerProfile.savedPlayerID {
              RecentExpeditionsView(
                games: Array(ownerGames.prefix(5)),
                ownerID: ownerID
              )
            }

          }
          .padding(.horizontal)
          // Нижняя навигация накладывается поверх корневого экрана. На iPhone
          // оставляем запас, чтобы последние действия журнала можно было
          // полностью прокрутить выше неё.
          .padding(.bottom, 16 + JournalNavigationLayout.contentBottomClearance)
          .padding(.top, 56)
          .adaptiveContentWidth(560)
        }
        .accessibilityIdentifier("owner-dashboard")
      }
    }
  }
}
