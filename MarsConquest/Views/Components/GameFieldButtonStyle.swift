import SwiftUI

/// Оформляет действие фоном выбранного игрового поля.
private struct GameFieldButtonStyle: ViewModifier {
    let gameField: String?

    private var imageName: String {
        switch GameField(rawValue: gameField ?? "") {
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
            .font(.custom("Play", size: 20))
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

extension View {
    /// Применяет единый стиль кнопок, зависящий от игрового поля.
    func gameFieldButtonStyle(for gameField: String?) -> some View {
        modifier(GameFieldButtonStyle(gameField: gameField))
    }
}
