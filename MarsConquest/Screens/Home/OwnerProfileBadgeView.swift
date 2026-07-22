import SwiftUI

/// Единый бортовой бейдж владельца личного журнала.
struct OwnerProfileBadgeView: View {
  @Environment(\.locale) private var locale
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(OwnerBadgeStyle.storageKey) private var badgeStyleRawValue = OwnerBadgeStyle.marsFrontier.rawValue
  @AppStorage(OwnerAvatarStyle.storageKey) private var avatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @AppStorage(OwnerSelfieStore.revisionKey) private var selfieRevision = 0
  @State private var showAvatarPicker = false

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
        Button {
          showAvatarPicker = true
        } label: {
          ownerAvatarImage
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay {
              Circle()
                .stroke(primaryColor.opacity(0.48), lineWidth: 1)
            }
            .overlay(alignment: .bottomTrailing) {
              Image(systemName: "camera.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(.orange, in: Circle())
                .overlay {
                  Circle().stroke(.white.opacity(0.85), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ownerAvatarAccessibilityLabel)
        .accessibilityHint(avatarPickerAccessibilityHint)

        VStack(alignment: .leading, spacing: 4) {
          Text(personalLogTitle)
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(primaryColor.opacity(0.65))

          HStack(spacing: 8) {
            Image(systemName: "cube.fill")
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(Color.named(colorName))
              .accessibilityLabel(gameColorAccessibilityLabel)

            Text(nickname)
              .font(.title2.weight(.bold))
              .foregroundStyle(primaryColor)
          }

          if let realName, !realName.isEmpty, realName.caseInsensitiveCompare(nickname) != .orderedSame {
            Text(realName)
              .font(.subheadline)
              .foregroundStyle(primaryColor.opacity(0.78))
          }
        }

        Spacer()

        Image(systemName: "shield.lefthalf.filled")
          .font(.title2)
          .foregroundStyle(primaryColor.opacity(0.72))
      }

      Rectangle()
        .fill(primaryColor.opacity(0.16))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(value: "\(games)", title: gamesTitle)
        metric(value: "\(wins)", title: winsTitle)
        metric(value: "\(winRate)%", title: winRateTitle)
      }

      Rectangle()
        .fill(primaryColor.opacity(0.12))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(value: "\(averageScore)", title: averageScoreTitle)
        metric(value: "\(bestScore)", title: bestScoreTitle)
      }

      Rectangle()
        .fill(primaryColor.opacity(0.12))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(
          value: averagePlace > 0 ? "\(averagePlace)" : "—",
          title: averagePlaceTitle
        )
        metric(
          value: maxGeneration > 0 ? "\(maxGeneration)" : "—",
          title: maxGenerationTitle
        )
      }

      if hasPreferences {
        Rectangle()
          .fill(primaryColor.opacity(0.12))
          .frame(height: 1)

        VStack(alignment: .leading, spacing: 10) {
          Text(preferencesTitle)
            .font(.caption2.weight(.bold))
            .tracking(1.1)
            .foregroundStyle(primaryColor.opacity(0.62))

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
    .background {
      Image(badgeAssetName)
        .resizable()
        .scaledToFill()
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(primaryColor.opacity(0.28), lineWidth: 1)
    }
    .sheet(isPresented: $showAvatarPicker) {
      OwnerAvatarPickerView(selection: $avatarStyleRawValue)
    }
  }

  @ViewBuilder
  private var ownerAvatarImage: some View {
    if avatarStyle == .selfie, let image = OwnerSelfieStore.load() {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .id(selfieRevision)
    } else {
      Image(avatarStyle.assetName)
        .resizable()
        .scaledToFill()
    }
  }

  private func metric(value: String, title: String) -> some View {
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
  private var hasPreferences: Bool {
    frequentCorporation != nil || successfulField != nil || fastestWinGeneration != nil
  }

  private var badgeStyle: OwnerBadgeStyle {
    OwnerBadgeStyle(rawValue: badgeStyleRawValue) ?? .marsFrontier
  }

  private var avatarStyle: OwnerAvatarStyle {
    OwnerAvatarStyle(rawValue: avatarStyleRawValue) ?? .commander
  }

  private var badgeAssetName: String {
    badgeStyle.assetName(isLightMode: colorScheme == .light)
  }

  private var primaryColor: Color {
    colorScheme == .light ? .black : .white
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var personalLogTitle: String { isEnglish ? "PERSONAL LOG" : "ЛИЧНЫЙ ЖУРНАЛ" }
  private var ownerAvatarAccessibilityLabel: String { isEnglish ? "Journal owner avatar" : "Аватар владельца журнала" }
  private var avatarPickerAccessibilityHint: String { isEnglish ? "Opens avatar selection" : "Открывает выбор аватара" }
  private var gameColorAccessibilityLabel: String { isEnglish ? "Game color: \(localizedColorName)" : "Игровой цвет: \(colorName)" }
  private var gamesTitle: String { isEnglish ? "GAMES PLAYED" : "СЫГРАНО ПАРТИЙ" }
  private var winsTitle: String { isEnglish ? "WINS" : "ПОБЕД" }
  private var winRateTitle: String { isEnglish ? "WIN RATE" : "ПРОЦЕНТ ПОБЕД" }
  private var averageScoreTitle: String { isEnglish ? "AVERAGE SCORE" : "СРЕДНИЙ РЕЗУЛЬТАТ" }
  private var bestScoreTitle: String { isEnglish ? "BEST SCORE" : "ЛУЧШИЙ РЕЗУЛЬТАТ" }
  private var averagePlaceTitle: String { isEnglish ? "AVERAGE PLACE" : "СРЕДНЕЕ МЕСТО" }
  private var maxGenerationTitle: String { isEnglish ? "MAX GENERATION" : "МАКС. ПОКОЛЕНИЕ" }

  private var localizedColorName: String {
    switch colorName {
    case "Красный": return "Red"
    case "Синий": return "Blue"
    case "Желтый": return "Yellow"
    case "Зеленый": return "Green"
    case "Черный": return "Black"
    default: return colorName
    }
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
        .foregroundStyle(primaryColor.opacity(0.72))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption2.weight(.bold))
          .foregroundStyle(primaryColor.opacity(0.62))
        Text(value)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(primaryColor)
        Text(detail)
          .font(.caption)
          .foregroundStyle(primaryColor.opacity(0.72))
      }
    }
  }

}
