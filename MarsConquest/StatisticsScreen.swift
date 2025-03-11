import SwiftUI
import SwiftData

struct StatisticsScreen: View {
    @Query(sort: \Game.date, order: .reverse) private var games: [Game]
    @State private var selectedTab: StatisticTab = .general
    
    enum StatisticTab: String, CaseIterable {
        case general = "Общая"
        case conquerors = "Покорители"
        case corporations = "Корпорации"
        case prologues = "Прологи"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Выберите вкладку", selection: $selectedTab) {
                ForEach(StatisticTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            switch selectedTab {
            case .general:
                GeneralStatisticsView(games: games)
            case .conquerors:
                ConquerorsStatisticsView(games: games)
            case .corporations:
                CorporationsStatisticsView(games: games)
            case .prologues:
                ProloguesStatisticsView(games: games)
            }
            
            Spacer()
        }
        .navigationTitle("Статистика")
        .onAppear {
            print("Загружено игр: \(games.count)")
        }
    }
}

// MARK: - Общая статистика
struct GeneralStatisticsView: View {
    var games: [Game]
    
    var body: some View {
           VStack {
               Text("Количество игр: \(games.count)")
            Text("Последняя игра: \(games.first?.date.formatted() ?? "Нет данных")")
        }
    }
}

// MARK: - Статистика по покорителям
struct ConquerorsStatisticsView: View {
    var games: [Game]
    
    var body: some View {
        List {
            Text("Статистика по покорителям")
            // Добавьте свою логику для отображения статистики по игрокам
        }
    }
}

// MARK: - Статистика по корпорациям
struct CorporationsStatisticsView: View {
    var games: [Game]
    
    var body: some View {
        List {
            Text("Статистика по корпорациям")
            // Добавьте свою логику для отображения статистики по корпорациям
        }
    }
}

// MARK: - Статистика по прологам
struct ProloguesStatisticsView: View {
    var games: [Game]
    
    var body: some View {
        List {
            Text("Статистика по прологам")
            // Добавьте свою логику для отображения статистики по прологам
        }
    }
}
