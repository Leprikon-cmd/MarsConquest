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
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedItems: [LocalAward]
    var gameField: String
    let hasVenus: Bool
    
    @FetchRequest var awardTemplates: FetchedResults<AwardTemplate>

    init(selectedItems: Binding<[LocalAward]>, gameField: String, hasVenus: Bool) {
        _selectedItems = selectedItems
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
                
                HStack {
                    Text(name)
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func isSelected(_ name: String) -> Bool {
        selectedItems.contains(where: { $0.name == name })
    }

    private func toggleSelection(for name: String) {
        if isSelected(name) {
            selectedItems.removeAll { $0.name == name }
        } else if selectedItems.count < GameConstants.maxAwards {
            selectedItems.append(LocalAward(name: name))
        }
    }
}
