//
//  JournalBackupManager.swift
//
//  Зачем:
//  Формирует резервный архив и безопасно вносит его в журнал без перезаписи известных записей.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - собирает профиль, игроков и завершённые экспедиции в JSON-модель;
//  - проверяет архив целиком до внесения данных;
//  - восстанавливает только отсутствующие UUID в отдельном контексте Core Data.
//
//  Что можно менять руками:
//  - правила формата и проверки — только одновременно с JournalBackupModels.swift;
//  - текст ошибок архива расположен в JournalBackupError в конце файла.
//

import CoreData
import Foundation

struct JournalBackupManager {
    static func makeBackup(in context: NSManagedObjectContext) throws -> JournalBackup {
        try context.performAndWait {
            let profile = OwnerProfileManager.fetch(in: context)
            let savedPlayers = try fetchSavedPlayers(in: context).map(backupSavedPlayer)
            let games = try fetchGames(in: context).map(backupGame)
            let avatarStyle = UserDefaults.standard.string(forKey: OwnerAvatarStyle.storageKey)
                ?? OwnerAvatarStyle.commander.rawValue

            return JournalBackup(
                formatVersion: JournalBackup.currentFormatVersion,
                createdAt: Date(),
                profile: try profile.map(backupOwnerProfile),
                savedPlayers: savedPlayers,
                games: games,
                avatar: JournalBackupAvatar(
                    style: OwnerAvatarStyle(rawValue: avatarStyle)?.rawValue
                        ?? OwnerAvatarStyle.commander.rawValue,
                    selfieJPEGData: OwnerSelfieStore.backupData()
                )
            )
        }
    }

