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
    
    /// Справочник доступных корпораций.
    static let corporations: [String] = [
        "Credicor", "Ecoline", "Helion", "Mining Guild", "Interplanetary Cinematics",
        "Inventrix", "Phobolog", "Tharsis Republic", "Thorgate", "United Nations Mars Initiative",
        "Teractor", "Saturn Systems", "Aphrodite", "Celestic", "Manutech", "Morning Star Inc",
        "Viron", "Cheung Shing Mars", "Point Luna", "Robinson Industries", "Valley Trust", "Vitor",
        "Aridor", "Arklight", "Polyphemos", "Poseidon", "Storm Craft Incorporated", "Lakefront Resorts",
        "Pristar", "Septem Tribus", "Terralabs Research", "Utopia Invest", "Factorum", "Mons Insurance",
        "Philares", "Arcadian Communities", "Recyclon", "Splice Tactical Genomics"
    ]
    
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
