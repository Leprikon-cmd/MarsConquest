import SwiftUI

/// Единый бортовой бейдж владельца личного журнала.
struct OwnerProfileBadgeView: View {
  @Environment(\.locale) private var locale
  @AppStorage(OwnerAvatarStyle.storageKey) private var avatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @AppStorage(OwnerSelfieStore.revisionKey) private var selfieRevision = 0
  @State private var showAvatarPicker = false

  let nickname: String
  let realName: String?
  let colorName: String
  let careerLevel: Int
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
    VStack(spacing: 9) {
      VStack(spacing: 0) {
        cardTopBar
          .padding(.horizontal, -6)
        cardTitleBand
          .padding(.horizontal, -6)
        avatarCard
          .padding(.top, -7)
        technicalRail
      }

      VStack(spacing: 9) {
        Text(ceoDossierTitle)
          .font(.caption2.weight(.black))
          .tracking(1.5)
          .foregroundStyle(.black.opacity(0.58))
          .frame(maxWidth: .infinity, alignment: .leading)

        Rectangle()
          .fill(.black.opacity(0.22))
          .frame(height: 1)

        HStack(spacing: 0) {
          metric(value: "\(games)", title: gamesTitle)
          metric(value: "\(wins)", title: winsTitle)
          metric(value: "\(winRate)%", title: winRateTitle)
        }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 6)
      .background(cardPaperColor)
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(.black.opacity(0.15))
          .frame(height: 1)
      }

      Rectangle()
        .fill(.black.opacity(0.15))
        .frame(height: 1)

      HStack(spacing: 0) {
        metric(value: "\(averageScore)", title: averageScoreTitle)
        metric(value: "\(bestScore)", title: bestScoreTitle)
      }
      .padding(.horizontal, 8)

      Rectangle()
        .fill(.black.opacity(0.15))
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
      .padding(.horizontal, 8)