    static func encodedData(for backup: JournalBackup) throws -> Data {
        try validate(backup)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> JournalBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let backup = try decoder.decode(JournalBackup.self, from: data)
            try validate(backup)
            return backup
        } catch let error as JournalBackupError {
            throw error
        } catch {
            throw JournalBackupError.invalidArchive
        }
    }

    /// Восстанавливает только отсутствующие сущности с постоянным UUID. Уже существующие данные
    /// остаются источником истины текущего журнала и никогда не перезаписываются.
    static func restore(
        _ backup: JournalBackup,
        in context: NSManagedObjectContext
    ) throws -> JournalRestoreReport {
        try validate(backup)

        guard let coordinator = context.persistentStoreCoordinator else {
            throw JournalBackupError.missingPersistentStoreCoordinator
        }

        let savingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        savingContext.persistentStoreCoordinator = coordinator
        savingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let saveObserver = ContextSaveObserver()
        let token = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: savingContext,
            queue: nil
        ) { notification in
            saveObserver.notification = notification
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let report = try savingContext.performAndWait {
            do {
                var restoredPlayers = 0
                for savedPlayer in backup.savedPlayers {
                    guard try existingSavedPlayer(id: savedPlayer.id, in: savingContext) == nil else {
                        continue
                    }

                    let player = SavedPlayer(context: savingContext)
                    player.id = savedPlayer.id
                    player.name = savedPlayer.name
                    player.nickname = savedPlayer.nickname
                    player.realName = savedPlayer.realName
                    player.favoriteColor = savedPlayer.favoriteColor
                    player.isFavorite = savedPlayer.isFavorite
                    player.createdAt = savedPlayer.createdAt
                    player.updatedAt = savedPlayer.updatedAt
                    restoredPlayers += 1
                }

                var profileRestored = false
                if try existingOwnerProfile(in: savingContext) == nil, let profile = backup.profile {
                    let restoredProfile = OwnerProfile(context: savingContext)
                    restoredProfile.id = profile.id
                    restoredProfile.savedPlayerID = profile.savedPlayerID
                    restoredProfile.createdAt = profile.createdAt
                    restoredProfile.updatedAt = profile.updatedAt
                    restoredProfile.hasBaseGame = profile.hasBaseGame
                    restoredProfile.hasPrelude = profile.hasPrelude
                    restoredProfile.hasVenus = profile.hasVenus
                    restoredProfile.hasColonies = profile.hasColonies
                    restoredProfile.hasHellasElysium = profile.hasHellasElysium
                    restoredProfile.hasTurmoil = profile.hasTurmoil
                    profileRestored = true
                }

                var gamesRestored = 0
                var gamesAlreadyPresent = 0
                var restoredGameIDs: [UUID] = []
                for game in backup.games {
                    if try existingGame(id: game.id, in: savingContext) != nil {
                        gamesAlreadyPresent += 1
                        continue
                    }

                    try restore(game: game, in: savingContext)
                    gamesRestored += 1
                    restoredGameIDs.append(game.id)
                }

                let report = JournalRestoreReport(
                    gamesRestored: gamesRestored,
                    gamesAlreadyPresent: gamesAlreadyPresent,
                    savedPlayersRestored: restoredPlayers,
                    profileRestored: profileRestored,
                    restoredGameIDs: restoredGameIDs
                )

                if savingContext.hasChanges {
                    try savingContext.save()
                }
                return report
            } catch {
                savingContext.rollback()
                throw error
            }
        }

        if let notification = saveObserver.notification {
            context.performAndWait {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }

        return report
    }

    /// Явно относит участие из другой истории к владельцу этого журнала.
    /// Выбор производится по исходному UUID профиля, а не по совпадению имени.
    static func linkImportedParticipation(
        sourceSavedPlayerID: UUID,
        to ownerSavedPlayerID: UUID,
        in context: NSManagedObjectContext
    ) throws -> Int {
        guard let coordinator = context.persistentStoreCoordinator else {
            throw JournalBackupError.missingPersistentStoreCoordinator
        }

        let savingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        savingContext.persistentStoreCoordinator = coordinator

        let saveObserver = ContextSaveObserver()
        let token = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: savingContext,
            queue: nil
        ) { notification in
            saveObserver.notification = notification
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let linkedCount = try savingContext.performAndWait {
            do {
                let request = NSFetchRequest<Player>(entityName: "Player")
                request.predicate = NSPredicate(
                    format: "savedPlayerID == %@",
                    sourceSavedPlayerID as CVarArg
                )
                let participations = try savingContext.fetch(request)
                participations.forEach { $0.savedPlayerID = ownerSavedPlayerID }
                try savingContext.save()
                return participations.count
            } catch {
                savingContext.rollback()
                throw error
            }
        }

        if let notification = saveObserver.notification {
            context.performAndWait {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }

        return linkedCount
    }

    private static func backupOwnerProfile(_ profile: OwnerProfile) throws -> JournalBackupOwnerProfile {
        guard let id = profile.id, let savedPlayerID = profile.savedPlayerID else {
            throw JournalBackupError.incompleteLocalProfile
        }

        return JournalBackupOwnerProfile(
            id: id,
            savedPlayerID: savedPlayerID,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            hasBaseGame: profile.hasBaseGame,
            hasPrelude: profile.hasPrelude,
            hasVenus: profile.hasVenus,
            hasColonies: profile.hasColonies,
            hasHellasElysium: profile.hasHellasElysium,
            hasTurmoil: profile.hasTurmoil
        )
    }

    private static func backupSavedPlayer(_ player: SavedPlayer) throws -> JournalBackupSavedPlayer {
        guard let id = player.id else { throw JournalBackupError.incompleteLocalProfile }

        return JournalBackupSavedPlayer(
            id: id,
            name: player.name,
            nickname: player.nickname,
            realName: player.realName,
            favoriteColor: player.favoriteColor,
            isFavorite: player.isFavorite,
            createdAt: player.createdAt,
            updatedAt: player.updatedAt
        )
    }

    private static func backupGame(_ game: Game) throws -> JournalBackupGame {
        guard let id = game.id else { throw JournalBackupError.incompleteLocalGame }

        let players = try (game.players?.allObjects as? [Player] ?? [])
            .map(backupPlayer)
            .sorted { $0.id.uuidString < $1.id.uuidString }
        let colonies = (game.colonies?.allObjects as? [Colony] ?? [])
            .map { JournalBackupColony(name: $0.name, referenceID: $0.referenceID) }
            .sorted { ($0.referenceID ?? $0.name ?? "") < ($1.referenceID ?? $1.name ?? "") }
        let achievements = try (game.achievments?.allObjects as? [Achievement] ?? [])
            .map(backupAchievement)
            .sorted { ($0.referenceID ?? $0.name ?? "") < ($1.referenceID ?? $1.name ?? "") }
        let awards = try (game.awards?.allObjects as? [Award] ?? [])
            .map(backupAward)
            .sorted {
                ($0.referenceID ?? $0.name ?? "", $0.place, $0.playerID.uuidString)
                    < ($1.referenceID ?? $1.name ?? "", $1.place, $1.playerID.uuidString)
            }

        return JournalBackupGame(
            id: id,
            date: game.date,
            gameField: game.gameField,
            gameFieldID: game.gameFieldID,
            gameNumber: game.gameNumber,
            generation: game.generation,
            venusTerraformingScale: game.venusTerraformingScale,
            hasPrelude: game.hasPrelude,
            hasVenus: game.hasVenus,
            hasColonies: game.hasColonies,
            hasHellasElysium: game.hasHellasElysium,
            hasTurmoil: game.hasTurmoil,
            hasTieBreakerData: game.hasTieBreakerData,
            usesHostMode: game.usesHostMode,
            sports: backupSports(game),
            players: players,
            colonies: colonies,
            achievements: achievements,
            awards: awards
        )
    }

    private static func backupPlayer(_ player: Player) throws -> JournalBackupPlayer {
        guard let id = player.id else { throw JournalBackupError.incompleteLocalGame }

        return JournalBackupPlayer(
            id: id,
            savedPlayerID: player.savedPlayerID,
            name: player.name,
            color: player.color,
            corporation: player.corporation,
            corporationID: player.corporationID,
            prologue1: player.prologue1,
            prologue1ID: player.prologue1ID,
            prologue2: player.prologue2,
            prologue2ID: player.prologue2ID,
            remainingMegaCredits: player.remainingMegaCredits,
            unplayedCards: player.unplayedCards,
            sportsTimeUsedSeconds: player.sportsTimeUsedSeconds,
            sportsTimeExceeded: player.sportsTimeExceeded,
            score: player.score.map(backupScore)
        )
    }

    private static func backupSports(_ game: Game) -> JournalBackupSports? {
        guard game.isSportsMode else { return nil }
        return JournalBackupSports(
            ruleID: game.sportsRuleID ?? SportsRegulationMetadata.ruleID,
            ruleVersion: game.sportsRuleVersion ?? SportsRegulationMetadata.ruleVersion,
            timeLimitSeconds: game.sportsTimeLimitSeconds,
            generationLimit: game.sportsGenerationLimit,
            allTimedOutRule: game.sportsAllTimedOutRule,
            outcome: game.sportsOutcome,
            winnerPlayerID: game.sportsWinnerPlayerID
        )
    }

    private static func backupScore(_ score: Score) -> JournalBackupScore {
        JournalBackupScore(
            terraformingRating: score.terraformingRating,
            greenery: score.greenery,
            cities: score.cities,
            victoryPoints: score.victoryPoints,
            resourcesOnCards: score.resourcesOnCards,
            conditionsOnCards: score.conditionsOnCards,
            politics: score.politics
        )
    }

    private static func backupAchievement(_ achievement: Achievement) throws -> JournalBackupAchievement {
        guard let playerID = achievement.player?.id else { throw JournalBackupError.incompleteLocalGame }
        return JournalBackupAchievement(
            name: achievement.name,
            referenceID: achievement.referenceID,
            playerID: playerID
        )
    }

    private static func backupAward(_ award: Award) throws -> JournalBackupAward {
        guard let playerID = award.player?.id else { throw JournalBackupError.incompleteLocalGame }
        return JournalBackupAward(
            name: award.name,
            referenceID: award.referenceID,
            place: award.place,
            playerID: playerID
        )
    }

    private static func restore(game: JournalBackupGame, in context: NSManagedObjectContext) throws {
        let restoredGame = Game(context: context)
        restoredGame.id = game.id
        restoredGame.date = game.date
        restoredGame.gameField = game.gameField
        restoredGame.gameFieldID = game.gameFieldID
        restoredGame.gameNumber = game.gameNumber
        restoredGame.generation = game.generation
        restoredGame.venusTerraformingScale = game.venusTerraformingScale
        restoredGame.hasPrelude = game.hasPrelude
        restoredGame.hasVenus = game.hasVenus
        restoredGame.hasColonies = game.hasColonies
        restoredGame.hasHellasElysium = game.hasHellasElysium
        restoredGame.hasTurmoil = game.hasTurmoil
        restoredGame.hasTieBreakerData = game.hasTieBreakerData
        restoredGame.usesHostMode = game.usesHostMode ?? false

        if let sports = game.sports {
            restoredGame.isSportsMode = true
            restoredGame.sportsRuleID = sports.ruleID
            restoredGame.sportsRuleVersion = sports.ruleVersion
            restoredGame.sportsTimeLimitSeconds = sports.timeLimitSeconds
            restoredGame.sportsGenerationLimit = sports.generationLimit
            restoredGame.sportsAllTimedOutRule = sports.allTimedOutRule
            restoredGame.sportsOutcome = sports.outcome
            restoredGame.sportsWinnerPlayerID = sports.winnerPlayerID
        }

        var playersByID: [UUID: Player] = [:]
        for player in game.players {
            let restoredPlayer = Player(context: context)
            restoredPlayer.id = player.id
            restoredPlayer.savedPlayerID = player.savedPlayerID
            restoredPlayer.name = player.name
            restoredPlayer.color = player.color
            restoredPlayer.corporation = player.corporation
            restoredPlayer.corporationID = player.corporationID
            restoredPlayer.prologue1 = player.prologue1
            restoredPlayer.prologue1ID = player.prologue1ID
            restoredPlayer.prologue2 = player.prologue2
            restoredPlayer.prologue2ID = player.prologue2ID
            restoredPlayer.remainingMegaCredits = player.remainingMegaCredits
            restoredPlayer.unplayedCards = player.unplayedCards
            restoredPlayer.sportsTimeUsedSeconds = player.sportsTimeUsedSeconds ?? 0
            restoredPlayer.sportsTimeExceeded = player.sportsTimeExceeded ?? false

            if let score = player.score {
                let restoredScore = Score(context: context)
                restoredScore.terraformingRating = score.terraformingRating
                restoredScore.greenery = score.greenery
                restoredScore.cities = score.cities
                restoredScore.victoryPoints = score.victoryPoints
                restoredScore.resourcesOnCards = score.resourcesOnCards
                restoredScore.conditionsOnCards = score.conditionsOnCards
                restoredScore.politics = score.politics
                restoredPlayer.score = restoredScore
            }

            restoredGame.addToPlayers(restoredPlayer)
            playersByID[player.id] = restoredPlayer
        }

        for colony in game.colonies {
            let restoredColony = Colony(context: context)
            restoredColony.name = colony.name
            restoredColony.referenceID = colony.referenceID
            restoredColony.game = restoredGame
        }

        for achievement in game.achievements {
            guard let player = playersByID[achievement.playerID] else {
                throw JournalBackupError.invalidArchive
            }

            let restoredAchievement = Achievement(context: context)
            restoredAchievement.name = achievement.name
            restoredAchievement.referenceID = achievement.referenceID
            restoredAchievement.game = restoredGame
            restoredAchievement.player = player
        }

        for award in game.awards {
            guard let player = playersByID[award.playerID] else {
                throw JournalBackupError.invalidArchive
            }

            let restoredAward = Award(context: context)
            restoredAward.name = award.name
            restoredAward.referenceID = award.referenceID
            restoredAward.place = award.place
            restoredAward.game = restoredGame
            restoredAward.player = player
        }
    }

    private static func validate(_ backup: JournalBackup) throws {
        guard (1...JournalBackup.currentFormatVersion).contains(backup.formatVersion) else {
            throw JournalBackupError.unsupportedArchiveVersion
        }
        guard OwnerAvatarStyle(rawValue: backup.avatar.style) != nil else {
            throw JournalBackupError.invalidArchive
        }
        guard backup.avatar.selfieJPEGData?.count ?? 0 <= 10_000_000 else {
            throw JournalBackupError.invalidArchive
        }
        if backup.avatar.style == OwnerAvatarStyle.selfie.rawValue,
           backup.avatar.selfieJPEGData == nil {
            throw JournalBackupError.invalidArchive
        }
        if let selfie = backup.avatar.selfieJPEGData,
           !OwnerSelfieStore.isValidBackupData(selfie) {
            throw JournalBackupError.invalidArchive
        }

        let savedPlayerIDs = backup.savedPlayers.map(\.id)
        guard Set(savedPlayerIDs).count == savedPlayerIDs.count else {
            throw JournalBackupError.invalidArchive
        }
        guard backup.savedPlayers.allSatisfy({
            $0.name != nil
                && $0.favoriteColor != nil
                && $0.createdAt != nil
                && $0.updatedAt != nil
        }) else {
            throw JournalBackupError.invalidArchive
        }
        if let profile = backup.profile,
           (!Set(savedPlayerIDs).contains(profile.savedPlayerID)
                || profile.createdAt == nil
                || profile.updatedAt == nil) {
            throw JournalBackupError.invalidArchive
        }

        let gameIDs = backup.games.map(\.id)
        guard Set(gameIDs).count == gameIDs.count else {
            throw JournalBackupError.invalidArchive
        }

        for game in backup.games {
            let playerIDs = game.players.map(\.id)
            let uniquePlayerIDs = Set(playerIDs)
            guard uniquePlayerIDs.count == playerIDs.count else {
                throw JournalBackupError.invalidArchive
            }
            guard game.achievements.allSatisfy({ uniquePlayerIDs.contains($0.playerID) }),
                  game.awards.allSatisfy({ uniquePlayerIDs.contains($0.playerID) }) else {
                throw JournalBackupError.invalidArchive
            }
            if let sports = game.sports,
               let winnerPlayerID = sports.winnerPlayerID,
               !uniquePlayerIDs.contains(winnerPlayerID) {
                throw JournalBackupError.invalidArchive
            }
        }
    }

    private static func fetchGames(in context: NSManagedObjectContext) throws -> [Game] {
        let request = NSFetchRequest<Game>(entityName: "Game")
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true),
            NSSortDescriptor(key: "id", ascending: true)
        ]
        return try context.fetch(request)
    }

    private static func fetchSavedPlayers(in context: NSManagedObjectContext) throws -> [SavedPlayer] {
        let request = NSFetchRequest<SavedPlayer>(entityName: "SavedPlayer")
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        return try context.fetch(request)
    }

    private static func existingGame(id: UUID, in context: NSManagedObjectContext) throws -> Game? {
        let request = NSFetchRequest<Game>(entityName: "Game")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private static func existingSavedPlayer(
        id: UUID,
        in context: NSManagedObjectContext
    ) throws -> SavedPlayer? {
        let request = NSFetchRequest<SavedPlayer>(entityName: "SavedPlayer")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private static func existingOwnerProfile(in context: NSManagedObjectContext) throws -> OwnerProfile? {
        let request = NSFetchRequest<OwnerProfile>(entityName: "OwnerProfile")
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

enum JournalBackupError: LocalizedError {
    case missingPersistentStoreCoordinator
    case unsupportedArchiveVersion
    case invalidArchive
    case incompleteLocalProfile
    case incompleteLocalGame

    var errorDescription: String? {
        switch self {
        case .missingPersistentStoreCoordinator:
            return "Хранилище журнала недоступно."
        case .unsupportedArchiveVersion:
            return "Архив создан версией журнала, которую это приложение пока не поддерживает."
        case .invalidArchive:
            return "Архив не содержит согласованных записей и не был принят."
        case .incompleteLocalProfile:
            return "В профиле журнала отсутствует постоянный идентификатор."
        case .incompleteLocalGame:
            return "Одна из записей журнала не имеет постоянного идентификатора."
        }
    }
}

private final class ContextSaveObserver {
    var notification: Notification?
}
