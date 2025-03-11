import SwiftData
import Foundation

@Model
final class Score: Codable { // Codable = Encodable + Decodable
    var playerID: UUID
    var terraformingRating: Int
    var greenery: Int
    var cities: Int
    var victoryPoints: Int
    var resourcesOnCards: Int
    var conditionsOnCards: Int
    var politics: Int
    var additionalPoints: [String: Int]

    // Инициализатор
    init(
        playerID: UUID,
        terraformingRating: Int = 0,
        greenery: Int = 0,
        cities: Int = 0,
        victoryPoints: Int = 0,
        resourcesOnCards: Int = 0,
        conditionsOnCards: Int = 0,
        politics: Int = 0,
        additionalPoints: [String: Int] = [:]
    ) {
        self.playerID = playerID
        self.terraformingRating = terraformingRating
        self.greenery = greenery
        self.cities = cities
        self.victoryPoints = victoryPoints
        self.resourcesOnCards = resourcesOnCards
        self.conditionsOnCards = conditionsOnCards
        self.politics = politics
        self.additionalPoints = additionalPoints
    }

    // Реализация Encodable
    enum CodingKeys: String, CodingKey {
        case playerID
        case terraformingRating
        case greenery
        case cities
        case victoryPoints
        case resourcesOnCards
        case conditionsOnCards
        case politics
        case additionalPoints
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerID, forKey: .playerID)
        try container.encode(terraformingRating, forKey: .terraformingRating)
        try container.encode(greenery, forKey: .greenery)
        try container.encode(cities, forKey: .cities)
        try container.encode(victoryPoints, forKey: .victoryPoints)
        try container.encode(resourcesOnCards, forKey: .resourcesOnCards)
        try container.encode(conditionsOnCards, forKey: .conditionsOnCards)
        try container.encode(politics, forKey: .politics)
        try container.encode(additionalPoints, forKey: .additionalPoints)
    }

    // Реализация Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerID = try container.decode(UUID.self, forKey: .playerID)
        terraformingRating = try container.decode(Int.self, forKey: .terraformingRating)
        greenery = try container.decode(Int.self, forKey: .greenery)
        cities = try container.decode(Int.self, forKey: .cities)
        victoryPoints = try container.decode(Int.self, forKey: .victoryPoints)
        resourcesOnCards = try container.decode(Int.self, forKey: .resourcesOnCards)
        conditionsOnCards = try container.decode(Int.self, forKey: .conditionsOnCards)
        politics = try container.decode(Int.self, forKey: .politics)
        additionalPoints = try container.decode([String: Int].self, forKey: .additionalPoints)
    }
}