      if hasPreferences {
        Rectangle()
          .fill(.black.opacity(0.15))
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

      Rectangle()
        .fill(.black.opacity(0.5))
        .frame(height: 1)

      Text(corporateDemandPhrase)
        .font(.caption.italic())
        .foregroundStyle(.black.opacity(0.68))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }
    .padding(.init(top: 14, leading: 20, bottom: 24, trailing: 20))
    .background {
      ZStack {
        cardPaperColor

        GeometryReader { proxy in
          Image("employee-card-background-black")
            .resizable()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .mask {
              VStack(spacing: 0) {
                Color.clear
                  .frame(height: 136)
                Rectangle()
                  .fill(.white)
              }
            }
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(color: .black.opacity(0.42), radius: 7, y: 4)
    .sheet(isPresented: $showAvatarPicker) {
      OwnerAvatarPickerView(selection: $avatarStyleRawValue)
    }
  }

  private var cardTopBar: some View {
    ZStack(alignment: .topLeading) {
      CorporateIDCardShape(cut: 10)
        .fill(
          LinearGradient(
            colors: [Color(white: 0.88), Color(white: 0.55), Color(white: 0.80)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay {
          CorporateIDCardShape(cut: 10)
            .stroke(.black.opacity(0.82), lineWidth: 2)
        }

      ZStack {
        CorporateIDCardShape(cut: 9)
          .fill(
            LinearGradient(
              colors: [Color(white: 0.94), Color(white: 0.62)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay {
            CorporateIDCardShape(cut: 9)
              .stroke(.black.opacity(0.82), lineWidth: 2)
          }
          .frame(width: 64, height: 64)

        levelBadge
      }
      .frame(width: 64, height: 64)

    }
    .frame(height: 64)
  }

  private var cardTitleBand: some View {
    VStack(spacing: 2) {
      Text(nickname.uppercased(with: locale))
        .font(.custom("Play-Bold", size: 22))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      HStack(spacing: 6) {
        Text(personalLogTitle)
        if let realName, !realName.isEmpty, realName.caseInsensitiveCompare(nickname) != .orderedSame {
          Text("•")
          Text(realName)
            .lineLimit(1)
        }
      }
      .font(.custom("Play-Bold", size: 11))
      .tracking(0.7)
      .foregroundStyle(.white.opacity(0.7))
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .frame(height: 54)
    .padding(.horizontal, 12)
    .background {
      CardTitleBandShape()
        .fill(
          LinearGradient(
            colors: [.black, Color(white: 0.12), .black],
            startPoint: .top,
            endPoint: .bottom
          )
        )
    }
    .overlay {
      CardTitleBandShape()
        .stroke(
          LinearGradient(
            colors: [.white.opacity(0.62), .gray.opacity(0.42), .white.opacity(0.24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1.5
        )
    }
    .zIndex(1)
  }

  private var technicalRail: some View {
    HStack(spacing: 8) {
      Text("CEO // ID 01")
        .font(.system(size: 8, weight: .black, design: .monospaced))
        .tracking(0.8)
      Spacer()
      ForEach(0..<7, id: \.self) { index in
        Capsule()
          .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.72) : Color.white.opacity(0.24))
          .frame(width: index.isMultiple(of: 2) ? 9 : 4, height: 3)
      }
    }
    .foregroundStyle(.white.opacity(0.66))
    .padding(.horizontal, 6)
  }

  private var levelBadge: some View {
    ZStack {
      Image("level-octagon-yellow")
        .resizable()
        .scaledToFit()

      Text("\(careerLevel)")
        .font(.system(size: 29, weight: .black, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.black.opacity(0.9))
        .shadow(color: .white.opacity(0.7), radius: 0.5, y: -0.5)
        .offset(y: -1)
    }
    .frame(width: 56, height: 56)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(levelAccessibilityLabel)
  }

  private var avatarCard: some View {
    Button {
      showAvatarPicker = true
    } label: {
      ownerAvatarImage
        .frame(maxWidth: .infinity)
        .frame(height: 184)
        .clipShape(CardArtworkShape(cut: 10, notchDepth: 0))
        .overlay {
          CardArtworkShape(cut: 10, notchDepth: 0)
            .stroke(.black.opacity(0.82), lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "camera.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.black.opacity(0.88))
            .padding(8)
            .background(
              LinearGradient(
                colors: [.white, Color(white: 0.62)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              in: Circle()
            )
            .overlay {
              Circle().stroke(.black.opacity(0.72), lineWidth: 1)
            }
            .padding(8)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(ownerAvatarAccessibilityLabel)
    .accessibilityHint(avatarPickerAccessibilityHint)
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
    VStack(alignment: .leading, spacing: 2) {
      Text(value)
        .font(.headline.weight(.bold))
        .foregroundStyle(primaryColor)
      Text(title)
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(primaryColor.opacity(0.62))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  private var hasPreferences: Bool {
    frequentCorporation != nil || successfulField != nil || fastestWinGeneration != nil
  }

  private var avatarStyle: OwnerAvatarStyle {
    OwnerAvatarStyle(rawValue: avatarStyleRawValue) ?? .commander
  }

  private var primaryColor: Color {
    .black
  }

  private var cardPaperColor: Color {
    Color(red: 0.91, green: 0.90, blue: 0.87)
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private var personalLogTitle: String { isEnglish ? "PERSONAL LOG" : "ЛИЧНЫЙ ЖУРНАЛ" }
  private var ceoDossierTitle: String { isEnglish ? "CEO DOSSIER" : "ДОСЬЕ РУКОВОДИТЕЛЯ" }
  private var levelAccessibilityLabel: String { isEnglish ? "Level \(careerLevel)" : "Уровень \(careerLevel)" }
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

  private var corporateDemandPhrase: String {
    switch careerLevel {
    case ...0:
      return isEnglish
        ? "Corporations are only beginning to study this candidate's file."
        : "Корпорации только начинают изучать досье этого кандидата."
    case 1...3:
      return isEnglish
        ? "Junior offices are already competing for the chance to test this CEO in the field."
        : "Младшие представительства уже спорят за право проверить этого CEO в деле."
    case 4...7:
      return isEnglish
        ? "Corporations increasingly request this CEO for demanding Martian projects."
        : "Корпорации всё чаще запрашивают этого CEO для сложных марсианских проектов."
    case 8...11:
      return isEnglish
        ? "Major corporations keep a place open whenever this CEO enters the market."
        : "Крупные корпорации держат место открытым, когда этот CEO выходит на рынок."
    case 12...15:
      return isEnglish
        ? "Boardrooms compete for this CEO before the vacancy is even announced."
        : "Советы директоров борются за этого CEO ещё до объявления вакансии."
    default:
      return isEnglish
        ? "Corporations reshape their strategies for the chance to secure this CEO."
        : "Корпорации меняют стратегии ради возможности заполучить этого CEO."
    }
  }

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

private struct CorporateIDCardShape: Shape {
  let cut: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
    path.closeSubpath()
    return path
  }
}

private struct CardArtworkShape: Shape {
  let cut: CGFloat
  let notchDepth: CGFloat

  func path(in rect: CGRect) -> Path {
    let centerX = rect.midX
    let notchHalfWidth = min(30, rect.width * 0.1)
    var path = Path()

    path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
    path.addLine(to: CGPoint(x: centerX - notchHalfWidth, y: rect.minY))
    path.addQuadCurve(
      to: CGPoint(x: centerX + notchHalfWidth, y: rect.minY),
      control: CGPoint(x: centerX, y: rect.minY + notchDepth)
    )
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
    path.closeSubpath()
    return path
  }
}

private struct CardTitleBandShape: Shape {
  func path(in rect: CGRect) -> Path {
    let sideCut: CGFloat = 8
    let curveDepth: CGFloat = 7
    var path = Path()

    path.move(to: CGPoint(x: rect.minX + sideCut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - sideCut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + sideCut))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - sideCut))
    path.addLine(to: CGPoint(x: rect.maxX - sideCut, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY - curveDepth),
      control: CGPoint(x: rect.width * 0.75, y: rect.maxY)
    )
    path.addQuadCurve(
      to: CGPoint(x: rect.minX + sideCut, y: rect.maxY),
      control: CGPoint(x: rect.width * 0.25, y: rect.maxY)
    )
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - sideCut))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + sideCut))
    path.closeSubpath()
    return path
  }
}
