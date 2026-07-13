//
//  AddPlayerScreen.swift
//
//  Зачем:
//  Экран ввода данных нового игрока перед добавлением его в локальную партию.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - ввод имени игрока
//  - выбор корпорации
//  - выбор двух прологов
//  - проверка корректности ввода
//  - добавление игрока в LocalGameData
//

import SwiftUI
import CoreData

struct AddPlayerScreen: View {
    /// Среда для закрытия текущего экрана после добавления игрока.
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: SavedPlayer.entity(),
        sortDescriptors: [
            NSSortDescriptor(key: "isFavorite", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
    ) private var savedPlayers: FetchedResults<SavedPlayer>
    
    /// Цвет, заранее выбранный для нового игрока.
    let selectedColor: String
    
    /// Локальная модель текущей создаваемой игры.
    @Binding var localGame: LocalGameData
    
    /// Имя нового игрока.
    @State private var name: String = ""
    
    /// Выбранная корпорация.
    @State private var corporation: String = ""
    
    /// Первый выбранный пролог.
    @State private var prologue1: String = ""
    
    /// Второй выбранный пролог.
    @State private var prologue2: String = ""
    
    /// Флаг показа окна ошибки.
    @State private var showError = false
    
    /// Текст ошибки валидации.
    @State private var errorMessage = ""
    
    @State private var selectedSavedPlayerID: NSManagedObjectID?
    
    /// Допы
    @State private var expansions = ExpansionSettingsManager.load()
    
    /// Доступный список корпораций из справочника.
    private var corporations: [String] {
        GameData.corporations
    }
    
    /// Доступный список прологов из справочника.
    private var prologues: [String] {
        GameData.prologues
    }

    /// Сохранённые профили, которые ещё не участвуют в текущей партии.
    /// Сравниваем UUID профиля, а не имя: в приложении могут быть разные люди
    /// с одинаковым именем.
    private var availableSavedPlayers: [SavedPlayer] {
        savedPlayers.filter { savedPlayer in
            guard let profileID = savedPlayer.id else { return true }
            return !localGame.players.contains { $0.id == profileID }
        }
    }

    /// Профиль, выбранный в списке сохранённых игроков.
    private var selectedSavedPlayer: SavedPlayer? {
        guard let selectedSavedPlayerID else { return nil }
        return savedPlayers.first { $0.objectID == selectedSavedPlayerID }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !savedPlayers.isEmpty {
                    Section(header: Text("Сохранённые игроки")) {
                        Picker("Выберите игрока", selection: $selectedSavedPlayerID) {
                            Text("Новый игрок").tag(nil as NSManagedObjectID?)
                            
                            ForEach(availableSavedPlayers, id: \.objectID) { savedPlayer in
                                Text(savedPlayer.name ?? UIStrings.noName)
                                    .tag(savedPlayer.objectID as NSManagedObjectID?)
                            }
                        }
                        .onChange(of: selectedSavedPlayerID) { _, newValue in
                            guard let newValue,
                                  let savedPlayer = availableSavedPlayers.first(where: { $0.objectID == newValue }) else {
                                return
                            }
                            
                            name = savedPlayer.name ?? ""
                        }
                    }
                }
                
                Section(header: Text("Имя игрока")) {
                    TextField("Введите имя CEO", text: $name)
                        .autocapitalization(.words)
                        .disabled(selectedSavedPlayer != nil)
                }
                
                Section(header: Text("Корпорация")) {
                    Picker("Выберите корпорацию", selection: $corporation) {
                        ForEach(availableCorporations, id: \.self) { corp in
                            Text(corp).tag(corp)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                if expansions.hasPrelude {
                    Section(header: Text("Первый пролог")) {
                        Picker("Выберите первый пролог", selection: $prologue1) {
                            ForEach(availablePrologues, id: \.self) { prologue in
                                Text(prologue).tag(prologue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section(header: Text("Второй пролог")) {
                        Picker("Выберите второй пролог", selection: $prologue2) {
                            ForEach(availablePrologues.filter { $0 != prologue1 }, id: \.self) { prologue in
                                Text(prologue).tag(prologue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section {
                    Button("Добавить") {
                        addPlayer()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isInputValid)
                }
            }
            .navigationTitle("Добавить игрока")
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Ошибка"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                expansions = ExpansionSettingsManager.load()
                setInitialValues()
            }
            .onReceive(NotificationCenter.default.publisher(for: ExpansionSettingsManager.settingsChangedNotification)) { _ in
                expansions = ExpansionSettingsManager.load()
                setInitialValues()
            }
        }
    }
    
    /// Устанавливает стартовые значения полей выбора
    /// при первом открытии экрана.
    private func setInitialValues() {
        corporation = availableCorporations.first ?? ""
        prologue1 = availablePrologues.first ?? ""
        prologue2 = availablePrologues.filter { $0 != prologue1 }.first ?? ""
    }
    
    /// Возвращает список свободных корпораций,
    /// которые ещё не выбраны другими игроками текущей партии.
    private var availableCorporations: [String] {
        let usedCorporations = localGame.players.map { $0.corporation }
        return corporations.filter { !usedCorporations.contains($0) }
    }
    
    /// Возвращает список свободных прологов,
    /// которые ещё не выбраны другими игроками текущей партии.
    private var availablePrologues: [String] {
        let usedPrologues = localGame.players.flatMap { [$0.prologue1, $0.prologue2] }
        return prologues.filter { !usedPrologues.contains($0) }
    }
    
    /// Проверяет, заполнены ли обязательные поля формы
    /// и не совпадают ли два пролога у одного игрока.
    private var isInputValid: Bool {
        !trimmedName.isEmpty &&
        !corporation.isEmpty &&
        !prologue1.isEmpty &&
        !prologue2.isEmpty &&
        prologue1 != prologue2
    }

    /// Имя без случайных пробелов в начале и конце.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Создаёт нового локального игрока и добавляет его в текущую игру,
    /// если входные данные прошли валидацию.
    private func addPlayer() {
        guard validateInput() else { return }

        // Для сохранённого игрока используем постоянный UUID его профиля.
        // Это одновременно не даёт добавить профиль дважды и позволяет
        // в будущем считать статистику по человеку, а не по тексту имени.
        let playerID = selectedSavedPlayer?.id ?? UUID()

        guard !localGame.players.contains(where: { $0.id == playerID }) else {
            errorMessage = "Этот игрок уже добавлен в текущую партию."
            showError = true
            return
        }
        
        let newPlayer = LocalPlayer(
            id: playerID,
            name: trimmedName,
            color: selectedColor,
            corporation: corporation,
            prologue1: expansions.hasPrelude ? prologue1 : "",
            prologue2: expansions.hasPrelude ? prologue2 : "",
            score: LocalScore()
        )
        
        localGame.players.append(newPlayer)
        if selectedSavedPlayer == nil {
            SavedPlayerManager.savePlayerIfNeeded(
                id: playerID,
                name: newPlayer.name,
                color: newPlayer.color,
                in: viewContext
            )
        }
        presentationMode.wrappedValue.dismiss()
        
    }
    
    
    
    /// Выполняет дополнительную проверку уникальности корпорации и прологов
    /// среди уже добавленных игроков.
    ///
    /// - Returns: true, если данные корректны и игрок может быть добавлен
    private func validateInput() -> Bool {
        guard !trimmedName.isEmpty else {
            errorMessage = "Введите имя игрока."
            showError = true
            return false
        }

        // Новое имя должно быть уникально во всём списке сохранённых профилей.
        // Это не даст статистике смешать двух разных людей с одним именем.
        if selectedSavedPlayer == nil,
           savedPlayers.contains(where: { namesMatch($0.name ?? "", trimmedName) }) {
            errorMessage = "Игрок с таким именем уже существует. Выберите его из списка или добавьте уточнение к имени."
            showError = true
            return false
        }

        if localGame.players.contains(where: { namesMatch($0.name, trimmedName) }) {
            errorMessage = "Игрок с таким именем уже добавлен в текущую партию."
            showError = true
            return false
        }

        if localGame.players.contains(where: { $0.corporation == corporation }) {
            errorMessage = "Корпорация уже занята другим игроком."
            showError = true
            return false
        }
        
        if localGame.players.contains(where: { $0.prologue1 == prologue1 || $0.prologue2 == prologue1 }) {
            errorMessage = "Первый пролог уже занят другим игроком."
            showError = true
            return false
        }
        
        if localGame.players.contains(where: { $0.prologue1 == prologue2 || $0.prologue2 == prologue2 }) {
            errorMessage = "Второй пролог уже занят другим игроком."
            showError = true
            return false
        }
        
        return true
    }

    /// Сравнивает имена без учёта регистра и лишних пробелов по краям.
    private func namesMatch(_ first: String, _ second: String) -> Bool {
        first.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(second.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }
}
