import Foundation

enum OwnerAvatarStyle: String, CaseIterable, Identifiable {
  static let storageKey = "ownerAvatarStyle"

  case commander
  case pilot
  case facetedArmor
  case panoramicWrap
  case roundDome
  case selfie

  static let builtInCases: [OwnerAvatarStyle] = [
    .commander, .pilot, .facetedArmor, .panoramicWrap, .roundDome
  ]

  var id: String { rawValue }

  var title: String {
    switch self {
    case .commander: return "Commander"
    case .pilot: return "Pilot"
    case .facetedArmor: return "Faceted Armor"
    case .panoramicWrap: return "Panoramic Wrap"
    case .roundDome: return "Round Dome"
    case .selfie: return "Selfie"
    }
  }

  var assetName: String {
    switch self {
    case .commander: return "avatar-commander"
    case .pilot: return "avatar-pilot"
    case .facetedArmor: return "avatar-helmet-faceted-armor"
    case .panoramicWrap: return "avatar-helmet-panoramic-wrap"
    case .roundDome: return "avatar-helmet-round-dome"
    case .selfie: return "avatar-commander"
    }
  }
}
