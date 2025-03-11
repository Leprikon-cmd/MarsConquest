import SwiftData
import Foundation

@Model
final class Player: Codable {
    var id: UUID
    var name: String
    var color: String
    var corporation: String
    var prologue1: String
    var prologue2: String

    init(
        id: UUID = UUID(),
        name: String,
        color: String,
        corporation: String,
        prologue1: String,
        prologue2: String
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.corporation = corporation
        self.prologue1 = prologue1
        self.prologue2 = prologue2
    }

    // Реализация Codable (если требуется)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case corporation
        case prologue1
        case prologue2
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        corporation = try container.decode(String.self, forKey: .corporation)
        prologue1 = try container.decode(String.self, forKey: .prologue1)
        prologue2 = try container.decode(String.self, forKey: .prologue2)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(corporation, forKey: .corporation)
        try container.encode(prologue1, forKey: .prologue1)
        try container.encode(prologue2, forKey: .prologue2)
    }
}
