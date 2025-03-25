//
//  AchievementsListView.swift
//
//  Зачем:
//  Экран выбора достижений для текущей партии.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - загрузка шаблонов достижений из CoreData по выбранному полю
//  - выбор до 3 достижений
//  - снятие выбранного достижения
//  - сохранение выбора в локальную модель игры
//

import SwiftUI
import CoreData

struct AchievementsListView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedItems: [LocalAchievement]
    var gameField: String
    
    @FetchRequest var achievementTemplates: FetchedResults<AchievementTemplate>

    init(selectedItems: Binding<[LocalAchievement]>, gameField: String) {
        _selectedItems = selectedItems
        self.gameField = gameField
        _achievementTemplates = FetchRequest<AchievementTemplate>(
            entity: AchievementTemplate.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "gameField == %@", gameField)
        )
    }

    var body: some View {
        List {
            ForEach(achievementTemplates, id: \.self) { template in
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
        .navigationTitle("Достижения")
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
        } else if selectedItems.count < GameConstants.maxAchievements {
            selectedItems.append(LocalAchievement(name: name))
        }
    }
}
