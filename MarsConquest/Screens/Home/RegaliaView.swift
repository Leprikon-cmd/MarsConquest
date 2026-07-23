import CoreData
import SwiftUI

/// Личная коллекция карьерных вех владельца журнала.
/// Игровые достижения Terraforming Mars остаются частью конкретной партии.
struct RegaliaView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.locale) private var locale

  let ownerProfile: OwnerProfile

  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>

  private var ownerGames: [Game] {
    guard let ownerID = ownerProfile.savedPlayerID else { return [] }

    return games.filter { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains { $0.savedPlayerID == ownerID || $0.id == ownerID }
    }
  }

  private var progress: CareerProgressCalculator.Progress {
    guard let ownerID = ownerProfile.savedPlayerID else { return .empty }
    return CareerProgressCalculator().calculate(ownerID: ownerID, from: ownerGames)
  }

  private var level: Int {
    CareerProgressCalculator().level(for: progress)
  }

  private var regalia: [CareerProgressCalculator.Regalia] {
    guard let ownerID = ownerProfile.savedPlayerID else { return [] }
    return CareerProgressCalculator().regalia(ownerID: ownerID, from: ownerGames)
  }

  private var earnedDiscoveries: [CareerProgressCalculator.Regalia] {
    regalia.filter { $0.kind != .milestone }
  }

  private var professionalTitles: [CareerProgressCalculator.ProfessionalTitle] {
    guard let ownerID = ownerProfile.savedPlayerID else { return [] }
    return CareerProgressCalculator().professionalTitles(ownerID: ownerID, from: ownerGames)
  }

  private var reachedMilestones: [(games: Int, value: Int)] {
    CareerProgressCalculator.ExperienceRules.initial.milestones
      .sorted { $0.key < $1.key }
      .compactMap { games, value in
        progress.gamesPlayed >= games ? (games, value) : nil
      }
  }

  private var nextMilestone: (games: Int, value: Int)? {
    CareerProgressCalculator.ExperienceRules.initial.milestones
      .sorted { $0.key < $1.key }
      .first { $0.key > progress.gamesPlayed }
      .map { ($0.key, $0.value) }
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
            careerCard
            professionalTitlesSection
            earnedRegaliaSection
            milestonesSection
            futureRegaliaSection
          }
          .padding()
        }
      }
      .navigationTitle(regaliaTitle)
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  @ViewBuilder
  private var professionalTitlesSection: some View {
    if !professionalTitles.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        Label(professionalTitlesTitle, systemImage: "briefcase.fill")
          .font(.title3.weight(.bold))
          .foregroundStyle(.white)

        ForEach(professionalTitles) { title in
          HStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
              .font(.title3)
              .foregroundStyle(.yellow)
              .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
              Text(professionalTitleName(title.kind))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
              Text(title.detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
          }
          .padding(13)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }
    }
  }

  private var earnedRegaliaSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(earnedRegaliaTitle, systemImage: "medal.fill")
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)

      ForEach(earnedDiscoveries) { item in
        HStack(spacing: 12) {
          Image(systemName: regaliaIcon(item.kind))
            .font(.title3)
            .foregroundStyle(.yellow)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 2) {
            Text(regaliaName(item))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.white)
            if item.kind != .newCorporationPreludePair,
               let detail = item.detail,
               !detail.isEmpty {
              Text(regaliaDetail(for: item))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
          }
          Spacer()
        }
        .padding(13)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
  }

  private var careerCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
              LinearGradient(
                colors: [.yellow, .orange.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )

          VStack(spacing: -1) {
            Text("LV")
              .font(.caption2.weight(.black))
              .tracking(0.8)
            Text("\(level)")
              .font(.system(size: 37, weight: .black, design: .rounded))
              .monospacedDigit()
          }
          .foregroundStyle(.black.opacity(0.85))
        }
        .frame(width: 78, height: 88)

        VStack(alignment: .leading, spacing: 7) {
          Label(careerPathTitle, systemImage: "medal.star.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.orange)

          Text(levelTitle)
            .font(.title3.weight(.bold))
            .foregroundStyle(primaryColor)

          Text(levelDescription)
            .font(.subheadline)
            .foregroundStyle(primaryColor.opacity(0.74))
        }
      }

      Divider().overlay(primaryColor.opacity(0.16))

      HStack(spacing: 0) {
        statistic(value: "\(progress.gamesPlayed)", title: gamesTitle)
        statistic(value: "\(progress.wins)", title: winsTitle)
        statistic(value: "\(progress.secondPlaces)", title: secondPlacesTitle)
      }
    }
    .padding(16)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(primaryColor.opacity(0.22), lineWidth: 1)
    }
  }

  private var milestonesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(milestonesTitle, systemImage: "flag.checkered")
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)

      if reachedMilestones.isEmpty {
        emptyMilestones
      } else {
        ForEach(reachedMilestones, id: \.games) { milestone in
          milestoneRow(games: milestone.games, isReached: true)
        }
      }

      if let nextMilestone {
        milestoneRow(games: nextMilestone.games, isReached: false)
      }
    }
  }

  private var emptyMilestones: some View {
    Text(firstMilestoneHint)
      .font(.subheadline)
      .foregroundStyle(.white.opacity(0.78))
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func milestoneRow(games: Int, isReached: Bool) -> some View {
    HStack(spacing: 12) {
      Image(systemName: isReached ? "checkmark.seal.fill" : "seal")
        .font(.title2)
        .foregroundStyle(isReached ? .yellow : .white.opacity(0.52))
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 2) {
        Text(milestoneTitle(games))
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
        Text(isReached ? milestoneReachedTitle : milestoneUpcomingTitle)
          .font(.caption)
          .foregroundStyle(.white.opacity(isReached ? 0.74 : 0.56))
      }

      Spacer()
    }
    .padding(13)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private var futureRegaliaSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(futureRegaliaTitle, systemImage: "sparkles")
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)

      Text(futureRegaliaDescription)
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.78))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
  }

  private func statistic(value: String, title: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(value)
        .font(.title3.weight(.bold))
        .foregroundStyle(primaryColor)
      Text(title)
        .font(.caption2.weight(.bold))
        .foregroundStyle(primaryColor.opacity(0.62))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var primaryColor: Color {
    colorScheme == .light ? .black : .white
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var regaliaTitle: String { isEnglish ? "Honors" : "Регалии" }
  private var careerPathTitle: String { isEnglish ? "CAREER PATH" : "КАРЬЕРНЫЙ ПУТЬ" }
  private var levelTitle: String { isEnglish ? "Level \(level)" : "Уровень \(level)" }
  private var levelDescription: String {
    progress.gamesPlayed == 0
      ? (isEnglish ? "Your first expedition will begin your career." : "Первая экспедиция откроет карьерный путь.")
      : (isEnglish ? "Your progress is built from confirmed expedition results." : "Путь складывается из подтверждённых результатов экспедиций.")
  }
  private var gamesTitle: String { isEnglish ? "EXPEDITIONS" : "ЭКСПЕДИЦИЙ" }
  private var winsTitle: String { isEnglish ? "WINS" : "ПОБЕД" }
  private var secondPlacesTitle: String { isEnglish ? "SECOND PLACES" : "ВТОРЫХ МЕСТ" }
  private var milestonesTitle: String { isEnglish ? "CAREER MILESTONES" : "КАРЬЕРНЫЕ ВЕХИ" }
  private var firstMilestoneHint: String {
    isEnglish ? "Your first career milestone unlocks after 5 expeditions." : "Первая карьерная веха откроется после 5 экспедиций."
  }
  private var milestoneReachedTitle: String { isEnglish ? "Regalia received" : "Регалия получена" }
  private var milestoneUpcomingTitle: String { isEnglish ? "Next career milestone" : "Следующая карьерная веха" }
  private var futureRegaliaTitle: String { isEnglish ? "FUTURE REGALIA" : "БУДУЩИЕ РЕГАЛИИ" }
  private var earnedRegaliaTitle: String { isEnglish ? "EARNED REGALIA" : "ПОЛУЧЕННЫЕ РЕГАЛИИ" }
  private var professionalTitlesTitle: String { isEnglish ? "PROFESSIONAL TITLES" : "ПРОФЕССИОНАЛЬНЫЕ ТИТУЛЫ" }
  private var futureRegaliaDescription: String {
    isEnglish
      ? "Professional titles, records, and rare career events will appear here as they become verifiable from your journal history."
      : "Профессиональные титулы, рекорды и редкие карьерные события появятся здесь, когда их можно будет честно подтвердить историей журнала."
  }

  private func milestoneTitle(_ games: Int) -> String {
    isEnglish ? "\(games) expeditions" : "\(games) экспедиций"
  }

  private func regaliaIcon(_ kind: CareerProgressCalculator.RegaliaKind) -> String {
    switch kind {
    case .firstExpedition: "rocket.fill"
    case .firstVictory: "trophy.fill"
    case .newField: "map.fill"
    case .newCorporation: "building.2.fill"
    case .newPrelude: "sparkles"
    case .newCorporationPreludePair: "link"
    case .newColony: "globe.americas.fill"
    case .firstExpeditionWithExpansion: "puzzlepiece.extension.fill"
    case .firstVictoryWithExpansion: "puzzlepiece.extension.fill"
    case .firstVictoryWithField: "map.circle.fill"
    case .firstVictoryWithCorporation: "building.2.crop.circle.fill"
    case .firstVictoryWithPrelude: "sparkles.square.fill"
    case .milestone: "flag.checkered"
    }
  }

  private func regaliaName(_ item: CareerProgressCalculator.Regalia) -> String {
    switch item.kind {
    case .firstExpedition: return isEnglish ? "First expedition" : "Первая экспедиция"
    case .firstVictory: return isEnglish ? "First victory" : "Первая победа"
    case .newField: return isEnglish ? "New board explored" : "Освоено новое поле"
    case .newCorporation: return isEnglish ? "New corporation" : "Новая корпорация"
    case .newPrelude: return isEnglish ? "New prelude" : "Новый пролог"
    case .newCorporationPreludePair: return isEnglish ? "New strategic pairing" : "Новая стратегическая связка"
    case .newColony: return isEnglish ? "New colony explored" : "Освоена новая колония"
    case .firstExpeditionWithExpansion: return isEnglish ? "First expedition with this expansion" : "Первая экспедиция с этим дополнением"
    case .firstVictoryWithExpansion: return isEnglish ? "First victory with this expansion" : "Первая победа с этим дополнением"
    case .firstVictoryWithField: return isEnglish ? "First victory on this board" : "Первая победа на этом поле"
    case .firstVictoryWithCorporation: return isEnglish ? "First victory with this corporation" : "Первая победа этой корпорацией"
    case .firstVictoryWithPrelude: return isEnglish ? "First victory with this prelude" : "Первая победа с этим прологом"
    case .milestone: return isEnglish ? "Career milestone" : "Карьерная веха"
    }
  }

  private func professionalTitleName(_ kind: CareerProgressCalculator.ProfessionalTitleKind) -> String {
    switch kind {
    case .corporationSpecialist:
      return isEnglish ? "Corporate insider" : "Человек корпорации"
    }
  }

  private func regaliaDetail(for item: CareerProgressCalculator.Regalia) -> String {
    guard item.kind == .firstExpeditionWithExpansion || item.kind == .firstVictoryWithExpansion else {
      return item.detail ?? ""
    }
    switch item.detail {
    case "prelude": return isEnglish ? "Prelude" : "Пролог"
    case "venus": return isEnglish ? "Venus Next" : "Венера"
    case "colonies": return isEnglish ? "Colonies" : "Колонии"
    case "hellasElysium": return isEnglish ? "Hellas & Elysium" : "Эллада и Элизий"
    case "turmoil": return isEnglish ? "Turmoil" : "Кризис"
    default: return item.detail ?? ""
    }
  }
}
