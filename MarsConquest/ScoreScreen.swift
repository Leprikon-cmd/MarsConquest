import SwiftUI
import SwiftData

struct ScoreScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Состояния
    @State private var generation: Int = 1
    @State private var scores: [Score] = [] // Используем массив Score
    @State private var selectedAchievements: [String] = []
    @State private var selectedAwards: [String] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAchievementsList = false
    @State private var showAwardsList = false
    
    // Игра, переданная из предыдущего экрана
    var game: Game
    
    var body: some View {
        NavigationView {
            Form {
                headerSection()
                playersTable()
                saveButton()
            }
            .navigationTitle("Подсчет очков")
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showAchievementsList) {
                SelectionList(
                    title: "Выберите достижение",
                    items: achievements().filter { !selectedAchievements.contains($0) },
                    onSelect: { item in
                        selectedAchievements.append(item)
                    }
                )
            }
            .sheet(isPresented: $showAwardsList) {
                SelectionList(
                    title: "Выберите награду",
                    items: awards().filter { !selectedAwards.contains($0) },
                    onSelect: { item in
                        selectedAwards.append(item)
                    }
                )
            }
            .onAppear {
                initializeScores()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    // Заголовок экрана
    private func headerSection() -> some View {
        Section(header: Text("Игра #\(game.gameNumber)")) {
            Text("Дата игры: \(game.date, formatter: dateFormatter)")
            Text("Игровое поле: \(game.gameField)")
            generationPicker()
        }
    }
    
    // Выбор поколения
    private func generationPicker() -> some View {
        Picker("Поколение", selection: $generation) {
            ForEach(1..<31, id: \.self) { number in
                Text("\(number)")
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 100)
    }
    
    // Таблица с очками
    private func playersTable() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                // Заголовок таблицы (цветовые маркеры игроков)
                HStack {
                    Text("Категория")
                        .frame(width: 120, alignment: .leading)
                    ForEach(game.players) { player in
                        Circle()
                            .fill(colorFromString(player.color))
                            .frame(width: 20, height: 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .font(.headline)
                
                // Основные категории
                scoreRow(title: "РТ", keyPath: \.terraformingRating)
                scoreRow(title: "Озеленение", keyPath: \.greenery)
                scoreRow(title: "Города", keyPath: \.cities)
                scoreRow(title: "Победные очки", keyPath: \.victoryPoints)
                scoreRow(title: "Ресурсы на картах", keyPath: \.resourcesOnCards)
                scoreRow(title: "Условия на картах", keyPath: \.conditionsOnCards)
                scoreRow(title: "Политика", keyPath: \.politics)
                
                // Кнопка "Достижения+"
                if selectedAchievements.count < 3 {
                    Button(action: {
                        showAchievementsList = true
                        showAwardsList = false
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Достижения+")
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Выбранные достижения
                if !selectedAchievements.isEmpty {
                    Section(header: Text("Достижения").font(.headline)) {
                        ForEach(selectedAchievements, id: \.self) { key in
                            scoreRow(title: key, keyPath: nil, additionalKey: key)
                        }
                    }
                }
                
                // Кнопка "Награды+"
                if selectedAwards.count < 3 {
                    Button(action: {
                        showAwardsList = true
                        showAchievementsList = false
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Награды+")
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Выбранные награды
                if !selectedAwards.isEmpty {
                    Section(header: Text("Награды").font(.headline)) {
                        ForEach(selectedAwards, id: \.self) { key in
                            scoreRow(title: key, keyPath: nil, additionalKey: key)
                        }
                    }
                }
                
                // Итог с именем победителя
                HStack {
                    Text("Итог")
                        .frame(width: 120, alignment: .leading)
                        .bold()
                    ForEach(game.players) { player in
                        Text("\(totalScore(for: player.id))")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .foregroundColor(totalScore(for: player.id) == highestScore() ? .green : .blue)
                    }
                }
                
                // Имя победителя
                if let winner = game.players.first(where: { totalScore(for: $0.id) == highestScore() }) {
                    HStack {
                        Text("Победитель:")
                            .frame(width: 120, alignment: .leading)
                            .bold()
                        Text(winner.name)
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    // Строка с очками
    private func scoreRow(title: String, keyPath: WritableKeyPath<Score, Int>?, additionalKey: String? = nil) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
            ForEach(game.players) { player in
                if let score = score(for: player.id) {
                    if let keyPath = keyPath {
                        TextField("", value: Binding(
                            get: { score[keyPath: keyPath] },
                            set: { newValue in
                                if let index = scores.firstIndex(where: { $0.playerID == player.id }) {
                                    scores[index][keyPath: keyPath] = newValue
                                }
                            }
                        ), formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else if let additionalKey = additionalKey {
                        TextField("", value: Binding(
                            get: { score.additionalPoints[additionalKey] ?? 0 },
                            set: { newValue in
                                if let index = scores.firstIndex(where: { $0.playerID == player.id }) {
                                    scores[index].additionalPoints[additionalKey] = newValue
                                }
                            }
                        ), formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    Text("N/A") // Если очки не найдены
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    // Кнопка сохранения
    private func saveButton() -> some View {
        Section {
            Button("Сохранить игру") {
                saveGame()
                dismiss()
            }
        }
    }
    
    // MARK: - Logic
    
    // Инициализация очков
    private func initializeScores() {
        for player in game.players {
            if score(for: player.id) == nil {
                let newScore = Score(playerID: player.id)
                scores.append(newScore)
                initializeAdditionalPoints(for: player.id)
            }
        }
    }
    
    // Инициализация дополнительных очков
    private func initializeAdditionalPoints(for playerID: UUID) {
        guard let score = score(for: playerID) else { return }
        
        switch game.gameField {
        case "Фарсида":
            score.additionalPoints = [
                "Колонизатор": 0,
                "Мэр": 0,
                "Садовод": 0,
                "Строитель": 0,
                "Стратег": 0,
                "Авиатор": 0,
                "Собственник": 0,
                "Банкир": 0,
                "Ученый": 0,
                "Теплотехник": 0,
                "Шахтер": 0,
                "Венерианец": 0
            ]
        case "Эллада":
            score.additionalPoints = [
                "Эрудит": 0,
                "Тактик": 0,
                "Полярник": 0,
                "Энергетик": 0,
                "Пионер": 0,
                "Авиатор": 0,
                "Агроном": 0,
                "Магнат": 0,
                "Покоритель": 0,
                "Эксцентрик": 0,
                "Подрядчик": 0,
                "Венерианец": 0
            ]
        case "Элизий":
            score.additionalPoints = [
                "Универсал": 0,
                "Специалист": 0,
                "Эколог": 0,
                "Олигарх": 0,
                "Легенда": 0,
                "Авиатор": 0,
                "Энаменитость": 0,
                "Фабрикант": 0,
                "Южанин": 0,
                "Риэлтор": 0,
                "Меценат": 0,
                "Венерианец": 0
            ]
        default:
            break
        }
    }
    
    // Получение очков для игрока
    private func score(for playerID: UUID) -> Score? {
        scores.first { $0.playerID == playerID }
    }
    
    // Достижения (зависят от игрового поля)
    private func achievements() -> [String] {
        switch game.gameField {
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
    
    // Награды (зависят от игрового поля)
    private func awards() -> [String] {
        switch game.gameField {
        case "Фарсида":
            return ["Собственник", "Банкир", "Ученый", "Теплотехник", "Шахтер", "Венерианец"]
        case "Эллада":
            return ["Агроном", "Магнат", "Покоритель", "Эксцентрик", "Подрядчик", "Венерианец"]
        case "Элизий":
            return ["Энаменитость", "Фабрикант", "Южанин", "Риэлтор", "Меценат", "Венерианец"]
        default:
            return []
        }
    }
    
    // Подсчет итога
    private func totalScore(for playerID: UUID) -> Int {
        guard let score = score(for: playerID) else { return 0 }
        return score.terraformingRating +
               score.greenery +
               score.cities +
               score.victoryPoints +
               score.resourcesOnCards +
               score.conditionsOnCards +
               score.politics +
               score.additionalPoints.values.reduce(0, +)
    }
    
    // Определение максимального количества очков
    private func highestScore() -> Int {
        game.players.map { totalScore(for: $0.id) }.max() ?? 0
    }
    
    // Валидация ввода
    private func validateInput(_ value: Int) {
        guard (0...100).contains(value) else {
            errorMessage = "Допустимый диапазон: 0-100"
            showError = true
            return
        }
    }
    
    // Преобразование цвета из String в Color
    private func colorFromString(_ color: String) -> Color {
        switch color {
        case "Красный": return .red
        case "Синий": return .blue
        case "Желтый": return .yellow
        case "Черный": return .black
        case "Зеленый": return .green
        default: return .gray
        }
    }
    
    // Сохранение игры
    private func saveGame() {
        game.generation = generation
        game.scores = scores // Сохраняем массив Score

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Не удалось сохранить игру: \(error.localizedDescription)"
            showError = true
        }
    }
}

// Экран выбора достижений или наград
struct SelectionList: View {
    let title: String
    let items: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                Button(action: {
                    onSelect(item)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(item)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Форматтер даты
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()
