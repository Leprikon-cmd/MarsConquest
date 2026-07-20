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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    
    @Binding var selectedItems: [LocalAchievement]
    /// Черновой выбор. Попадает в партию только после явного подтверждения.
    @State private var pendingItems: [LocalAchievement]
    var gameField: String
    let hasVenus: Bool
    
    @FetchRequest var achievementTemplates: FetchedResults<AchievementTemplate>

    init(selectedItems: Binding<[LocalAchievement]>, gameField: String, hasVenus: Bool) {
        _selectedItems = selectedItems
        _pendingItems = State(initialValue: selectedItems.wrappedValue)
        self.gameField = gameField
        self.hasVenus = hasVenus
        _achievementTemplates = FetchRequest<AchievementTemplate>(
            entity: AchievementTemplate.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "gameField == %@", gameField)
        )
    }
    
    private var filteredAchievementTemplates: [AchievementTemplate] {
        achievementTemplates.filter { template in
            guard let name = template.name else { return false }
            return hasVenus || name != "Авиатор"
        }
    }
    var body: some View {
        List {
            ForEach(filteredAchievementTemplates, id: \.self) { template in
                let name = template.name ?? "Без имени"
                let displayName = GameData.localizedAchievementName(
                    referenceID: GameData.achievementID(named: name, for: gameField),
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
        .navigationTitle("Достижения")
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
        } else if pendingItems.count < GameConstants.maxAchievements {
            pendingItems.append(LocalAchievement(name: name))
        }
    }
}
