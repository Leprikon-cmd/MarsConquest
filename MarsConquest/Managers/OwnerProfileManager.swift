import CoreData
import Foundation

struct OwnerCollectionSettings {
  var hasBaseGame: Bool
  var expansions: GameExpansions
}

/// Хранит единственный локальный профиль владельца журнала.
struct OwnerProfileManager {
  static func fetch(in context: NSManagedObjectContext) -> OwnerProfile? {
    let request: NSFetchRequest<OwnerProfile> = OwnerProfile.fetchRequest()
    request.fetchLimit = 1
    request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

    do {
      return try context.fetch(request).first
    } catch {
      print("Ошибка загрузки профиля владельца: \(error.localizedDescription)")
      return nil
    }
  }

  static func fetchSavedPlayer(
    with id: UUID,
    in context: NSManagedObjectContext
  ) -> SavedPlayer? {
    let request: NSFetchRequest<SavedPlayer> = SavedPlayer.fetchRequest()
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

    do {
      return try context.fetch(request).first
    } catch {
      print("Ошибка загрузки владельца журнала: \(error.localizedDescription)")
      return nil
    }
  }

  /// Создаёт участника новой партии из профиля владельца.
  /// UUID сохраняется тем же, чтобы новые партии сразу попадали в личный журнал.
  static func makeOwnerPlayer(
    for expansions: GameExpansions,
    in context: NSManagedObjectContext
  ) -> LocalPlayer? {
    guard
      let ownerProfile = fetch(in: context),
      let ownerID = ownerProfile.savedPlayerID,
      let savedPlayer = fetchSavedPlayer(with: ownerID, in: context)
    else {
      return nil
    }

    let name = savedPlayer.nickname ?? savedPlayer.name ?? "Владелец"
    let preferredColor = savedPlayer.favoriteColor ?? ""
    let color = GameData.colors.contains(preferredColor)
      ? preferredColor
      : GameData.colors.first ?? "Красный"
    let preludeChoices = expansions.hasPrelude ? Array(GameData.prologues.prefix(2)) : []

    return LocalPlayer(
      id: ownerID,
      name: name,
      color: color,
      corporation: GameData.beginnerCorporation,
      prologue1: preludeChoices.first ?? "",
      prologue2: preludeChoices.dropFirst().first ?? "",
      score: LocalScore()
    )
  }

  static func save(
    ownerPlayerID: UUID,
    collection: OwnerCollectionSettings,
    in context: NSManagedObjectContext
  ) throws -> OwnerProfile {
    let profile = fetch(in: context) ?? OwnerProfile(context: context)
    let now = Date()

    if profile.id == nil {
      profile.id = UUID()
      profile.createdAt = now
    }

    profile.savedPlayerID = ownerPlayerID
    profile.hasBaseGame = collection.hasBaseGame
    profile.hasPrelude = collection.expansions.hasPrelude
    profile.hasVenus = collection.expansions.hasVenus
    profile.hasColonies = collection.expansions.hasColonies
    profile.hasHellasElysium = collection.expansions.hasHellasElysium
    profile.hasTurmoil = collection.expansions.hasTurmoil
    profile.updatedAt = now

    try context.save()
    return profile
  }
}
