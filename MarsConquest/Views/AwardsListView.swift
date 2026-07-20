//
//  AwardsListView.swift
//
//  Зачем:
//  Экран выбора наград для текущей партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - загрузка шаблонов наград из CoreData по выбранному полю
//  - выбор до 3 наград
//  - снятие выбранной награды
//  - сохранение выбора в локальную модель игры
//

import SwiftUI
import CoreData

struct AwardsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    
    @Binding var selectedItems: [LocalAward]
    /// Черновой выбор. Попадает в партию только после явного подтверждения.
    @State private var pendingItems: [LocalAward]
    var gameField: String
    let hasVenus: Bool
    
    @FetchRequest var awardTemplates: FetchedResults<AwardTemplate>

    init(selectedItems: Binding<[LocalAward]>, gameField: String, hasVenus: Bool) {
        _selectedItems = selectedItems
        _pendingItems = State(initialValue: selectedItems.wrappedValue)
        self.gameField = gameField
        self.hasVenus = hasVenus
        _awardTemplates = FetchRequest<AwardTemplate>(
            entity: AwardTemplate.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "gameField == %@", gameField)
        )
    }
    
    private var filteredAwardTemplates: [AwardTemplate] {
        awardTemplates.filter { template in
            guard let name = template.name else { return false }
            return hasVenus || name != "Венерианец"
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredAwardTemplates, id: \.self) { template in
                let name = template.name ?? "Без имени"
                let displayName = GameData.localizedAwardName(
                    referenceID: GameData.awardID(named: name, for: gameField),
                    fallbackName: name,
                    locale: locale
                )
                
                HStack {
                    Text(displayName)
                    Spacer()
                    if isSelected(name) {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(for: name)
                }
            }
        }
        .navigationTitle("Награды")
        .safeAreaInset(edge: .bottom) {
            Button("Добавить выбранное") {
                selectedItems = pendingItems
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.bar)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") {
                    dismiss()
                }
            }
        }
    }

    private func isSelected(_ name: String) -> Bool {
        pendingItems.contains(where: { $0.name == name })
    }

    private func toggleSelection(for name: String) {
        if isSelected(name) {
            pendingItems.removeAll { $0.name == name }
        } else if pendingItems.count < GameConstants.maxAwards {
            pendingItems.append(LocalAward(name: name))
        }
    }
}
