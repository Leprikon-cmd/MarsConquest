//
//  TieBreakerSectionView.swift
//  MarsConquest
//
//  Ввод данных для последовательного разрешения ничьей за первое место.
//

import SwiftUI

struct TieBreakerSectionView: View {
    @Environment(\.locale) private var locale

    @Binding var localGame: LocalGameData

    private let scoreManager = ScoreManager()
    @State private var playersWithEnteredCredits: Set<UUID> = []

    private var tiedLeaderIndices: [Int] {
        let leaderIDs = Set(scoreManager.leadersTiedOnPoints(in: localGame).map(\.id))
        return localGame.players.indices.filter { leaderIDs.contains(localGame.players[$0].id) }
    }

    /// Карты нужны только для игроков, которые не разошлись после сравнения M€.
    private var cardTieIndices: [Int] {
        guard hasEnteredCreditsForAll,
              let maximumCredits = tiedLeaderIndices
                .map({ localGame.players[$0].remainingMegaCredits })
                .max()
        else {
            return []
        }

        let leadersAfterCredits = tiedLeaderIndices.filter {
            localGame.players[$0].remainingMegaCredits == maximumCredits
        }
        return leadersAfterCredits.count > 1 ? leadersAfterCredits : []
    }

    private var hasEnteredCreditsForAll: Bool {
        tiedLeaderIndices.allSatisfy {
            playersWithEnteredCredits.contains(localGame.players[$0].id)
        }
    }

    var body: some View {
        if !tiedLeaderIndices.isEmpty {
            Section(header: Text(isEnglish ? "Tie-breaker for 1st place" : "Тай-брейк за 1 место")) {
                Text(
                    isEnglish
                        ? "Players are first compared by remaining M€."
                        : "Сначала сравниваются оставшиеся M€ всех игроков с равными ПО."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                ForEach(tiedLeaderIndices, id: \.self) { index in
                    megaCreditInput(for: index)
                }

                if hasEnteredCreditsForAll {
                    if cardTieIndices.isEmpty {
                        Text(
                            isEnglish
                                ? "The M€ result determines the winner; cards are not needed."
                                : "Победитель определён по M€; карты не учитываются."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(
                            isEnglish
                                ? "M€ are equal. Compare cards in hand only for these players."
                                : "M€ равны. Теперь сравниваются карты в руке только у этих игроков."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        ForEach(cardTieIndices, id: \.self) { index in
                            cardInput(for: index)
                        }
                    }
                }
            }
        }
    }

    private func megaCreditInput(for index: Int) -> some View {
        playerInput(
            for: index,
            title: isEnglish ? "Remaining M€" : "Остаток M€",
            value: binding(
                for: index,
                keyPath: \.remainingMegaCredits,
                marksCreditInput: true
            )
        )
    }

    private func cardInput(for index: Int) -> some View {
        playerInput(
            for: index,
            title: isEnglish ? "Cards in hand" : "Карты в руке",
            value: binding(for: index, keyPath: \.unplayedCards)
        )
    }

    private func playerInput(
        for index: Int,
        title: String,
        value: Binding<Int32>
    ) -> some View {
        let player = localGame.players[index]

        return HStack(spacing: 10) {
            Circle()
                .fill(Color.named(player.color))
                .frame(width: 14, height: 14)

            Text(player.name)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScoreTextField(value: value)
                    .frame(width: 116)
            }
        }
        .padding(.vertical, 4)
    }

    private func binding(
        for index: Int,
        keyPath: WritableKeyPath<LocalPlayer, Int32>,
        marksCreditInput: Bool = false
    ) -> Binding<Int32> {
        Binding(
            get: { localGame.players[index][keyPath: keyPath] },
            set: { newValue in
                var players = localGame.players
                players[index][keyPath: keyPath] = newValue
                localGame.players = players

                if marksCreditInput {
                    playersWithEnteredCredits.insert(players[index].id)
                }
            }
        )
    }

    private var isEnglish: Bool {
        locale.identifier.lowercased().hasPrefix("en")
    }
}
