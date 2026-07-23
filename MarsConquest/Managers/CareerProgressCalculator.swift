//
//  CareerProgressCalculator.swift
//  MarsConquest
//
//  Расчёт скрытого Career XP по сохранённой истории владельца.
//  Калькулятор только читает Core Data и не изменяет исторические записи.
//

import Foundation

struct CareerProgressCalculator {
    struct LevelRequirement {
        let number: Int
        let minimumGames: Int
        let minimumXP: Int
    }

    /// Тестовая шкала из PROJECT_CONTEXT. Дополнительные квалификации будут
    /// дополнять эту проверку, но не ослабят уже достигнутый уровень.
    static let levelRequirements: [LevelRequirement] = [
        .init(number: 1, minimumGames: 1, minimumXP: 10),
        .init(number: 2, minimumGames: 2, minimumXP: 50),
        .init(number: 3, minimumGames: 4, minimumXP: 100),
        .init(number: 4, minimumGames: 6, minimumXP: 150),
        .init(number: 5, minimumGames: 9, minimumXP: 220),
        .init(number: 6, minimumGames: 12, minimumXP: 300),
        .init(number: 7, minimumGames: 16, minimumXP: 400),
        .init(number: 8, minimumGames: 20, minimumXP: 500),
        .init(number: 9, minimumGames: 25, minimumXP: 620),
        .init(number: 10, minimumGames: 32, minimumXP: 750),
        .init(number: 11, minimumGames: 40, minimumXP: 900),
        .init(number: 12, minimumGames: 50, minimumXP: 1050),
        .init(number: 13, minimumGames: 65, minimumXP: 1250),
        .init(number: 14, minimumGames: 80, minimumXP: 1450),
        .init(number: 15, minimumGames: 100, minimumXP: 1700),
        .init(number: 16, minimumGames: 125, minimumXP: 2000),
        .init(number: 17, minimumGames: 150, minimumXP: 2400),
        .init(number: 18, minimumGames: 200, minimumXP: 3200),
        .init(number: 19, minimumGames: 250, minimumXP: 4200)
    ]

    struct ExperienceRules {
        let earlyGame: Int
        let midGame: Int
        let lateGame: Int
        let veteranGame: Int
        let firstPlace: Int
        let secondPlace: Int
        let thirdPlace: Int
        let achievement: Int
        let awardFirstPlace: Int
        let awardSecondPlace: Int
        let newField: Int
        let newCorporation: Int
        let newCorporationPreludePair: Int
        let milestones: [Int: Int]

        static let initial = ExperienceRules(
            earlyGame: 10,
            midGame: 5,
            lateGame: 2,
            veteranGame: 1,
            firstPlace: 5,
            secondPlace: 2,
            thirdPlace: 1,
            achievement: 5,
            awardFirstPlace: 5,
            awardSecondPlace: 2,
            newField: 50,
            newCorporation: 10,
            newCorporationPreludePair: 5,
            milestones: [
                5: 10, 10: 15, 15: 20, 20: 25, 25: 30,
                50: 50, 100: 100, 150: 125, 200: 150, 250: 200
            ]
        )
    }

    struct GameContribution: Identifiable {
        let gameID: UUID?
        let date: Date?
        let place: Int
        let playersCount: Int
        let participationXP: Int
        let placementXP: Int
        let achievementXP: Int
        let awardXP: Int
        let newFieldXP: Int
        let newCorporationXP: Int
        let newCorporationPreludePairXP: Int
        let milestoneXP: Int

        var id: String {
            gameID?.uuidString ?? "legacy-\(date?.timeIntervalSinceReferenceDate ?? 0)-\(playersCount)"
        }

        var totalXP: Int {
            participationXP + placementXP + achievementXP + awardXP + newFieldXP
            + newCorporationXP + newCorporationPreludePairXP + milestoneXP
        }
    }

    struct Progress {
        let totalXP: Int
        let gamesPlayed: Int
        let wins: Int
        let secondPlaces: Int
        let contributions: [GameContribution]

        static let empty = Progress(
            totalXP: 0,
            gamesPlayed: 0,
            wins: 0,
            secondPlaces: 0,
            contributions: []
        )
    }

    enum RegaliaKind: String {
        case firstExpedition
        case firstVictory
        case newField
        case newCorporation
        case newPrelude
        case newCorporationPreludePair
        case newColony
        case firstExpeditionWithExpansion
        case firstVictoryWithExpansion
        case firstVictoryWithField
        case firstVictoryWithCorporation
        case firstVictoryWithPrelude
        case milestone
    }

