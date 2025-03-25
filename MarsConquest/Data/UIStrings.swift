//
//  UIStrings.swift
//
//  Зачем:
//  Единое место хранения текстовых строк интерфейса.
//  Позволяет избежать дублирования строк в разных файлах.
//
//  Почему это важно:
//  1. Если нужно изменить текст — меняется в одном месте.
//  2. Проще добавлять локализацию в будущем.
//  3. Код становится чище и легче читать.
//
//  Как использовать:
//  Вместо прямых строк:
//
//  Text("Поле: \(game.gameField ?? "Неизвестно")")
//
//  использовать:
//
//  Text("\(UIStrings.field): \(game.gameField ?? UIStrings.unknown)")
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//

import Foundation

enum UIStrings {

    // MARK: - Общие значения

    static let unknown = "Неизвестно"
    // Используется когда данные отсутствуют
    // Пример:
    // Text(game.gameField ?? UIStrings.unknown)

    static let noName = "Без имени"
    // Используется если у игрока нет имени
    // Пример:
    // Text(player.name ?? UIStrings.noName)


    // MARK: - Игровая информация

    static let game = "Игра"
    // Заголовки секций
    // Пример:
    // Section(header: Text(UIStrings.game))

    static let date = "Дата"
    // Отображение даты партии
    // Пример:
    // Text("\(UIStrings.date): \(date, formatter: DateFormatters.shortDate)")

    static let field = "Поле"
    // Название карты Марса
    // Пример:
    // Text("\(UIStrings.field): \(game.gameField ?? UIStrings.unknown)")


    // MARK: - Награды и достижения

    static let achievements = "Достижения"
    // Заголовок блока достижений
    // Пример:
    // Text(UIStrings.achievements)

    static let awards = "Награды"
    // Заголовок блока наград
    // Пример:
    // Text(UIStrings.awards)

}
