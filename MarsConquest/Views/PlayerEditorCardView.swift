import CoreData
import SwiftUI
import UIKit

/// Визуальная карточка участника. Экран отвечает за данные и сохранение,
/// а этот компонент — только за отображение и действия пользователя.
struct PlayerEditorCardView: View {
  @Binding var name: String
  @Binding var selectedColor: String
  @Binding var corporation: String
  @Binding var avatarStyleRawValue: String
  @Binding var avatarImageData: Data?

  let selectedPrologues: [String]
  let availableSavedPlayers: [SavedPlayer]
  let hasSavedPlayers: Bool
  let hasSelectedSavedPlayer: Bool
  let isEditing: Bool
  let hasPrelude: Bool
  let isInputValid: Bool
  let gameField: String
  let locale: Locale
  let nameFocus: FocusState<Bool>.Binding

  let onSelectNewPlayer: () -> Void
  let onSelectSavedPlayer: (SavedPlayer) -> Void
  let onChooseAvatar: () -> Void
  let onChooseColor: () -> Void
  let onChooseCorporation: () -> Void
  let onChoosePreludes: () -> Void
  let onSave: () -> Void

  var body: some View {
    VStack(spacing: 13) {
      header
      Divider().overlay(.white.opacity(0.18))
      corporationCard

      if hasPrelude {
        preludeCards
      }

      saveButton
    }
    .padding(12)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
  }

  private var header: some View {
    ZStack(alignment: .topTrailing) {
      HStack(spacing: 16) {
        avatarButton
        playerSummary
        Spacer(minLength: 48)
      }

      colorButton
        .padding(.top, 4)
        .padding(.trailing, 4)
    }
  }

  private var avatarButton: some View {
    Button(action: onChooseAvatar) {
      avatarImage
        .frame(width: 88, height: 88)
        .clipShape(Circle())
        .overlay {
          Circle()
            .strokeBorder(.white.opacity(0.62), lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "camera.fill")
            .font(AppFont.fixed(12))
            .foregroundStyle(.black)
            .padding(7)
            .background(.white.opacity(0.9), in: Circle())
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Выбрать аватар игрока")
  }

  private var playerSummary: some View {
    VStack(alignment: .leading, spacing: 6) {
      TextField("Имя игрока", text: $name)
        .font(AppFont.fixed(25))
        .textInputAutocapitalization(.words)
        .focused(nameFocus)
        .disabled(hasSelectedSavedPlayer)
        .lineLimit(1)
        .padding(.trailing, 44)
        .accessibilityIdentifier("player-name-field")

      if !isEditing && hasSavedPlayers {
        savedPlayerMenu
      }

      Text(corporation.isEmpty ? "Корпорация не выбрана" : "Корпорация: \(corporation)")
        .font(AppFont.font(.caption))
        .foregroundStyle(.secondary)
        .lineLimit(1)

      if hasPrelude {
        Text(
          selectedPrologues.isEmpty
            ? "Прологи не выбраны"
            : "Прологи: \(selectedPrologues.joined(separator: ", "))"
        )
        .font(AppFont.font(.caption))
        .foregroundStyle(.secondary)
        .lineLimit(2)
      }
    }
  }

  private var savedPlayerMenu: some View {
    Menu {
      Button("Новый игрок", action: onSelectNewPlayer)

      ForEach(availableSavedPlayers, id: \.objectID) { savedPlayer in
        Button(savedPlayer.name ?? UIStrings.noName(locale: locale)) {
          onSelectSavedPlayer(savedPlayer)
        }
      }
    } label: {
      Label(
        hasSelectedSavedPlayer ? "Сохранённый CEO" : "Выбрать сохранённого CEO",
        systemImage: "person.crop.circle.badge.checkmark"
      )
      .font(AppFont.font(.caption))
      .foregroundStyle(.secondary)
    }
  }

  private var colorButton: some View {
    Button(action: onChooseColor) {
      Group {
        if selectedColor.isEmpty {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.1))
            .overlay {
              Image(systemName: "square.dashed")
                .foregroundStyle(.secondary)
            }
        } else {
          PlayerCubeImage(colorName: selectedColor)
        }
      }
      .frame(width: 46, height: 46)
      .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Выбрать цвет игрока")
  }

  private var corporationCard: some View {
    Button(action: onChooseCorporation) {
      Group {
        if corporation.isEmpty {
          cardPlaceholder(
            systemName: "building.2.crop.circle",
            title: "Нажмите, чтобы выбрать корпорацию"
          )
        } else {
          CorporationCardImage(corporationName: corporation)
        }
      }
      .padding(.horizontal, 6)
      .frame(maxWidth: .infinity)
      .frame(height: 212)
      .clipped()
    }
    .buttonStyle(.plain)
    .accessibilityHint("Открывает выбор корпорации")
  }

  private var preludeCards: some View {
    Button(action: onChoosePreludes) {
      HStack(spacing: 4) {
        ForEach(0..<2, id: \.self) { index in
          Group {
            if selectedPrologues.indices.contains(index) {
              PreludeCardImage(prologueName: selectedPrologues[index])
            } else {
              cardPlaceholder(
                systemName: "sparkles.rectangle.stack",
                title: "Выбрать пролог \(index + 1)"
              )
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 112)
          .clipped()
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityHint("Открывает выбор двух прологов")
  }

  private var saveButton: some View {
    Button(action: onSave) {
      Text(isEditing ? "Сохранить игрока" : "Добавить игрока")
        .font(AppFont.font(.headline))
        .frame(maxWidth: .infinity, minHeight: 54)
        .gameFieldButtonStyle(for: gameField)
    }
    .buttonStyle(.plain)
    .disabled(!isInputValid)
    .opacity(isInputValid ? 1 : 0.48)
  }

  @ViewBuilder
  private var avatarImage: some View {
    if avatarStyle == .selfie,
      let avatarImageData,
      let image = UIImage(data: avatarImageData)
    {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
    } else {
      Image(avatarStyle.assetName)
        .resizable()
        .scaledToFill()
    }
  }

  private var avatarStyle: OwnerAvatarStyle {
    OwnerAvatarStyle(rawValue: avatarStyleRawValue) ?? .commander
  }

  private func cardPlaceholder(systemName: String, title: String) -> some View {
    VStack(spacing: 7) {
      Image(systemName: systemName)
        .font(AppFont.fixed(24))
      Text(title)
        .font(AppFont.font(.caption))
        .multilineTextAlignment(.center)
    }
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
    }
  }
}
