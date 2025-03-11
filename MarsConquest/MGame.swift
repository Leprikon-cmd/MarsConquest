import SwiftData
import Foundation

@Model
final class Game: Codable {
    var id: UUID
    var gameNumber: Int
    var date: Date
    var gameField: String
    var generation: Int
    
    @Relationship(deleteRule: .cascade)
    var players: [Player]
    
    @Relationship(deleteRule: .cascade)
    var scores: [Score]

    init(
        id: UUID = UUID(),
        gameNumber: Int,
        date: Date = Date(),
        gameField: String,
        generation: Int = 0,
        players: [Player] = [],
        scores: [Score] = []
    ) {
        self.id = id
        self.gameNumber = gameNumber
        self.date = date
        self.gameField = gameField
        self.generation = generation
        self.players = players
        self.scores = scores
    }

    // Реализация Codable (если требуется)
    enum CodingKeys: String, CodingKey {
        case id
        case gameNumber
        case date
        case gameField
        case generation
        case players
        case scores
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        gameNumber = try container.decode(Int.self, forKey: .gameNumber)
        date = try container.decode(Date.self, forKey: .date)
        gameField = try container.decode(String.self, forKey: .gameField)
        generation = try container.decode(Int.self, forKey: .generation)
        players = try container.decode([Player].self, forKey: .players)
        scores = try container.decode([Score].self, forKey: .scores)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gameNumber, forKey: .gameNumber)
        try container.encode(date, forKey: .date)
        try container.encode(gameField, forKey: .gameField)
        try container.encode(generation, forKey: .generation)
        try container.encode(players, forKey: .players)
        try container.encode(scores, forKey: .scores)
    }
}
