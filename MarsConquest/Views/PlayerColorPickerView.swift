import SwiftUI

struct PlayerColorPickerView: View {
  let colors: [String]
  @Binding var selection: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      HStack(spacing: 14) {
        ForEach(colors, id: \.self) { color in
          Button {
            selection = color
            dismiss()
          } label: {
            PlayerCubeImage(colorName: color)
              .frame(width: selection == color ? 62 : 48, height: selection == color ? 62 : 48)
              .frame(maxWidth: .infinity, minHeight: 82)
              .background {
                if selection == color {
                  RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.16))
                }
              }
              .overlay {
                if selection == color {
                  RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.orange, lineWidth: 3)
                }
              }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Фишка: \(color)")
        }
      }
      .padding(.horizontal, 18)
      .navigationTitle("Цвет игрока")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Закрыть") { dismiss() }
        }
      }
    }
  }
}
