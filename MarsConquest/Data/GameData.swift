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
    /// Базовая корпорация для начинающих игроков и безопасная замена
    /// корпорациям отключённых дополнений.
    static let beginnerCorporation = "Beginner Corporation"

    
    /// Доступные цвета игроков.
    static let colors = ["Красный", "Синий", "Желтый", "Черный", "Зеленый"]
    
    /// Справочник корпораций с указанием набора, из которого они происходят.
    /// Базовые корпорации доступны всегда, остальные - только при включённом
    /// дополнении конкретной текущей партии.
    static let corporationDefinitions: [CorporationDefinition] = [
        // Базовая игра
        .init(id: "corporation.beginner", name: beginnerCorporation, source: .base),
        .init(id: "corporation.credicor", name: "Credicor", source: .base),
        .init(id: "corporation.ecoline", name: "Ecoline", source: .base),
        .init(id: "corporation.helion", name: "Helion", source: .base),
        .init(id: "corporation.mining_guild", name: "Mining Guild", source: .base),
        .init(id: "corporation.interplanetary_cinematics", name: "Interplanetary Cinematics", source: .base),
        .init(id: "corporation.inventrix", name: "Inventrix", source: .base),
        .init(id: "corporation.phobolog", name: "Phobolog", source: .base),
        .init(id: "corporation.tharsis_republic", name: "Tharsis Republic", source: .base),
        .init(id: "corporation.thorgate", name: "Thorgate", source: .base),
        .init(id: "corporation.united_nations_mars_initiative", name: "United Nations Mars Initiative", source: .base),
        .init(id: "corporation.teractor", name: "Teractor", source: .base),
        .init(id: "corporation.saturn_systems", name: "Saturn Systems", source: .base),

        // Венера
        .init(id: "corporation.aphrodite", name: "Aphrodite", source: .venus),
        .init(id: "corporation.celestic", name: "Celestic", source: .venus),
        .init(id: "corporation.manutech", name: "Manutech", source: .venus),
        .init(id: "corporation.morning_star_inc", name: "Morning Star Inc", source: .venus),
        .init(id: "corporation.viron", name: "Viron", source: .venus),

        // Прологи
        .init(id: "corporation.cheung_shing_mars", name: "Cheung Shing Mars", source: .prelude),
        .init(id: "corporation.point_luna", name: "Point Luna", source: .prelude),
        .init(id: "corporation.robinson_industries", name: "Robinson Industries", source: .prelude),
        .init(id: "corporation.valley_trust", name: "Valley Trust", source: .prelude),
        .init(id: "corporation.vitor", name: "Vitor", source: .prelude),

        // Колонии
        .init(id: "corporation.aridor", name: "Aridor", source: .colonies),
        .init(id: "corporation.arklight", name: "Arklight", source: .colonies),
        .init(id: "corporation.polyphemos", name: "Polyphemos", source: .colonies),
        .init(id: "corporation.poseidon", name: "Poseidon", source: .colonies),
        .init(id: "corporation.storm_craft_incorporated", name: "Storm Craft Incorporated", source: .colonies),
        .init(id: "corporation.lakefront_resorts", name: "Lakefront Resorts", source: .colonies),

        // Кризис
        .init(id: "corporation.pristar", name: "Pristar", source: .turmoil),
        .init(id: "corporation.septem_tribus", name: "Septem Tribus", source: .turmoil),
        .init(id: "corporation.terralabs_research", name: "Terralabs Research", source: .turmoil),
        .init(id: "corporation.utopia_invest", name: "Utopia Invest", source: .turmoil),

        // Эллада и Элизий
        .init(id: "corporation.factorum", name: "Factorum", source: .hellasElysium),
        .init(id: "corporation.mons_insurance", name: "Mons Insurance", source: .hellasElysium),
        .init(id: "corporation.philares", name: "Philares", source: .hellasElysium),
        .init(id: "corporation.arcadian_communities", name: "Arcadian Communities", source: .hellasElysium),
        .init(id: "corporation.recyclon", name: "Recyclon", source: .hellasElysium),
        .init(id: "corporation.splice_tactical_genomics", name: "Splice Tactical Genomics", source: .hellasElysium)
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

    /// Постоянный ключ корпорации. Пока он используется только каталогом;
    /// в Core Data начнём сохранять его отдельной, следующей миграцией.
    static func corporationID(named name: String) -> String? {
        corporationDefinitions.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }?.id
    }
    
    /// Справочник доступных карт пролога с постоянными идентификаторами.
    static let preludeDefinitions: [GameReference] = [
        .init(id: "prelude.allied_banks", name: "Allied Banks"),
        .init(id: "prelude.aquifer_turbines", name: "Aquifer Turbines"),
        .init(id: "prelude.biofuels", name: "Biofuels"),
        .init(id: "prelude.biolab", name: "Biolab"),
        .init(id: "prelude.biosphere_support", name: "Biosphere Support"),
        .init(id: "prelude.business_empire", name: "Business Empire"),
        .init(id: "prelude.dome_farming", name: "Dome Farming"),
        .init(id: "prelude.donation", name: "Donation"),
        .init(id: "prelude.early_settlement", name: "Early Settlement"),
        .init(id: "prelude.ecology_experts", name: "Ecology Experts"),
        .init(id: "prelude.excentric_sponsor", name: "Excentric Sponsor"),
        .init(id: "prelude.experimental_forest", name: "Experimental Forest"),
        .init(id: "prelude.galilean_mining", name: "Galilean Mining"),
        .init(id: "prelude.great_aquifer", name: "Great Aquifer"),
        .init(id: "prelude.huge_asteroid", name: "Huge Asteroid"),
        .init(id: "prelude.io_research_outpost", name: "Io Research Outpost"),
        .init(id: "prelude.loan", name: "Loan"),
        .init(id: "prelude.martian_industries", name: "Martian Industries"),
        .init(id: "prelude.metal_rich_asteroid", name: "Metal-rich Asteroid"),
        .init(id: "prelude.metals_company", name: "Metals Company"),
        .init(id: "prelude.mining_operations", name: "Mining Operations"),
        .init(id: "prelude.mohole", name: "Mohole"),
        .init(id: "prelude.mohole_excavation", name: "Mohole Excavation"),
        .init(id: "prelude.nitrogen_shipment", name: "Nitrogen Shipment"),
        .init(id: "prelude.orbital_construction_yard", name: "Orbital Construction Yard"),
        .init(id: "prelude.polar_industries", name: "Polar Industries"),
        .init(id: "prelude.power_generation", name: "Power Generation"),
        .init(id: "prelude.research_network", name: "Research Network"),
        .init(id: "prelude.self_sufficient_settlement", name: "Self-Sufficient Settlement"),
        .init(id: "prelude.smelting_plant", name: "Smelting Plant"),
        .init(id: "prelude.society_support", name: "Society Support"),
        .init(id: "prelude.supplier", name: "Supplier"),
        .init(id: "prelude.supply_drop", name: "Supply Drop"),
        .init(id: "prelude.unmi_contractor", name: "UNMI Contractor"),
        .init(id: "prelude.acquired_space_agency", name: "Acquired Space Agency")
    ]

    static var prologues: [String] {
        preludeDefinitions.map(\.name)
    }

    /// Русские названия берутся с локализованных карточек. Каноническое
    /// английское имя остаётся в данных партии и используется как ключ.
    private static let russianPreludeNames: [String: String] = [
        "prelude.acquired_space_agency": "Космическое агентство",
        "prelude.allied_banks": "Подконтрольный банк",
        "prelude.aquifer_turbines": "Гидротурбины",
        "prelude.biofuels": "Биотопливо",
        "prelude.biolab": "Биолаборатория",
        "prelude.biosphere_support": "Поддержание биосферы",
        "prelude.business_empire": "Бизнес-империя",
        "prelude.dome_farming": "Земледелие под куполом",
        "prelude.donation": "Субсидия",
        "prelude.early_settlement": "Первое поселение",
        "prelude.ecology_experts": "Эксперты-экологи",
        "prelude.excentric_sponsor": "Эпатажный спонсор",
        "prelude.experimental_forest": "Экспериментальный лес",
        "prelude.galilean_mining": "Промысел на спутниках Юпитера",
        "prelude.great_aquifer": "Огромный аквифер",
        "prelude.huge_asteroid": "Огромный астероид",
        "prelude.io_research_outpost": "Исследовательский аванпост на Ио",
        "prelude.loan": "Ссуда",
        "prelude.martian_industries": "Промышленность на Марсе",
        "prelude.metal_rich_asteroid": "Металлический астероид",
        "prelude.metals_company": "Металлургическая компания",
        "prelude.mining_operations": "Горные работы",
        "prelude.mohole": "Проект «Мохол»",
        "prelude.mohole_excavation": "Глубокое бурение",
        "prelude.nitrogen_shipment": "Поставка азота",
        "prelude.orbital_construction_yard": "Орбитальная строительная база",
        "prelude.polar_industries": "Полярная промышленность",
        "prelude.power_generation": "Энергоснабжение",
        "prelude.research_network": "Исследовательская сеть",
        "prelude.self_sufficient_settlement": "Независимое поселение",
        "prelude.smelting_plant": "Плавильный завод",
        "prelude.society_support": "Поддержка общества",
        "prelude.supplier": "Поставщик",
        "prelude.supply_drop": "Поставка снабжения",
        "prelude.unmi_contractor": "Подрядчик МИОН"
    ]

    static func preludeID(named name: String) -> String? {
        preludeDefinitions.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }?.id
    }

    static func localizedPreludeName(
        persistedName: String?,
        referenceID: String?,
        locale: Locale
    ) -> String {
        let fallbackName = persistedName ?? "—"
        guard !locale.identifier.lowercased().hasPrefix("en") else {
            return fallbackName
        }

        let resolvedID = referenceID ?? preludeID(named: fallbackName)
        return resolvedID.flatMap { russianPreludeNames[$0] } ?? fallbackName
    }
    
    /// Справочник колоний, для которых в приложении уже подготовлены карточки.
    /// Пока используется отдельно: интерфейс выбора колоний будет добавлен следующим этапом.
    static let colonyDefinitions: [GameReference] = [
        .init(id: "colony.titan", name: "Titan"),
        .init(id: "colony.pluto", name: "Pluto"),
        .init(id: "colony.io", name: "Io"),
        .init(id: "colony.enceladus", name: "Enceladus"),
        .init(id: "colony.luna", name: "Luna"),
        .init(id: "colony.triton", name: "Triton"),
        .init(id: "colony.miranda", name: "Miranda"),
        .init(id: "colony.europa", name: "Europa"),
        .init(id: "colony.ceres", name: "Ceres"),
        .init(id: "colony.callisto", name: "Callisto"),
        .init(id: "colony.ganymede", name: "Ganymede")
    ]

    static var colonies: [String] {
        colonyDefinitions.map(\.name)
    }

    /// Русские названия колоний с локализованных планшетов. Английские имена
    /// остаются каноническими для сохранения и поиска ресурсов.
    private static let russianColonyNames: [String: String] = [
        "colony.titan": "Титан",
        "colony.pluto": "Плутон",
        "colony.io": "Ио",
        "colony.enceladus": "Энцелад",
        "colony.luna": "Луна",
        "colony.triton": "Тритон",
        "colony.miranda": "Миранда",
        "colony.europa": "Европа",
        "colony.ceres": "Церера",
        "colony.callisto": "Каллисто",
        "colony.ganymede": "Ганимед"
    ]

    static func colonyID(named name: String) -> String? {
        colonyDefinitions.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }?.id
    }

    static func localizedColonyName(
        persistedName: String?,
        referenceID: String?,
        locale: Locale
    ) -> String {
        let fallbackName = persistedName ?? "—"
        guard !locale.identifier.lowercased().hasPrefix("en") else {
            return fallbackName
        }

        let resolvedID = referenceID ?? colonyID(named: fallbackName)
        return resolvedID.flatMap { russianColonyNames[$0] } ?? fallbackName
    }

    /// Постоянный ключ игрового поля для сохранения в новых партиях.
    static func gameFieldID(named name: String) -> String? {
        GameField.resolve(persistedName: name, referenceID: nil)?.referenceID
    }

    /// Справочник достижений с постоянными ключами для каждого поля.
    static let achievementDefinitions: [String: [GameReference]] = [
        GameField.farsida.rawValue: [
            .init(id: "achievement.tharsis.colonizer", name: "Колонизатор"),
            .init(id: "achievement.tharsis.mayor", name: "Мэр"),
            .init(id: "achievement.tharsis.gardener", name: "Садовод"),
            .init(id: "achievement.tharsis.builder", name: "Строитель"),
            .init(id: "achievement.tharsis.strategist", name: "Стратег"),
            .init(id: "achievement.tharsis.aviator", name: "Авиатор")
        ],
        GameField.hellas.rawValue: [
            .init(id: "achievement.hellas.scholar", name: "Эрудит"),
            .init(id: "achievement.hellas.tactician", name: "Тактик"),
            .init(id: "achievement.hellas.polar_explorer", name: "Полярник"),
            .init(id: "achievement.hellas.energizer", name: "Энергетик"),
            .init(id: "achievement.hellas.pioneer", name: "Пионер"),
            .init(id: "achievement.hellas.aviator", name: "Авиатор")
        ],
        GameField.elysium.rawValue: [
            .init(id: "achievement.elysium.generalist", name: "Универсал"),
            .init(id: "achievement.elysium.specialist", name: "Специалист"),
            .init(id: "achievement.elysium.ecologist", name: "Эколог"),
            .init(id: "achievement.elysium.oligarch", name: "Олигарх"),
            .init(id: "achievement.elysium.legend", name: "Легенда"),
            .init(id: "achievement.elysium.aviator", name: "Авиатор")
        ]
    ]

    /// Справочник наград с постоянными ключами для каждого поля.
    static let awardDefinitions: [String: [GameReference]] = [
        GameField.farsida.rawValue: [
            .init(id: "award.tharsis.landlord", name: "Собственник"),
            .init(id: "award.tharsis.banker", name: "Банкир"),
            .init(id: "award.tharsis.scientist", name: "Ученый"),
            .init(id: "award.tharsis.thermalist", name: "Теплотехник"),
            .init(id: "award.tharsis.miner", name: "Шахтер"),
            .init(id: "award.tharsis.venuphile", name: "Венерианец")
        ],
        GameField.hellas.rawValue: [
            .init(id: "award.hellas.cultivator", name: "Агроном"),
            .init(id: "award.hellas.magnate", name: "Магнат"),
            .init(id: "award.hellas.space_baron", name: "Покоритель"),
            .init(id: "award.hellas.eccentric", name: "Эксцентрик"),
            .init(id: "award.hellas.contractor", name: "Подрядчик"),
            .init(id: "award.hellas.venuphile", name: "Венерианец")
        ],
        GameField.elysium.rawValue: [
            .init(id: "award.elysium.celebrity", name: "Знаменитость"),
            .init(id: "award.elysium.industrialist", name: "Фабрикант"),
            .init(id: "award.elysium.desert_settler", name: "Южанин"),
            .init(id: "award.elysium.estate_dealer", name: "Риэлтор"),
            .init(id: "award.elysium.benefactor", name: "Меценат"),
            .init(id: "award.elysium.venuphile", name: "Венерианец")
        ]
    ]

    /// Возвращает список достижений для выбранного поля.
    static func achievements(for gameField: String) -> [String] {
        achievementDefinitions[gameField, default: []].map(\.name)
    }

    /// Возвращает список наград для выбранного поля.
    static func awards(for gameField: String) -> [String] {
        awardDefinitions[gameField, default: []].map(\.name)
    }

    static func achievementID(named name: String, for gameField: String) -> String? {
        achievementDefinitions[gameField]?.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }?.id
    }

    static func awardID(named name: String, for gameField: String) -> String? {
        awardDefinitions[gameField]?.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }?.id
    }

    /// Английские отображаемые названия достижений.
    /// Русское имя остаётся в Core Data для совместимости с уже сохранёнными партиями.
    private static let achievementEnglishNames: [String: String] = [
        "achievement.tharsis.colonizer": "Colonizer",
        "achievement.tharsis.mayor": "Mayor",
        "achievement.tharsis.gardener": "Gardener",
        "achievement.tharsis.builder": "Builder",
        "achievement.tharsis.strategist": "Strategist",
        "achievement.tharsis.aviator": "Aviator",
        "achievement.hellas.scholar": "Scholar",
        "achievement.hellas.tactician": "Tactician",
        "achievement.hellas.polar_explorer": "Polar Explorer",
        "achievement.hellas.energizer": "Energizer",
        "achievement.hellas.pioneer": "Pioneer",
        "achievement.hellas.aviator": "Aviator",
        "achievement.elysium.generalist": "Generalist",
        "achievement.elysium.specialist": "Specialist",
        "achievement.elysium.ecologist": "Ecologist",
        "achievement.elysium.oligarch": "Oligarch",
        "achievement.elysium.legend": "Legend",
        "achievement.elysium.aviator": "Aviator"
    ]

    /// Английские отображаемые названия наград.
    private static let awardEnglishNames: [String: String] = [
        "award.tharsis.landlord": "Landlord",
        "award.tharsis.banker": "Banker",
        "award.tharsis.scientist": "Scientist",
        "award.tharsis.thermalist": "Thermalist",
        "award.tharsis.miner": "Miner",
        "award.tharsis.venuphile": "Venuphile",
        "award.hellas.cultivator": "Cultivator",
        "award.hellas.magnate": "Magnate",
        "award.hellas.space_baron": "Space Baron",
        "award.hellas.eccentric": "Eccentric",
        "award.hellas.contractor": "Contractor",
        "award.hellas.venuphile": "Venuphile",
        "award.elysium.celebrity": "Celebrity",
        "award.elysium.industrialist": "Industrialist",
        "award.elysium.desert_settler": "Desert Settler",
        "award.elysium.estate_dealer": "Estate Dealer",
        "award.elysium.benefactor": "Benefactor",
        "award.elysium.venuphile": "Venuphile"
    ]

    static func localizedAchievementName(
        referenceID: String?,
        fallbackName: String,
        locale: Locale
    ) -> String {
        guard locale.identifier.lowercased().hasPrefix("en") else { return fallbackName }
        return referenceID.flatMap { achievementEnglishNames[$0] } ?? fallbackName
    }

    static func localizedAwardName(
        referenceID: String?,
        fallbackName: String,
        locale: Locale
    ) -> String {
        guard locale.identifier.lowercased().hasPrefix("en") else { return fallbackName }
        return referenceID.flatMap { awardEnglishNames[$0] } ?? fallbackName
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
    let id: String
    let name: String
    let source: CorporationSource

    init(id: String, name: String, source: CorporationSource) {
        self.id = id
        self.name = name
        self.source = source
    }
}

struct GameReference {
    let id: String
    let name: String
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
