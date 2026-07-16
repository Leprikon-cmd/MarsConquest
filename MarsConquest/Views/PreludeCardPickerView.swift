//
//  PreludeCardPickerView.swift
//  MarsConquest
//
//  Вертикальный выбор пролога по изображению его карты.
//

import SwiftUI
import UIKit

struct PreludeCardPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let prologues: [String]
    @Binding var selection: String

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(prologues, id: \.self) { prologue in
                            Button {
                                selection = prologue
                                dismiss()
                            } label: {
                                PreludeCardImage(prologueName: prologue)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                prologue == selection ? Color.accentColor : .clear,
                                                lineWidth: 4
                                            )
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if prologue == selection {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white, Color.accentColor)
                                                .padding(10)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .id(prologue)
                            .accessibilityLabel(prologue)
                            .accessibilityHint("Выбрать пролог")
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
            .navigationTitle("Прологи")
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

private struct PreludeCardImage: View {
    let prologueName: String

    var body: some View {
        Group {
            if let image = PreludeCardImageCache.image(for: prologueName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                    Text(prologueName)
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

private enum PreludeCardImageCache {
    private static var images: [String: UIImage] = [:]

    static func image(for prologueName: String) -> UIImage? {
        let fileName = fileName(for: prologueName)

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

    private static func fileName(for prologueName: String) -> String {
        prologueName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
