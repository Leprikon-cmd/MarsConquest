//
//  ScoreTableView.swift
//
//  Зачем:
//  Отображает таблицу ввода основных очков игроков в текущей партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - показать игроков по цветам
//  - показать основные категории очков
//  - дать возможность вручную вводить очки по каждой категории
//  - назначать очки за выбранные достижения и награды
//  - обновлять localGame.players при изменении значений
//

import SwiftUI

struct ScoreTableView: View {
    /// Локальная модель текущей игры, которую пользователь заполняет до сохранения.
    @Binding var localGame: LocalGameData
    
    /// Упрощённый доступ к игрокам текущей партии.
    private var players: [LocalPlayer] {
        localGame.players
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            playersHeader()
            mainScoreCategories()
            bonusScoreCategories()
        }
        .padding(.vertical, 10)
    }

    /// Верхняя строка таблицы с колонкой категорий и цветами игроков.
    private func playersHeader() -> some View {
        HStack {
            Text("Категория")
                .frame(width: 120, alignment: .leading)
            
            ForEach(players) { player in
                Circle()
                    .fill(Color.named(player.color))
                    .frame(width: 20, height: 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .font(.headline)
    }

    /// Основные категории очков, вводимые вручную.
    private func mainScoreCategories() -> some View {
        Group {
            scoreRow(title: "Рейтинг", keyPath: \.terraformingRating)
            scoreRow(title: "Озеленение", keyPath: \.greenery)
            scoreRow(title: "Города", keyPath: \.cities)
            scoreRow(title: "Победы", keyPath: \.victoryPoints)
            scoreRow(title: "Ресурсы", keyPath: \.resourcesOnCards)
            scoreRow(title: "Условия", keyPath: \.conditionsOnCards)

            if localGame.expansions.hasTurmoil {
                scoreRow(title: "Политика", keyPath: \.politics)
            }
        }
    }

    /// Выбранные награды и достижения продолжают основную таблицу,
    /// чтобы все начисляемые очки были в одном месте.
    @ViewBuilder
    private func bonusScoreCategories() -> some View {
        if !localGame.achievements.isEmpty || !localGame.awards.isEmpty {
            Divider()
                .padding(.vertical, 2)

            if !localGame.achievements.isEmpty {
                Text("Достижения")
                    .font(.headline)

                ForEach(localGame.achievements.indices, id: \.self) { index in
                    achievementRow(index: index)
                }
            }

            if !localGame.awards.isEmpty {
                Text("Награды")
                    .font(.headline)
                    .padding(.top, localGame.achievements.isEmpty ? 0 : 4)

                ForEach(localGame.awards.indices, id: \.self) { index in
                    awardRows(index: index)
                }
            }
        }
    }

    /// Одна строка таблицы для конкретной категории очков.
    ///
    /// - Parameters:
    ///   - title: название категории
    ///   - keyPath: путь к соответствующему полю в LocalScore
    ///
    /// Для каждого игрока создаётся поле ввода числа.
    /// При изменении значения обновляется localGame.players.
    private func scoreRow(title: String, keyPath: WritableKeyPath<LocalScore, Int32>) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
            
            ForEach(players.indices, id: \.self) { index in
                ScoreTextField(
                    value: Binding<Int32>(
                        get: { localGame.players[index].score[keyPath: keyPath] },
                        set: { newValue in
                            var updatedPlayers = localGame.players
                            updatedPlayers[index].score[keyPath: keyPath] = newValue
                            localGame.players = updatedPlayers
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    /// Кнопка назначения бонуса. До выбора показывается круг, после - число очков.
    private func bonusValueButton(
        points: Int,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if isSelected {
                    Text("\(points)")
                        .font(.headline)
                        .monospacedDigit()
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 28))
                }
            }
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Одна строка достижения: каждый игрок может получить его только один раз.
    private func achievementRow(index: Int) -> some View {
        let achievement = localGame.achievements[index]

        return HStack {
            Text(achievement.name)
                .frame(width: 120, alignment: .leading)

            ForEach(players, id: \.id) { player in
                let isSelected = achievement.winnerPlayerIDs.contains(player.id)

                bonusValueButton(points: 5, isSelected: isSelected, color: .green) {
                    toggleAchievementWinner(achievementIndex: index, playerID: player.id)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// Награда содержит строку первого места и, при допустимых условиях, второго.
    @ViewBuilder
    private func awardRows(index: Int) -> some View {
        let award = localGame.awards[index]
        let hasTieForFirst = award.firstPlacePlayerIDs.count > 1

        Text(award.name)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)

        awardPlaceRow(
            medal: "🥇",
            points: 5,
            selectedPlayerIDs: award.firstPlacePlayerIDs,
            color: .yellow
        ) { playerID in
            toggleAwardFirstPlace(awardIndex: index, playerID: playerID)
        }

        if players.count >= 3 && !hasTieForFirst {
            awardPlaceRow(
                medal: "🥈",
                points: 2,
                selectedPlayerIDs: award.secondPlacePlayerIDs,
                color: .orange,
                disabledPlayerIDs: award.firstPlacePlayerIDs
            ) { playerID in
                toggleAwardSecondPlace(awardIndex: index, playerID: playerID)
            }
        }
    }

    private func awardPlaceRow(
        medal: String,
        points: Int,
        selectedPlayerIDs: [UUID],
        color: Color,
        disabledPlayerIDs: [UUID] = [],
        action: @escaping (UUID) -> Void
    ) -> some View {
        HStack {
            Text(medal)
                .frame(width: 120, alignment: .leading)

            ForEach(players, id: \.id) { player in
                let isDisabled = disabledPlayerIDs.contains(player.id)

                bonusValueButton(
                    points: points,
                    isSelected: selectedPlayerIDs.contains(player.id),
                    color: isDisabled ? .gray : color
                ) {
                    action(player.id)
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.4 : 1)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func toggleAchievementWinner(achievementIndex: Int, playerID: UUID) {
        if localGame.achievements[achievementIndex].winnerPlayerIDs.contains(playerID) {
            localGame.achievements[achievementIndex].winnerPlayerIDs.removeAll()
        } else {
            localGame.achievements[achievementIndex].winnerPlayerIDs = [playerID]
        }
    }

    private func toggleAwardFirstPlace(awardIndex: Int, playerID: UUID) {
        if localGame.awards[awardIndex].firstPlacePlayerIDs.contains(playerID) {
            localGame.awards[awardIndex].firstPlacePlayerIDs.removeAll { $0 == playerID }
        } else {
            localGame.awards[awardIndex].firstPlacePlayerIDs.append(playerID)
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll { $0 == playerID }
        }

        if localGame.awards[awardIndex].firstPlacePlayerIDs.count > 1 {
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll()
        }
    }

    private func toggleAwardSecondPlace(awardIndex: Int, playerID: UUID) {
        guard players.count >= 3 else { return }
        guard localGame.awards[awardIndex].firstPlacePlayerIDs.count == 1 else { return }
        guard !localGame.awards[awardIndex].firstPlacePlayerIDs.contains(playerID) else { return }

        if localGame.awards[awardIndex].secondPlacePlayerIDs.contains(playerID) {
            localGame.awards[awardIndex].secondPlacePlayerIDs.removeAll { $0 == playerID }
        } else {
            localGame.awards[awardIndex].secondPlacePlayerIDs.append(playerID)
        }
    }
}
