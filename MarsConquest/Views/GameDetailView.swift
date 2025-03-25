//
//  GameDetailView.swift
//
//  Зачем:
//  Показывает сохранённую партию и её участников после записи в базу данных.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - отображение информации о сохранённой игре
//  - отображение списка игроков
//  - показ данных игрока: корпорация, прологи, итоговые очки
//  - расчёт итоговой суммы очков по сохранённому Score, наградам и достижениям
//

import SwiftUI
import CoreData

struct GameDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var game: Game

    var body: some View {
        List {
            Section(header: Text("Информация об игре")) {
                Text("Поле: \(game.gameField ?? "Неизвестно")")
                Text("Дата: \(formattedDate(game.date))")
                Text("Поколение: \(game.generation)")
            }
            Section(header: Text("Игроки")) {
                if let players = game.players?.allObjects as? [Player] {
                    let sortedPlayers = players.sorted {
                        totalScore(for: $0) > totalScore(for: $1)
                    }
                    
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if index == 0 {
                                    Text("🏆")
                                }
                                
                                Text("\(index + 1) место — \(player.name ?? "Без имени")")
                                    .font(.headline)
                            }
                            
                            Text("Корпорация: \(player.corporation ?? "—")")
                            Text("Прологи: \(player.prologue1 ?? "—"), \(player.prologue2 ?? "—")")
                            
                            let base = baseScore(for: player)
                            let achievements = achievementPoints(for: player)
                            let awards = awardPoints(for: player)
                            let total = totalScore(for: player)
                            
                            Text("База: \(base)")
                            Text("Достижения: \(achievements)")
                            Text("Награды: \(awards)")
                            Text("Итог: \(total)")
                                .bold()

                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Игра №\(game.gameNumber)")
    }
    
    private func totalScore(for player: Player) -> Int32 {
        baseScore(for: player) +
        achievementPoints(for: player) +
        awardPoints(for: player)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Неизвестно" }
        let formatter = DateFormatters.shortDate
        return formatter.string(from: date)
    }

    /// Базовые очки из сущности Score.
    private func baseScore(for player: Player) -> Int32 {
        guard let score = player.score else { return 0 }
        
        return score.terraformingRating +
               score.greenery +
               score.cities +
               score.victoryPoints +
               score.resourcesOnCards +
               score.conditionsOnCards +
               score.politics
    }

    /// Очки игрока за достижения в рамках текущей игры.
    private func achievementPoints(for player: Player) -> Int32 {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@ AND player == %@", game, player)
        
        let count = (try? viewContext.count(for: request)) ?? 0
        return Int32(count * 5)
    }

    /// Очки игрока за награды в рамках текущей игры.
    private func awardPoints(for player: Player) -> Int32 {
        let request: NSFetchRequest<Award> = Award.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        
        guard let awards = try? viewContext.fetch(request) else { return 0 }
        
        let playersCount = (game.players?.allObjects as? [Player])?.count ?? 0
        var points: Int32 = 0
        
        // Группируем награды по названию
        let grouped = Dictionary(grouping: awards, by: { $0.name ?? "" })
        
        for (_, awardGroup) in grouped {
            let firstPlaceAwards = awardGroup.filter { $0.place == 1 }
            let secondPlaceAwards = awardGroup.filter { $0.place == 2 }
            let hasTieForFirst = firstPlaceAwards.count > 1
            
            if firstPlaceAwards.contains(where: { $0.player == player }) {
                points += Int32(GameConstants.awardFirstPlacePoints)
            }
            
            if playersCount >= 3 && !hasTieForFirst && secondPlaceAwards.contains(where: { $0.player == player }) {
                points += Int32(GameConstants.awardSecondPlacePoints)
            }
        }
        
        return points
    }
}
