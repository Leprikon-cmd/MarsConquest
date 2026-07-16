//
//  GameData.swift
//
//  Зачем:
//  Хранит справочные игровые данные и правила выбора данных
//  в зависимости от карты Марса.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - список доступных цветов игроков
//  - список корпораций
//  - список прологов
//  - список достижений по карте
//  - список наград по карте
//  - проверка соответствия CoreData-модели ожидаемым типам данных
//

import Foundation
import CoreData

struct GameData {
    
    /// Доступные цвета игроков.
    static let colors = ["Красный", "Синий", "Желтый", "Черный", "Зеленый"]
    
    /// Справочник корпораций с указанием набора, из которого они происходят.
    /// Базовые корпорации доступны всегда, остальные - только при включённом
    /// дополнении конкретной текущей партии.
    static let corporationDefinitions: [CorporationDefinition] = [
        // Базовая игра
        .init("Credicor", source: .base),
        .init("Ecoline", source: .base),
        .init("Helion", source: .base),
        .init("Mining Guild", source: .base),
        .init("Interplanetary Cinematics", source: .base),
        .init("Inventrix", source: .base),
        .init("Phobolog", source: .base),
        .init("Tharsis Republic", source: .base),
        .init("Thorgate", source: .base),
        .init("United Nations Mars Initiative", source: .base),
        .init("Teractor", source: .base),
        .init("Saturn Systems", source: .base),

        // Венера
        .init("Aphrodite", source: .venus),
        .init("Celestic", source: .venus),
        .init("Manutech", source: .venus),
        .init("Morning Star Inc", source: .venus),
        .init("Viron", source: .venus),

        // Прологи
        .init("Cheung Shing Mars", source: .prelude),
        .init("Point Luna", source: .prelude),
        .init("Robinson Industries", source: .prelude),
        .init("Valley Trust", source: .prelude),
        .init("Vitor", source: .prelude),

        // Колонии
        .init("Aridor", source: .colonies),
        .init("Arklight", source: .colonies),
        .init("Polyphemos", source: .colonies),
        .init("Poseidon", source: .colonies),
        .init("Storm Craft Incorporated", source: .colonies),
        .init("Lakefront Resorts", source: .colonies),

        // Кризис
        .init("Pristar", source: .turmoil),
        .init("Septem Tribus", source: .turmoil),
        .init("Terralabs Research", source: .turmoil),
        .init("Utopia Invest", source: .turmoil),

        // Эллада и Элизий
        .init("Factorum", source: .hellasElysium),
        .init("Mons Insurance", source: .hellasElysium),
        .init("Philares", source: .hellasElysium),
        .init("Arcadian Communities", source: .hellasElysium),
        .init("Recyclon", source: .hellasElysium),
        .init("Splice Tactical Genomics", source: .hellasElysium)
    ]

    /// Имена нужны загрузчику начальных данных Core Data.
    static var corporations: [String] {
        corporationDefinitions.map(\.name)
    }

    /// Проверяет, можно ли использовать корпорацию с набором дополнений партии.
    /// Неизвестные будущие записи оставляем доступными, чтобы новая запись
    /// справочника не исчезла у пользователя до обновления приложения.
    static func isCorporationAvailable(
        named name: String,
        for expansions: GameExpansions
    ) -> Bool {
        guard let definition = corporationDefinitions.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) else {
            return true
        }

