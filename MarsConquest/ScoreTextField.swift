//
//  ScoreTextField.swift
//  Mars LogBook
//
//  Поле ввода очков: пустое значение считается нулём,
//  а отрицательные числа не допускаются.
//

import SwiftUI
import UIKit

/// Числовое поле, в котором повторный тап выделяет всё значение целиком.
/// Поэтому новое число заменяет старое, а не дописывается в середину или конец.
struct ScoreTextField: UIViewRepresentable {
    @Binding private var value: Int32

    init(value: Binding<Int32>) {
        _value = value
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.placeholder = "0"
        textField.delegate = context.coordinator
        textField.accessibilityLabel = "Очки"
        context.coordinator.textField = textField

        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()

        // Точка для будущего дизайна кнопки клавиатуры.
        // Здесь можно изменить текст, иконку или цвет, но действие
        // doneButtonTapped должно остаться: оно закрывает клавиатуру.
        let flexibleSpace = UIBarButtonItem(systemItem: .flexibleSpace)
        let doneButton = UIBarButtonItem(
            title: "Готово",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneButtonTapped)
        )
        keyboardToolbar.items = [flexibleSpace, doneButton]
        textField.inputAccessoryView = keyboardToolbar
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Во время ввода UIKit сам управляет содержимым поля. Внешние изменения
        // (например, бонус за награду) отображаем сразу, когда поле не активно.
        guard !textField.isFirstResponder else { return }

        let displayedValue = value == 0 ? "" : String(value)
        if textField.text != displayedValue {
            textField.text = displayedValue
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private var value: Binding<Int32>
        weak var textField: UITextField?

        init(value: Binding<Int32>) {
            self.value = value
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Оставляем старое число видимым, но готовым к полной замене.
            // При выходе без ввода оно так и останется прежним.
            textField.selectAll(nil)
        }

        @objc func doneButtonTapped() {
            textField?.resignFirstResponder()
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""
            guard let swiftRange = Range(range, in: currentText) else { return false }

            let proposedText = currentText.replacingCharacters(in: swiftRange, with: string)
            let digitsOnly = proposedText.filter(\.isNumber)

            // Не даём вставить знак, пробел или иной нечисловой символ.
            guard proposedText == digitsOnly else { return false }

            value.wrappedValue = Int32(digitsOnly) ?? (digitsOnly.isEmpty ? 0 : Int32.max)
            return true
        }
    }
}
