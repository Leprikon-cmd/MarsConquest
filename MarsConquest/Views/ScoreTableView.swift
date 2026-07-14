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
}
