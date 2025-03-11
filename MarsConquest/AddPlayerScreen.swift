import SwiftUI
import SwiftData

struct AddPlayerScreen: View {
    let color: String
    var onSave: (Player) -> Void // Замыкание теперь принимает Player
    @Environment(\.modelContext) private var modelContext // Контекст SwiftData
    @Environment(\.dismiss) private var dismiss // Закрытие экрана
    
    @State private var name: String = ""
    @State private var corporation: String = ""
    @State private var prologue1: String = ""
    @State private var prologue2: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    let corporations = GameData.corporations
    let prologues = GameData.prologues
    
    var body: some View {
        NavigationStack {
            Form {
                // Поле для ввода имени
                Section(header: Text("Имя игрока")) {
                    TextField("Введите имя CEO", text: $name)
                        .autocapitalization(.words)
                }
                
                // Выбор корпорации
                Section(header: Text("Корпорация")) {
                    Picker("Выберите корпорацию", selection: $corporation) {
                        ForEach(availableCorporations, id: \.self) { corp in
                            Text(corp)
                                .tag(corp)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Выбор первого пролога
                Section(header: Text("Первый пролог")) {
                    Picker("Выберите первый пролог", selection: $prologue1) {
                        ForEach(availablePrologues, id: \.self) { prologue in
                            Text(prologue)
                                .tag(prologue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Выбор второго пролога
                Section(header: Text("Второй пролог")) {
                    Picker("Выберите второй пролог", selection: $prologue2) {
                        ForEach(availablePrologues.filter { $0 != prologue1 }, id: \.self) { prologue in
                            Text(prologue)
                                .tag(prologue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Кнопка "Добавить"
                Section {
                    Button(action: addPlayer) {
                        Text("Добавить")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!isInputValid)
                }
            }
            .navigationTitle("Добавить игрока")
            .alert(isPresented: $showError) {
                Alert(title: Text("Ошибка"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                setInitialValues()
            }
        }
    }
    
    // Устанавливаем начальные значения
    private func setInitialValues() {
        corporation = availableCorporations.first ?? ""
        prologue1 = availablePrologues.first ?? ""
        prologue2 = availablePrologues.filter { $0 != prologue1 }.first ?? ""
    }
    
    // Доступные корпорации (исключая уже выбранные)
    private var availableCorporations: [String] {
        let usedCorporations = fetchUsedCorporations()
        return corporations.filter { !usedCorporations.contains($0) }
    }
    
    // Доступные прологи (исключая уже выбранные)
    private var availablePrologues: [String] {
        let usedPrologues = fetchUsedPrologues()
        return prologues.filter { !usedPrologues.contains($0) }
    }
    
    // Проверка валидности ввода
    private var isInputValid: Bool {
        !name.isEmpty &&
        !corporation.isEmpty &&
        !prologue1.isEmpty &&
        !prologue2.isEmpty &&
        prologue1 != prologue2
    }
    
    // Добавление игрока
    private func addPlayer() {
        guard validateInput() else { return }
        
        let player = Player(
            name: name,
            color: color,
            corporation: corporation,
            prologue1: prologue1,
            prologue2: prologue2
        )
        modelContext.insert(player)
        dismiss()
    }
    
    // Проверка уникальности выбранных значений
    private func validateInput() -> Bool {
        let isCorporationUnique = !fetchUsedCorporations().contains(corporation)
        let isPrologue1Unique = !fetchUsedPrologues().contains(prologue1)
        let isPrologue2Unique = !fetchUsedPrologues().contains(prologue2)
        
        if !isCorporationUnique {
            errorMessage = "Корпорация уже занята другим игроком."
            showError = true
            return false
        }
        
        if !isPrologue1Unique {
            errorMessage = "Первый пролог уже занят другим игроком."
            showError = true
            return false
        }
        
        if !isPrologue2Unique {
            errorMessage = "Второй пролог уже занят другим игроком."
            showError = true
            return false
        }
        
        return true
    }
    
    // Получение списка использованных корпораций
    private func fetchUsedCorporations() -> [String] {
        let descriptor = FetchDescriptor<Player>()
        let players = (try? modelContext.fetch(descriptor)) ?? []
        return players.map { $0.corporation }
    }
    
    // Получение списка использованных прологов
    private func fetchUsedPrologues() -> [String] {
        let descriptor = FetchDescriptor<Player>()
        let players = (try? modelContext.fetch(descriptor)) ?? []
        return players.flatMap { [$0.prologue1, $0.prologue2] }
    }
}
