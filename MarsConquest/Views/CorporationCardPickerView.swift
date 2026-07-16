//
//  CorporationCardPickerView.swift
//  MarsConquest
//
//  Вертикальный выбор корпорации по изображению её карты.
//

import SwiftUI
import UIKit

struct CorporationCardPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let corporations: [String]
    @Binding var selection: String

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(corporations, id: \.self) { corporation in
                            Button {
                                selection = corporation
                                dismiss()
                            } label: {
                                CorporationCardImage(corporationName: corporation)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                corporation == selection ? Color.accentColor : .clear,
                                                lineWidth: 4
                                            )
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if corporation == selection {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white, Color.accentColor)
                                                .padding(10)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .id(corporation)
                            .accessibilityLabel(corporation)
                            .accessibilityHint("Выбрать корпорацию")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    guard !selection.isEmpty else { return }
                    DispatchQueue.main.async {
                        scrollProxy.scrollTo(selection, anchor: .center)
                    }
                }
            }
            .navigationTitle("Корпорации")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CorporationCardImage: View {
    let corporationName: String

    var body: some View {
        Group {
            if let image = CorporationCardImageCache.image(for: corporationName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                    Text(corporationName)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(456.0 / 317.0, contentMode: .fit)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

private enum CorporationCardImageCache {
    private static var images: [String: UIImage] = [:]

    static func image(for corporationName: String) -> UIImage? {
        let fileName = fileName(for: corporationName)

        if let cachedImage = images[fileName] {
            return cachedImage
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        images[fileName] = image
        return image
    }

    private static func fileName(for corporationName: String) -> String {
        corporationName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
