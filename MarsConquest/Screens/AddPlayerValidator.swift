import Foundation

/// Проверяет заполненную карточку игрока, не управляя интерфейсом и сохранением.
enum AddPlayerValidator {
  static func errorMessage(
    name: String,
    corporation: String,
    prologue1: String,
    prologue2: String,
    hasPrelude: Bool,
    editingPlayerID: UUID?,
    isUsingSavedPlayer: Bool,
    savedPlayers: [SavedPlayer],
    localPlayers: [LocalPlayer],
    locale: Locale
  ) -> String? {
    guard !name.isEmpty else {
      return String(localized: "Введите имя игрока.", locale: locale)
    }

    if !isUsingSavedPlayer,
      savedPlayers.contains(where: {
        $0.id != editingPlayerID && namesMatch($0.name ?? "", name)
      })
    {
      return String(
        localized: "Игрок с таким именем уже существует. Выберите его из списка или добавьте уточнение к имени.",
        locale: locale
      )
    }

    if localPlayers.contains(where: {
      $0.id != editingPlayerID && namesMatch($0.name, name)
    }) {
      return String(
        localized: "Игрок с таким именем уже добавлен в текущую партию.",
        locale: locale
      )
    }

    if localPlayers.contains(where: {
      $0.id != editingPlayerID && $0.corporation == corporation
    }) {
      return String(localized: "Корпорация уже занята другим игроком.", locale: locale)
    }

    if hasPrelude,
      localPlayers.contains(where: {
        $0.id != editingPlayerID && ($0.prologue1 == prologue1 || $0.prologue2 == prologue1)
      })
    {
      return String(localized: "Первый пролог уже занят другим игроком.", locale: locale)
    }

    if hasPrelude,
      localPlayers.contains(where: {
        $0.id != editingPlayerID && ($0.prologue1 == prologue2 || $0.prologue2 == prologue2)
      })
    {
      return String(localized: "Второй пролог уже занят другим игроком.", locale: locale)
    }

    return nil
  }

  private static func namesMatch(_ first: String, _ second: String) -> Bool {
    first.trimmingCharacters(in: .whitespacesAndNewlines)
      .caseInsensitiveCompare(second.trimmingCharacters(in: .whitespacesAndNewlines))
      == .orderedSame
  }
}
