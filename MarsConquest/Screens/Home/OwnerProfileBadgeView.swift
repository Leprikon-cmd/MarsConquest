import SwiftUI

/// Единый бортовой бейдж владельца личного журнала.
struct OwnerProfileBadgeView: View {
  @Environment(\.locale) private var locale

  let nickname: String
  let realName: String?
  let colorName: String
  let games: Int
  let wins: Int
  let winRate: Int
  let averageScore: Int
  let bestScore: Int
  let averagePlace: Int
  let maxGeneration: Int
  let frequentCorporation: StatisticsCalculator.OwnerJournalStats.CorporationPreference?
  let successfulField: StatisticsCalculator.OwnerJournalStats.FieldPreference?
  let fastestWinGeneration: Int?

  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .center, spacing: 14) {
        ZStack {
          Circle()
            .fill(.white.opacity(0.14))
          Circle()
            .stroke(.white.opacity(0.36), lineWidth: 1)
          Image(systemName: "person.fill")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
        }
        .frame(width: 64, height: 64)
        .accessibilityLabel("Аватар владельца журнала")

        VStack(alignment: .leading, spacing: 4) {
          Text("ЛИЧНЫЙ ЖУРНАЛ")
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.65))

          HStack(spacing: 8) {
            Image(systemName: "cube.fill")
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(Color.named(colorName))
              .accessibilityLabel("Игровой цвет: \(colorName)")

            Text(nickname)
              .font(.title2.weight(.bold))
              .foregroundStyle(.white)
          }

          if let realName, !realName.isEmpty, realName.caseInsensitiveCompare(nickname) != .orderedSame {
            Text(realName)
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.78))
          }
        }

        Spacer()

        Image(systemName: "shield.lefthalf.filled")
          .font(.title2)
          .foregroundStyle(.white.opacity(0.72))
      }

      Rectangle()
        .fill(.white.opacity(0.16))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(value: "\(games)", title: "СЫГРАНО ПАРТИЙ")
        metric(value: "\(wins)", title: "ПОБЕД")
        metric(value: "\(winRate)%", title: "ПРОЦЕНТ ПОБЕД")
      }

      Rectangle()
        .fill(.white.opacity(0.12))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(value: "\(averageScore)", title: "СРЕДНИЙ РЕЗУЛЬТАТ")
        metric(value: "\(bestScore)", title: "ЛУЧШИЙ РЕЗУЛЬТАТ")
      }

      Rectangle()
        .fill(.white.opacity(0.12))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(
          value: averagePlace > 0 ? "\(averagePlace)" : "—",
          title: "СРЕДНЕЕ МЕСТО"
        )
        metric(
          value: maxGeneration > 0 ? "\(maxGeneration)" : "—",
          title: "МАКС. ПОКОЛЕНИЕ"
        )
      }

      if hasPreferences {
        Rectangle()
          .fill(.white.opacity(0.12))
          .frame(height: 1)

        VStack(alignment: .leading, spacing: 10) {
          Text(preferencesTitle)
            .font(.caption2.weight(.bold))
            .tracking(1.1)
            .foregroundStyle(.white.opacity(0.62))

          if let frequentCorporation {
            preferenceRow(
              icon: "building.2.fill",
              title: frequentCorporationTitle,
              value: frequentCorporation.name,
              detail: gamesAndWins(
                games: frequentCorporation.games,
                wins: frequentCorporation.wins
              )
            )
          }

          if let successfulField {
            preferenceRow(
              icon: "map.fill",
              title: successfulFieldTitle,
              value: GameField.localizedName(
                persistedName: successfulField.persistedName,
                referenceID: successfulField.referenceID,
                locale: locale
              ),
              detail: gamesAndWins(games: successfulField.games, wins: successfulField.wins)
            )
          }

          if let fastestWinGeneration {
            preferenceRow(
              icon: "bolt.fill",
              title: fastestWinTitle,
              value: generationsText(fastestWinGeneration),
              detail: fastestWinDetail
            )
          }
        }
      }
    }
    .padding(18)
    .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.28), lineWidth: 1)
    }
  }

  private func metric(value: String, title: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(value)
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)
      Text(title)
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white.opacity(0.62))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  private var hasPreferences: Bool {
    frequentCorporation != nil || successfulField != nil || fastestWinGeneration != nil
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var preferencesTitle: String {
    isEnglish ? "PREFERENCES AND RECORDS" : "ПРЕДПОЧТЕНИЯ И РЕКОРДЫ"
  }

  private var frequentCorporationTitle: String {
    isEnglish ? "MOST PLAYED CORPORATION" : "ЧАСТАЯ КОРПОРАЦИЯ"
  }

  private var successfulFieldTitle: String {
    isEnglish ? "MOST SUCCESSFUL BOARD" : "САМОЕ УСПЕШНОЕ ПОЛЕ"
  }

  private var fastestWinTitle: String {
    isEnglish ? "FASTEST WIN" : "САМАЯ БЫСТРАЯ ПОБЕДА"
  }

  private var fastestWinDetail: String {
    isEnglish ? "winning game" : "победная партия"
  }

  private func gamesAndWins(games: Int, wins: Int) -> String {
    let winRate = Int((Double(wins) / Double(games) * 100).rounded())
    return isEnglish
      ? "\(games) games · \(winRate)% wins"
      : "\(games) игр · \(winRate)% побед"
  }

  private func generationsText(_ generation: Int) -> String {
    isEnglish ? "Generation \(generation)" : "Поколение \(generation)"
  }

  private func preferenceRow(
    icon: String,
    title: String,
    value: String,
    detail: String
  ) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: icon)
        .font(.subheadline.weight(.semibold))
        .frame(width: 20)
        .foregroundStyle(.white.opacity(0.72))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption2.weight(.bold))
          .foregroundStyle(.white.opacity(0.62))
        Text(value)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.white.opacity(0.72))
      }
    }
  }

}