        return definition.source.isEnabled(in: expansions)
    }
    
    /// Справочник доступных карт пролога.
    static let prologues: [String] = [
        "Allied Banks", "Aquifer Turbines", "Biofuels", "Biolab", "Biosphere Support", "Business Empire",
        "Dome Farming", "Donation", "Early Settlement", "Ecology Experts", "Excentric Sponsor",
        "Experimental Forest", "Galilean Mining", "Great Aquifer", "Huge Asteroid", "Io Research Outpost",
        "Loan", "Martian Industries", "Metal-rich Asteroid", "Metals Company", "Mining Operations",
        "Mohole", "Mohole Excavation", "Nitrogen Shipment", "Orbital Construction Yard", "Polar Industries",
        "Power Generation", "Research Network", "Self-Sufficient Settlement", "Smelting Plant",
        "Society Support", "Supplier", "Supply Drop", "UNMI Contractor", "Acquired Space Agency"
    ]
    
    /// Справочник колоний, для которых в приложении уже подготовлены карточки.
    /// Пока используется отдельно: интерфейс выбора колоний будет добавлен следующим этапом.
    static let colonies: [String] = [
        "Titan", "Pluto", "Io", "Enceladus", "Luna", "Triton",
        "Miranda", "Europa", "Ceres", "Callisto", "Ganymede"
    ]

    /// Возвращает список достижений для выбранной карты Марса.
    ///
    /// - Parameter gameField: название карты
    /// - Returns: массив названий достижений
    static func achievements(for gameField: String) -> [String] {
        switch gameField {
        case "Фарсида":
            return ["Колонизатор", "Мэр", "Садовод", "Строитель", "Стратег", "Авиатор"]
        case "Эллада":
            return ["Эрудит", "Тактик", "Полярник", "Энергетик", "Пионер", "Авиатор"]
        case "Элизий":
            return ["Универсал", "Специалист", "Эколог", "Олигарх", "Легенда", "Авиатор"]
        default:
            return []
        }
    }
    
    /// Возвращает список наград для выбранной карты Марса.
    ///
    /// - Parameter gameField: название карты
    /// - Returns: массив названий наград
    static func awards(for gameField: String) -> [String] {
        switch gameField {
        case "Фарсида":
            return ["Собственник", "Банкир", "Ученый", "Теплотехник", "Шахтер", "Венерианец"]
        case "Эллада":
            return ["Агроном", "Магнат", "Покоритель", "Эксцентрик", "Подрядчик", "Венерианец"]
        case "Элизий":
            return ["Знаменитость", "Фабрикант", "Южанин", "Риэлтор", "Меценат", "Венерианец"]
        default:
            return []
        }
    }

    /// Проверяет, что атрибут corporation в CoreData существует
    /// и имеет строковый тип.
    ///
    /// - Parameter context: контекст CoreData
    static func validateCorporations(with context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Player", in: context)
        
        guard let corporationAttribute = entity?.attributesByName["corporation"] else {
            print("Предупреждение: Атрибут corporation не найден в Core Data модели")
            return
        }
        
        if corporationAttribute.attributeType != .stringAttributeType {
            print("Предупреждение: Атрибут corporation должен быть строкового типа")
        }
    }

    /// Проверяет, что атрибуты prologue1 и prologue2 в CoreData существуют
    /// и имеют строковый тип.
    ///
    /// - Parameter context: контекст CoreData
    static func validatePrologues(with context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Player", in: context)
       
        for attr in ["prologue1", "prologue2"] {
            guard let attribute = entity?.attributesByName[attr] else {
                print("Предупреждение: Атрибут \(attr) не найден в Core Data модели")
                continue
            }
           
            if attribute.attributeType != .stringAttributeType {
                print("Предупреждение: Атрибут \(attr) должен быть строкового типа")
            }
        }
    }
}

struct CorporationDefinition {
    let name: String
    let source: CorporationSource

    init(_ name: String, source: CorporationSource) {
        self.name = name
        self.source = source
    }
}

enum CorporationSource {
    case base
    case prelude
    case venus
    case colonies
    case hellasElysium
    case turmoil

    func isEnabled(in expansions: GameExpansions) -> Bool {
        switch self {
        case .base:
            return true
        case .prelude:
            return expansions.hasPrelude
        case .venus:
            return expansions.hasVenus
        case .colonies:
            return expansions.hasColonies
        case .hellasElysium:
            return expansions.hasHellasElysium
        case .turmoil:
            return expansions.hasTurmoil
        }
    }
}
