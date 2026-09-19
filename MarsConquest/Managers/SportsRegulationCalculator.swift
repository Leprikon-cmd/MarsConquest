//
//  SportsRegulationCalculator.swift
//
//  Зачем:
//  Определяет победителя по спортивному регламенту, не меняя классические очки и места.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - спортивные правила только после согласования; классический рейтинг остаётся в ScoreManager.
//

import Foundation

enum SportsRegulationCalculator {
  /// Возвращает UUID спортивного победителя. `nil` означает, что по регламенту победителя нет.
  static func winnerID(in localGame: LocalGameData) -> UUID? {
    guard let session = localGame.hostSession,
          session.configuration.isSportsMode,
          session.sportsOutcome != .generationLimitReached
    else { return nil }

    let ranking = ScoreManager().ranking(in: localGame)
    guard !ranking.isEmpty else { return nil }

    guard session.configuration.usesTimer else {
      return ranking.first?.player.id
    }

    let playersWithinTime = ranking.filter {
      !session.hasExceededTime(for: $0.player.id)
    }
    if let winner = playersWithinTime.first {
      return winner.player.id
    }

    switch session.configuration.allTimedOutRule {
    case .smallestOvertime:
      let rankingIndex = Dictionary(
        uniqueKeysWithValues: ranking.enumerated().map { ($0.element.player.id, $0.offset) }
      )
      return localGame.players.min { left, right in
        let leftElapsed = session.elapsedSeconds(for: left.id)
        let rightElapsed = session.elapsedSeconds(for: right.id)
        if leftElapsed != rightElapsed {
          return leftElapsed < rightElapsed
        }
        return (rankingIndex[left.id] ?? .max) < (rankingIndex[right.id] ?? .max)
      }?.id
    case .classicalScore:
      return ranking.first?.player.id
    case .allLose:
      return nil
    }
  }
}
