import SwiftUI

/// Единый бортовой бейдж владельца личного журнала.
struct OwnerProfileBadgeView: View {
  let nickname: String
  let realName: String?
  let colorName: String
  let games: Int
  let wins: Int
  let winRate: Int
  let averageScore: Int
  let bestScore: Int

  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .center, spacing: 14) {
        ZStack {
          Circle()
            .fill(Color.named(colorName).opacity(0.32))
          Circle()
            .stroke(Color.named(colorName), lineWidth: 2)
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

          Text(nickname)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)

          if let realName, !realName.isEmpty, realName.caseInsensitiveCompare(nickname) != .orderedSame {
            Text(realName)
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.78))
          }
        }

        Spacer()

        Image(systemName: "shield.lefthalf.filled")
          .font(.title2)
          .foregroundStyle(Color.named(colorName))
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
}
