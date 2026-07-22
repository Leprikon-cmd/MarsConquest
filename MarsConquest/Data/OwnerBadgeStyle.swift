import Foundation

enum OwnerBadgeStyle: String, CaseIterable, Identifiable {
  static let storageKey = "ownerBadgeStyle"

  case marsFrontier
  case lunarPacific
  case europeanScience
  case cosmonautTraining
  case orbitalResearch

  var id: String { rawValue }

  var title: String {
    switch self {
    case .marsFrontier: return "Mars Frontier"
    case .lunarPacific: return "Lunar Pacific"
    case .europeanScience: return "European Science"
    case .cosmonautTraining: return "Cosmonaut Training"
    case .orbitalResearch: return "Orbital Research"
    }
  }

  func assetName(isLightMode: Bool) -> String {
    let baseName: String
    switch self {
    case .marsFrontier: baseName = "id-badge-mars-frontier"
    case .lunarPacific: baseName = "id-badge-lunar-pacific"
    case .europeanScience: baseName = "id-badge-european-science"
    case .cosmonautTraining: baseName = "id-badge-cosmonaut-training"
    case .orbitalResearch: baseName = "id-badge-orbital-research"
    }

    return isLightMode ? "\(baseName)-light-v2" : baseName
  }
}