    struct Regalia: Identifiable {
        let kind: RegaliaKind
        let date: Date?
        let detail: String?
        let ordinal: Int

        var id: String { "\(kind.rawValue)-\(detail ?? "")-\(ordinal)" }
    }

    enum ProfessionalTitleKind: String {
        case corporationSpecialist
    }

    struct ProfessionalTitle: Identifiable {
        let kind: ProfessionalTitleKind
        let date: Date?
        let detail: String

        var id: String { kind.rawValue }
    }

    let rules: ExperienceRules

    init(rules: ExperienceRules = .initial) {
        self.rules = rules
    }

    /// Считает только партии, где участие владельца подтверждено стабильным UUID.
    /// Ранние записи с UUID участника, равным UUID профиля, также учитываются.
    /// Записи без такой связи не угадываются по имени.
    func calculate(ownerID: UUID, from games: [Game]) -> Progress {
        let history = linkedOwnerGames(ownerID: ownerID, from: games)
        guard !history.isEmpty else { return .empty }

        var exploredFields = Set<String>()
        var exploredCorporations = Set<String>()
        var exploredCorporationPreludePairs = Set<String>()
        var contributions: [GameContribution] = []

        for (index, entry) in history.enumerated() {
            let ordinal = index + 1
            let game = entry.game
            let owner = entry.owner
            let playersCount = entry.players.count
            let place = StatisticsCalculator.place(of: owner, in: game)

            let fieldKey = stableKey(id: game.gameFieldID, name: game.gameField)
            let corporationKey = stableKey(id: owner.corporationID, name: owner.corporation)
            let preludeKeys = [
                stableKey(id: owner.prologue1ID, name: owner.prologue1),
                stableKey(id: owner.prologue2ID, name: owner.prologue2)
            ].compactMap { $0 }

            let fieldXP = firstUseXP(for: fieldKey, in: &exploredFields, value: rules.newField)
            let corporationXP = firstUseXP(
                for: corporationKey,
                in: &exploredCorporations,
                value: rules.newCorporation
            )
            let preludePairXP = preludePairsXP(
                corporationKey: corporationKey,
                preludeKeys: preludeKeys,
                exploredPairs: &exploredCorporationPreludePairs
            )

            contributions.append(
                GameContribution(
                    gameID: game.id,
                    date: game.date,
                    place: place,
                    playersCount: playersCount,
                    participationXP: participationXP(forOrdinal: ordinal),
                    placementXP: placementXP(place: place, playersCount: playersCount),
                    achievementXP: achievementXP(for: owner),
                    awardXP: awardXP(for: owner, in: game, playersCount: playersCount),
                    newFieldXP: fieldXP,
                    newCorporationXP: corporationXP,
                    newCorporationPreludePairXP: preludePairXP,
                    milestoneXP: rules.milestones[ordinal] ?? 0
                )
            )
        }

        return Progress(
            totalXP: contributions.reduce(0) { $0 + $1.totalXP },
            gamesPlayed: contributions.count,
            wins: contributions.filter { $0.place == 1 }.count,
            secondPlaces: contributions.filter { $0.place == 2 }.count,
            contributions: contributions
        )
    }

    /// Номер ступени, подтверждённый числом партий и скрытым XP.
    func level(for progress: Progress) -> Int {
        Self.levelRequirements.last(where: {
            progress.gamesPlayed >= $0.minimumGames && progress.totalXP >= $0.minimumXP
        })?.number ?? 0
    }

    /// Первая подтверждённая регалия — завершённая экспедиция.
    /// В будущем сюда добавятся титулы, рекорды и карьерные события.
    func hasVisibleRegalia(for progress: Progress) -> Bool {
        progress.gamesPlayed > 0
    }

