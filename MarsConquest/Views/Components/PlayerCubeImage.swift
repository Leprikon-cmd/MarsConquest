import SwiftUI

/// Физический кубик-маркер игрока в цвете, выбранном для партии.
struct PlayerCubeImage: View {
  let colorName: String

  var body: some View {
    Image(assetName)
      .renderingMode(.original)
      .resizable()
      .interpolation(.high)
      .scaledToFit()
  }

  private var assetName: String {
    switch colorName {
    case "Красный": "cube-red"
    case "Синий": "cube-blue"
    case "Желтый": "cube-yellow"
    case "Черный": "cube-black"
    case "Зеленый": "cube-green"
    default: "cube-red"
    }
  }
}
