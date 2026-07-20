//
//  ColonyCardPickerView.swift
//  MarsConquest
//
//  Выбор нескольких колоний для текущей партии.
//

import SwiftUI
import UIKit

struct ColonyCardPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale

  let colonies: [String]
  @Binding var selection: [String]
  let maximumSelection: Int

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(colonies, id: \.self) { colony in
            Button {
              toggle(colony)
            } label: {
              ColonyCardImage(colonyName: colony)
                .overlay {
                  RoundedRectangle(cornerRadius: 18)
                    .stroke(
                      isSelected(colony) ? Color.accentColor : .clear,
                      lineWidth: 4
                    )
                }
                .overlay(alignment: .topTrailing) {
                  if isSelected(colony) {
                    Image(systemName: "checkmark.circle.fill")
                      .font(.title2)
                      .foregroundStyle(.white, Color.accentColor)
                      .padding(10)
                  }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedColonyName(for: colony))
            .accessibilityHint(
              isSelected(colony) ? "Убрать из партии" : "Добавить в партию"
            )
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
      .navigationTitle("Колонии \(selection.count)/\(maximumSelection)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Готово") {
            dismiss()
          }
        }
      }
    }
  }

  private func isSelected(_ colony: String) -> Bool {
    selection.contains(colony)
  }

  private func toggle(_ colony: String) {
    if isSelected(colony) {
      selection.removeAll { $0 == colony }
    } else if selection.count < maximumSelection {
      selection.append(colony)
    }
  }

  private func localizedColonyName(for colony: String) -> String {
    GameData.localizedColonyName(
      persistedName: colony,
      referenceID: GameData.colonyID(named: colony),
      locale: locale
    )
  }
}

private struct ColonyCardImage: View {
  let colonyName: String

  var body: some View {
    Group {
      if let image = ColonyCardImageCache.image(for: colonyName) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        VStack(spacing: 8) {
          Image(systemName: "globe.americas.fill")
            .font(.title2)
          Text(colonyName)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.85, contentMode: .fit)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
      }
    }
    .frame(maxWidth: 360)
    .frame(maxWidth: .infinity)
    .contentShape(RoundedRectangle(cornerRadius: 18))
  }
}

private enum ColonyCardImageCache {
  private static var images: [String: UIImage] = [:]

  static func image(for colonyName: String) -> UIImage? {
    let fileName = colonyName.lowercased()

    if let cachedImage = images[fileName] {
      return cachedImage
    }

    guard let url = Bundle.main.url(forResource: fileName, withExtension: "png"),
      let image = UIImage(contentsOfFile: url.path)
    else {
      return nil
    }

    images[fileName] = image
    return image
  }
}