    /// Личные регалии, которые можно честно восстановить из сохранённой истории.
    func regalia(ownerID: UUID, from games: [Game]) -> [Regalia] {
        let history = linkedOwnerGames(ownerID: ownerID, from: games)
        var fields = Set<String>()
        var corporations = Set<String>()
        var preludes = Set<String>()
        var pairs = Set<String>()
        var colonies = Set<String>()
        var expansions = Set<String>()
        var winningFields = Set<String>()
        var winningCorporations = Set<String>()
        var winningPreludes = Set<String>()
        var winningExpansions = Set<String>()
        var result: [Regalia] = []

        for (index, entry) in history.enumerated() {
            let ordinal = index + 1
            let field = stableKey(id: entry.game.gameFieldID, name: entry.game.gameField)
            let corporation = stableKey(id: entry.owner.corporationID, name: entry.owner.corporation)
            let preludePairs = [
                stableKey(id: entry.owner.prologue1ID, name: entry.owner.prologue1),
                stableKey(id: entry.owner.prologue2ID, name: entry.owner.prologue2)
            ].compactMap { $0 }
            let gameColonies = (entry.game.colonies?.allObjects as? [Colony] ?? [])
                .sorted { ($0.referenceID ?? $0.name ?? "") < ($1.referenceID ?? $1.name ?? "") }

            if ordinal == 1 {
                result.append(.init(kind: .firstExpedition, date: entry.game.date, detail: nil, ordinal: ordinal))
            }
            if entry.players.count > 1, StatisticsCalculator.place(of: entry.owner, in: entry.game) == 1,
               !result.contains(where: { $0.kind == .firstVictory }) {
                result.append(.init(kind: .firstVictory, date: entry.game.date, detail: nil, ordinal: ordinal))
            }
            if let field, fields.insert(field).inserted {
                result.append(.init(kind: .newField, date: entry.game.date, detail: entry.game.gameField, ordinal: ordinal))
            }
            if let corporation, corporations.insert(corporation).inserted {
                result.append(.init(kind: .newCorporation, date: entry.game.date, detail: entry.owner.corporation, ordinal: ordinal))
            }
            for prelude in preludePairs {
                if preludes.insert(prelude).inserted {
                    result.append(.init(kind: .newPrelude, date: entry.game.date, detail: preludeDisplayName(prelude, owner: entry.owner), ordinal: ordinal))
                }
            }
            if let corporation {
                for prelude in preludePairs {
                    let key = "\(corporation)|\(prelude)"
                    if pairs.insert(key).inserted {
                        result.append(.init(kind: .newCorporationPreludePair, date: entry.game.date, detail: key, ordinal: ordinal))
                    }
                }
            }
            for colony in gameColonies {
                if let key = stableKey(id: colony.referenceID, name: colony.name),
                   colonies.insert(key).inserted {
                    result.append(.init(kind: .newColony, date: entry.game.date, detail: colony.name, ordinal: ordinal))
                }
            }
            for expansion in enabledExpansionKeys(in: entry.game) {
                if expansions.insert(expansion).inserted {
                    result.append(.init(kind: .firstExpeditionWithExpansion, date: entry.game.date, detail: expansion, ordinal: ordinal))
                }
            }
            if entry.players.count > 1, StatisticsCalculator.place(of: entry.owner, in: entry.game) == 1 {
                if let field, winningFields.insert(field).inserted {
                    result.append(.init(kind: .firstVictoryWithField, date: entry.game.date, detail: entry.game.gameField, ordinal: ordinal))
                }
                if let corporation, winningCorporations.insert(corporation).inserted {
                    result.append(.init(kind: .firstVictoryWithCorporation, date: entry.game.date, detail: entry.owner.corporation, ordinal: ordinal))
                }
                for prelude in preludePairs {
                    if winningPreludes.insert(prelude).inserted {
                        result.append(.init(kind: .firstVictoryWithPrelude, date: entry.game.date, detail: preludeDisplayName(prelude, owner: entry.owner), ordinal: ordinal))
                    }
                }
                for expansion in enabledExpansionKeys(in: entry.game) {
                    if winningExpansions.insert(expansion).inserted {
                        result.append(.init(kind: .firstVictoryWithExpansion, date: entry.game.date, detail: expansion, ordinal: ordinal))
                    }
                }
            }
            if rules.milestones[ordinal] != nil {
                result.append(.init(kind: .milestone, date: entry.game.date, detail: "\(ordinal)", ordinal: ordinal))
            }
        }
        return result
    }

    /// Первый профессиональный титул: 5 подтверждённых экспедиций одной корпорацией.
    /// Титул восстанавливается из истории и не хранится отдельной копией в Core Data.
    func professionalTitles(ownerID: UUID, from games: [Game]) -> [ProfessionalTitle] {
        var corporationCounts: [String: Int] = [:]
        var corporationNames: [String: String] = [:]

        for entry in linkedOwnerGames(ownerID: ownerID, from: games) {
            guard let key = stableKey(id: entry.owner.corporationID, name: entry.owner.corporation) else {
                continue
            }
            let count = (corporationCounts[key] ?? 0) + 1
            corporationCounts[key] = count
            if let name = entry.owner.corporation, !name.isEmpty {
                corporationNames[key] = name
            }
            if count == 5 {
                return [
                    .init(
                        kind: .corporationSpecialist,
                        date: entry.game.date,
                        detail: corporationNames[key] ?? key
                    )
                ]
            }
        }
        return []
    }

