//
//  GameInfoView.swift
//
//  Зачем:
//  Показывает основные параметры текущей партии на экране подсчёта очков.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - отображение даты партии
//  - отображение выбранного игрового поля
//  - выбор количества поколений / длительности партии
//

import SwiftUI

struct GameInfoView: View {
    /// Дата текущей партии.
    let date: Date
    
    /// Название выбранного игрового поля.
    let gameField: String
    
    /// Количество поколений / длительность партии.
    @Binding var generation: Int

    
    var body: some View {
        Section(header: Text("Игра")) {
            Text("Дата: \(date, formatter: DateFormatters.shortDate)")
            Text("Поле: \(gameField)")

            HStack {
                Text("Поколение:")
                Spacer()
                
                Picker("", selection: $generation) {
                    ForEach(5...20, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 100)
            }
        }
    }
}
