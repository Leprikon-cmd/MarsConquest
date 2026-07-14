//
//  GameDetailView.swift
//
//  Показывает сохранённую партию: краткую сводку по игрокам и,
//  по явному действию, подробную разбивку их очков.
//

import SwiftUI
import CoreData

struct GameDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let game: Game
    let gameNumber: Int?

    init(game: Game, gameNumber: Int? = nil) {
        self.game = game
        self.gameNumber = gameNumber
    }

    var body: some View {
        List {
            gameInformationSection()

            ForEach(sortedPlayers, id: \.objectID) { player in
                playerSection(for: player)
            }
        }
        .navigationTitle(gameNumber.map { "Игра №\($0)" } ?? "Игра")
    }

    private func gameInformationSection() -> some View {
        Section("Информация об игре") {
            Text("Поле: \(game.gameField ?? UIStrings.unknown)")
            Text("Дата: \(formattedDate(game.date))")
            Text("Поколение: \(game.generation)")

            let expansions = expansionsList()
            if !expansions.isEmpty {
                Text("Дополнения: \(expansions.joined(separator: ", "))")
            }
        }
    }

    private func playerSection(for player: Player) -> some View {
        Section(placeTitle(for: player)) {
            playerSummary(for: player)

            DisclosureGroup("Подробнее") {
                scoreBreakdown(for: player)
            }
        }
    }

    /// Краткая часть всегда остаётся на экране: кто играл и с каким итогом.
    private func playerSummary(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Корпорация: \(player.corporation ?? "—")")

            if game.hasPrelude {
                Text("Прологи: \(player.prologue1 ?? "—"), \(player.prologue2 ?? "—")")
            }

            HStack {
                Text("Итог")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalScore(for: player))")
                    .font(.title3.weight(.bold))
            }
        }
        .padding(.vertical, 3)
    }

    /// Детальная часть использует те же данные Score, Achievement и Award,
    /// которые были сохранены после партии.
    private func scoreBreakdown(for player: Player) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Основные очки")
                .font(.subheadline.weight(.semibold))

            scoreRows(for: player)

            let achievements = achievementNames(for: player)
            if !achievements.isEmpty {
                Divider()
                Text("Достижения")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(achievements.enumerated()), id: \.offset) { _, name in
                    detailRow(name, points: Int32(GameConstants.achievementPoints))
                }
            }

            let awards = awardSummaries(for: player)
            if !awards.isEmpty {
                Divider()
                Text("Награды")
                    .font(.subheadline.weight(.semibold))

                ForEach(awards) { award in
                    HStack {
                        Text(award.name)
                        Spacer()
                        Text(award.medal)
                        if award.points > 0 {
                            Text("+\(award.points)")
                                .monospacedDigit()
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Divider()
            HStack {
                Text("Всего")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalScore(for: player))")
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func scoreRows(for player: Player) -> some View {
        let score = player.score

        detailRow("Рейтинг терраформирования", points: score?.terraformingRating ?? 0)
        detailRow("Озеленение", points: score?.greenery ?? 0)
        detailRow("Города", points: score?.cities ?? 0)
        detailRow("Победные очки", points: score?.victoryPoints ?? 0)
        detailRow("Ресурсы на картах", points: score?.resourcesOnCards ?? 0)
        detailRow("Условия на картах", points: score?.conditionsOnCards ?? 0)

        if game.hasTurmoil {
            detailRow("Политика", points: score?.politics ?? 0)
        }
    }

    private func detailRow(_ title: String, points: Int32) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(points)")
                .monospacedDigit()
        }
        .foregroundStyle(.secondary)
    }

    private var sortedPlayers: [Player] {
        guard let players = game.players?.allObjects as? [Player] else { return [] }

        return players.sorted {
            let leftScore = totalScore(for: $0)
            let rightScore = totalScore(for: $1)

            if leftScore != rightScore {
                return leftScore > rightScore
            }

            return ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
        }
    }

    /// Места плотные: 1, 1, 2, 3, а не 1, 1, 3, 4.
    private func place(for player: Player) -> Int {
        let distinctScores = Array(Set(sortedPlayers.map { totalScore(for: $0) })).sorted(by: >)
        return (distinctScores.firstIndex(of: totalScore(for: player)) ?? 0) + 1
    }

    private func placeTitle(for player: Player) -> String {
        let place = place(for: player)
        let medal: String

        switch place {
        case 1: medal = "🥇 "
        case 2: medal = "🥈 "
        case 3: medal = "🥉 "
        default: medal = ""
        }

        return "\(medal)\(place) место — \(player.name ?? "Без имени")"
    }

    private func expansionsList() -> [String] {
        var expansions: [String] = []

        if game.hasPrelude { expansions.append("Прологи") }
        if game.hasVenus { expansions.append("Венера") }
        if game.hasColonies { expansions.append("Колонии") }
        if game.hasHellasElysium { expansions.append("Эллада / Элизий") }
        if game.hasTurmoil { expansions.append("Кризис") }

        return expansions
    }

    private var gameAchievements: [Achievement] {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    private var gameAwards: [Award] {
        let request: NSFetchRequest<Award> = Award.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true),
            NSSortDescriptor(key: "place", ascending: true)
        ]
        return (try? viewContext.fetch(request)) ?? []
    }

    private func achievementNames(for player: Player) -> [String] {
        gameAchievements
            .filter { $0.player == player }
            .compactMap(\.name)
    }

    private func achievementPoints(for player: Player) -> Int32 {
        Int32(achievementNames(for: player).count * GameConstants.achievementPoints)
    }

    private func awardSummaries(for player: Player) -> [AwardSummary] {
        gameAwards
            .filter { $0.player == player }
            .map { award in
                AwardSummary(
                    id: award.objectID,
                    name: award.name ?? "Без названия",
                    medal: award.place == 1 ? "🥇" : "🥈",
                    points: award.place == 1
                        ? Int32(GameConstants.awardFirstPlacePoints)
                        : secondPlacePoints(for: award)
                )
            }
    }

    private func awardPoints(for player: Player) -> Int32 {
        awardSummaries(for: player).reduce(0) { $0 + $1.points }
    }

    private func secondPlacePoints(for award: Award) -> Int32 {
        // Нельзя брать количество игроков через sortedPlayers: сортировка
        // сама рассчитывает очки, а очки второй награды попадают сюда снова.
        // Берём число игроков напрямую из сохранённой партии.
        let playersCount = (game.players?.allObjects as? [Player])?.count ?? 0
        let firstPlaces = gameAwards.filter {
            $0.name == award.name && $0.place == 1
        }

        guard playersCount >= 3, firstPlaces.count == 1 else { return 0 }
        return Int32(GameConstants.awardSecondPlacePoints)
    }

    private func baseScore(for player: Player) -> Int32 {
        guard let score = player.score else { return 0 }

        var total =
            score.terraformingRating +
            score.greenery +
            score.cities +
            score.victoryPoints +
            score.resourcesOnCards +
            score.conditionsOnCards

        if game.hasTurmoil {
            total += score.politics
        }

        return total
    }

    private func totalScore(for player: Player) -> Int32 {
        baseScore(for: player) +
        achievementPoints(for: player) +
        awardPoints(for: player)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return UIStrings.unknown }
        return DateFormatters.shortDate.string(from: date)
    }
}

private struct AwardSummary: Identifiable {
    let id: NSManagedObjectID
    let name: String
    let medal: String
    let points: Int32
}
