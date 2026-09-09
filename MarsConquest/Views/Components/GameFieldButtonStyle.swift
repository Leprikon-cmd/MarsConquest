//
//  GameFieldButtonStyle.swift
//
//  Зачем:
//  Оформляет действия фоном выбранного игрового поля.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - имена button-for-* в Assets, размер шрифта и тень кнопки.
//
import SwiftUI

/// Оформляет действие фоном выбранного игрового поля.
private struct GameFieldButtonStyle: ViewModifier {
    let gameField: String?
    let fontSize: CGFloat

    private var imageName: String {
        switch GameField.resolve(persistedName: gameField, referenceID: nil) {
        case .hellas:
            return "button-for-hellas"
        case .elysium:
            return "button-for-elysium"
        case .farsida, .none:
            return "button-for-farsida"
        }
    }

    func body(content: Content) -> some View {
        content
            .font(AppFont.fixed(fontSize))
            .foregroundStyle(.black)
            .background {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Компактная версия для двух соседних кнопок: показывает рамку целиком без обрезки.
private struct CompactGameFieldButtonStyle: ViewModifier {
    let gameField: String?
    let fontSize: CGFloat

    private var imageName: String {
        switch GameField.resolve(persistedName: gameField, referenceID: nil) {
        case .hellas:
            return "compact-button-hellas"
        case .elysium:
            return "compact-button-elysium"
        case .farsida, .none:
            return "compact-button-farsida"
        }
    }

    func body(content: Content) -> some View {
        content
            .font(AppFont.fixed(fontSize))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    /// Применяет единый стиль кнопок, зависящий от игрового поля.
    func gameFieldButtonStyle(
        for gameField: String?,
        fontSize: CGFloat = 20
    ) -> some View {
        modifier(GameFieldButtonStyle(gameField: gameField, fontSize: fontSize))
    }

    /// Применяет фон, подготовленный для двух кнопок в одной строке.
    func compactGameFieldButtonStyle(
        for gameField: String?,
        fontSize: CGFloat = 20
    ) -> some View {
        modifier(CompactGameFieldButtonStyle(gameField: gameField, fontSize: fontSize))
    }
}
