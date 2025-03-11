import SwiftUICore
import SwiftUI
struct ColorButton: View {
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(colorFromString(color))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Text("+")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func colorFromString(_ color: String) -> Color {
        switch color {
        case "Красный": return .red
        case "Желтый": return .yellow
        case "Зеленый": return .green
        case "Синий": return .blue
        case "Черный": return .black
        default: return .gray
        }
    }
}
