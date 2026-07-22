import CoreData
import SwiftUI

/// Компактная история последних партий владельца на главном экране журнала.
struct RecentExpeditionsView: View {
  @Environment(\.locale) private var locale

  let games: [Game]
  let ownerID: UUID

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(isEnglish ? "Recent expeditions" : "Последние экспедиции")
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)

      ForEach(games, id: \.objectID) { game in
        NavigationLink {
          GameDetailView(game: game)
        } label: {
          expeditionRow(for: game)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func expeditionRow(for game: Game) -> some View {
    let ownerPlayer = ownerPlayer(in: game)
    let score = ownerPlayer.map { StatisticsCalculator.totalScore(for: $0, in: game) }
    let place = ownerPlayer.map { StatisticsCalculator.place(of: $0, in: game) }

    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text(StatisticsCalculator.formattedDate(game.date, locale: locale))
          .font(.headline)

        Spacer()

        if let place, let score {
          Text("\(placeTitle(place)) · \(score) \(pointsLabel)")
            .font(.subheadline.weight(.semibold))
        }
      }

      Text(GameField.localizedName(
        persistedName: game.gameField,
        referenceID: game.gameFieldID,
        locale: locale
      ))
      .font(.subheadline)
      .foregroundStyle(.secondary)

      HStack(spacing: 6) {
        Text(leadersText(for: game))
        Spacer()
        Text(participantsText(for: game))
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .contentShape(RoundedRectangle(cornerRadius: 8))
  }

  private func ownerPlayer(in game: Game) -> Player? {
    (game.players?.allObjects as? [Player])?.first {
      $0.savedPlayerID == ownerID || $0.id == ownerID
    }
  }

  private func leadersText(for game: Game) -> String {
    guard let players = game.players?.allObjects as? [Player], !players.isEmpty else {
      return isEnglish ? "No players" : "Нет участников"
    }

    let maxScore = players.map { StatisticsCalculator.totalScore(for: $0, in: game) }.max() ?? 0
    let names = players
      .filter { StatisticsCalculator.totalScore(for: $0, in: game) == maxScore }
      .compactMap(\.name)
      .joined(separator: ", ")

    return isEnglish ? "Leader: \(names)" : "Лидер: \(names)"
  }

  private func participantsText(for game: Game) -> String {
    let count = (game.players?.allObjects as? [Player])?.count ?? 0
    return isEnglish ? "Players: \(count)" : "Игроков: \(count)"
  }

  private func placeTitle(_ place: Int) -> String {
    switch place {
    case 1: return "🥇 1"
    case 2: return "🥈 2"
    case 3: return "🥉 3"
    default: return "\(place)"
    }
  }

  private var pointsLabel: String {
    isEnglish ? "VP" : "ПО"
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }
}
