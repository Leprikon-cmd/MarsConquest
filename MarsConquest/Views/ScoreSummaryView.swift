//
//  ScoreSummaryView.swift
//  MarsConquest
//
//  Показывает итоговый рейтинг игроков перед сохранением партии.
//

import SwiftUI

struct ScoreSummaryView: View {
    @Environment(\.locale) private var locale

    let localGame: LocalGameData

    private let scoreManager = ScoreManager()

    var body: some View {
        Section(header: Text(isEnglish ? "Ranking" : "Рейтинг")) {
            ForEach(scoreManager.ranking(in: localGame)) { entry in
                HStack(spacing: 12) {
                    Text(placeTitle(for: entry.place))
                        .frame(width: 88, alignment: .leading)

                    Circle()
                        .fill(Color.named(entry.player.color))
                        .frame(width: 14, height: 14)

                    Text(entry.player.name)
                        .lineLimit(1)

                    Spacer()

                    Text("\(entry.score) \(isEnglish ? "VP" : "ПО")")
                        .font(.headline)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func placeTitle(for place: Int) -> String {
        guard isEnglish else {
            switch place {
            case 1: return "🥇 1 место"
            case 2: return "🥈 2 место"
            case 3: return "🥉 3 место"
            default: return "\(place) место"
            }
        }

        switch place {
        case 1: return "🥇 1st Place"
        case 2: return "🥈 2nd Place"
        case 3: return "🥉 3rd Place"
        default: return "\(englishOrdinal(place)) Place"
        }
    }

    private var isEnglish: Bool {
        locale.identifier.lowercased().hasPrefix("en")
    }

    private func englishOrdinal(_ value: Int) -> String {
        let lastTwoDigits = value % 100
        guard !(11...13).contains(lastTwoDigits) else { return "\(value)th" }

        switch value % 10 {
        case 1: return "\(value)st"
        case 2: return "\(value)nd"
        case 3: return "\(value)rd"
        default: return "\(value)th"
        }
    }
}
