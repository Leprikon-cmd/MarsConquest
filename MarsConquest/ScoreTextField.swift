//
//  ScoreTextField.swift
//  MarsConquest
//
//  Created by Евгений Зотчик on 06.03.2025.
//
import SwiftUI

// Кастомное текстовое поле с названием
struct ScoreTextField: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        HStack {
            Text(title) // Название поля
                .frame(width: 150, alignment: .leading) // Фиксированная ширина для выравнивания
            Spacer()
            TextField("", value: $value, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing) // Выравнивание текста справа
        }
    }
}
