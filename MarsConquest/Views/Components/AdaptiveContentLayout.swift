import SwiftUI

/// Центрирует рабочее содержимое на iPad и Mac, не меняя компоновку iPhone.
private struct AdaptiveContentWidth: ViewModifier {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  let maximumWidth: CGFloat

  func body(content: Content) -> some View {
    content
      .frame(maxWidth: horizontalSizeClass == .regular ? maximumWidth : .infinity)
      .frame(maxWidth: .infinity)
  }
}

extension View {
  /// Ограничивает ширину рабочего столбца на широких экранах.
  func adaptiveContentWidth(_ maximumWidth: CGFloat = 760) -> some View {
    modifier(AdaptiveContentWidth(maximumWidth: maximumWidth))
  }
}