    private func preludeDisplayName(_ key: String, owner: Player) -> String? {
        if stableKey(id: owner.prologue1ID, name: owner.prologue1) == key {
            return owner.prologue1
        }
        if stableKey(id: owner.prologue2ID, name: owner.prologue2) == key {
            return owner.prologue2
        }
        return nil
    }

    private func enabledExpansionKeys(in game: Game) -> [String] {
        var result: [String] = []
        if game.hasPrelude { result.append("prelude") }
        if game.hasVenus { result.append("venus") }
        if game.hasColonies { result.append("colonies") }
        if game.hasHellasElysium { result.append("hellasElysium") }
        if game.hasTurmoil { result.append("turmoil") }
        return result
    }

    private func linkedOwnerGames(ownerID: UUID, from games: [Game]) -> [OwnerGame] {
        var seenIDs = Set<UUID>()

        return games.compactMap { game -> OwnerGame? in
            if let id = game.id, !seenIDs.insert(id).inserted {
                return nil
            }
            guard let players = game.players?.allObjects as? [Player],
                  let owner = players.first(where: {
                      $0.savedPlayerID == ownerID || $0.id == ownerID
                  })
            else {
                return nil
            }
            return OwnerGame(game: game, owner: owner, players: players)
        }
        .sorted { left, right in
            let leftDate = left.game.date ?? .distantPast
            let rightDate = right.game.date ?? .distantPast
            if leftDate != rightDate { return leftDate < rightDate }
            return (left.game.id?.uuidString ?? "") < (right.game.id?.uuidString ?? "")
        }
    }

    private func participationXP(forOrdinal ordinal: Int) -> Int {
        switch ordinal {
        case 1...50: rules.earlyGame
        case 51...75: rules.midGame
        case 76...100: rules.lateGame
        default: rules.veteranGame
        }
    }

    private func placementXP(place: Int, playersCount: Int) -> Int {
        // Модель пока не хранит признак успешности соло-партии. Место единственного
        // участника всегда равно первому, но это не доказательство победы, поэтому
        // бонус не придумывается до появления явного поля результата.
        guard playersCount > 1 else { return 0 }

        return switch place {
        case 1: rules.firstPlace
        case 2: rules.secondPlace
        case 3 where playersCount >= 3: rules.thirdPlace
        default: 0
        }
    }

    private func achievementXP(for player: Player) -> Int {
        let achievements = player.achievements?.allObjects as? [Achievement] ?? []
        return achievements.count * rules.achievement
    }

    private func awardXP(for player: Player, in game: Game, playersCount: Int) -> Int {
        let awards = game.awards?.allObjects as? [Award] ?? []
        let groups = Dictionary(grouping: awards) { award in
            stableKey(id: award.referenceID, name: award.name) ?? "award-\(award.objectID.uriRepresentation())"
        }

        return groups.values.reduce(0) { points, group in
            let firstPlaces = group.filter { $0.place == 1 }
            let secondPlaces = group.filter { $0.place == 2 }

            if firstPlaces.contains(where: { $0.player == player }) {
                return points + rules.awardFirstPlace
            }
            if playersCount >= 3,
               firstPlaces.count == 1,
               secondPlaces.contains(where: { $0.player == player }) {
                return points + rules.awardSecondPlace
            }
            return points
        }
    }

    private func preludePairsXP(
        corporationKey: String?,
        preludeKeys: [String],
        exploredPairs: inout Set<String>
    ) -> Int {
        guard let corporationKey else { return 0 }

        return preludeKeys.reduce(0) { points, preludeKey in
            let pairKey = "\(corporationKey)|\(preludeKey)"
            return exploredPairs.insert(pairKey).inserted
                ? points + rules.newCorporationPreludePair
                : points
        }
    }

    private func firstUseXP(for key: String?, in explored: inout Set<String>, value: Int) -> Int {
        guard let key, explored.insert(key).inserted else { return 0 }
        return value
    }

    private func stableKey(id: String?, name: String?) -> String? {
        if let id, !id.isEmpty { return id }
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        return "legacy:\(name.lowercased())"
    }

    private struct OwnerGame {
        let game: Game
        let owner: Player
        let players: [Player]
    }
}
