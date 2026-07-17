//
//  ScoreTextField.swift
//  Mars LogBook
//
//  Ячейка очков с двумя состояниями:
//  отображение зафиксированного значения и его замена через цифровую клавиатуру.
//

import SwiftUI

struct ScoreTextField: View {
    @Binding private var value: Int32

    @State private var isEditing = false
    @State private var draftText = ""
    @State private var originalValue: Int32 = 0
    @State private var hasChangedDraft = false
    @FocusState private var inputIsFocused: Bool

    init(value: Binding<Int32>) {
        _value = value
    }

    var body: some View {
        Group {
            if isEditing {
                editingField()
            } else {
                savedValueButton()
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Зафиксированное число не является TextField: поэтому в нём нет курсора
    /// и случайного редактирования в середине уже введённого результата.
    private func savedValueButton() -> some View {
        Button(action: beginEditing) {
            Text(value == 0 ? "0" : String(value))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(uiColor: .separator).opacity(0.45))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: String(localized: "Очки: %d"), value))
        .accessibilityHint(String(localized: "Дважды коснитесь, чтобы заменить значение"))
    }

    /// Поле появляется только после явного тапа по зафиксированному числу.
    /// Старый результат остаётся серой подсказкой, пока пользователь не начнёт
    /// вводить новое значение.
    private func editingField() -> some View {
        TextField(String(originalValue), text: $draftText)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .focused($inputIsFocused)
            // Курсор намеренно скрыт: это режим замены целого числа, а не
            // посимвольного редактирования в его середине.
            .tint(.clear)
            .onAppear {
                inputIsFocused = true
            }
            .onChange(of: draftText) { _, newText in
                sanitizeDraft(newText)
            }
            .onChange(of: inputIsFocused) { _, isNowFocused in
                if !isNowFocused {
                    finishEditing()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    // Точка для будущего дизайна кнопки клавиатуры.
                    // Можно менять текст, иконку и цвет. Действие finishEditing()
                    // должно остаться: оно подтверждает ввод и закрывает клавиатуру.
                    Button("Готово") {
                        finishEditing()
                    }
                }
            }
    }

    private func beginEditing() {
        originalValue = value
        draftText = ""
        hasChangedDraft = false
        isEditing = true
    }

    private func sanitizeDraft(_ newText: String) {
        let digitsOnly = newText.filter(\.isNumber)

        if digitsOnly != newText {
            draftText = digitsOnly
            return
        }

        hasChangedDraft = true
    }

    private func finishEditing() {
        guard isEditing else { return }

        if hasChangedDraft {
            // Пустой результат после удаления введённых цифр считается нулём.
            value = Int32(draftText) ?? (draftText.isEmpty ? 0 : Int32.max)
        }

        inputIsFocused = false
        isEditing = false
    }
}
