import SwiftUI
import UIKit

struct OwnerAvatarPickerView: View {
  @Binding var selection: String
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale
  @AppStorage(OwnerSelfieStore.revisionKey) private var selfieRevision = 0
  @State private var showCamera = false
  @State private var showCameraUnavailableAlert = false

  private let columns = [
    GridItem(.adaptive(minimum: 96), spacing: 16)
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 20) {
          ForEach(OwnerAvatarStyle.builtInCases) { style in
            Button {
              selection = style.rawValue
              dismiss()
            } label: {
              VStack(spacing: 8) {
                Image(style.assetName)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 92, height: 92)
                  .clipShape(Circle())
                  .overlay {
                    Circle()
                      .stroke(selection == style.rawValue ? Color.orange : Color.secondary.opacity(0.35), lineWidth: 3)
                  }

                Text(style.title)
                  .font(.caption.weight(.semibold))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(.primary)
              }
            }
            .buttonStyle(.plain)
          }

          if let selfie = OwnerSelfieStore.load() {
            Button {
              selection = OwnerAvatarStyle.selfie.rawValue
              dismiss()
            } label: {
              VStack(spacing: 8) {
                Image(uiImage: selfie)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 92, height: 92)
                  .clipShape(Circle())
                  .overlay {
                    Circle()
                      .stroke(selection == OwnerAvatarStyle.selfie.rawValue ? Color.orange : Color.secondary.opacity(0.35), lineWidth: 3)
                  }
                Text(selfieTitle)
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.primary)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding()

        Button {
          if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
          } else {
            showCameraUnavailableAlert = true
          }
        } label: {
          Label(takeSelfieTitle, systemImage: "camera.fill")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .padding(.horizontal)
      }
      .navigationTitle(avatarTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(closeTitle) { dismiss() }
        }
      }
      .fullScreenCover(isPresented: $showCamera) {
        SelfieCameraPicker { image in
          if OwnerSelfieStore.save(image) {
            selfieRevision += 1
            selection = OwnerAvatarStyle.selfie.rawValue
            dismiss()
          }
        }
        .ignoresSafeArea()
      }
      .alert(cameraUnavailableTitle, isPresented: $showCameraUnavailableAlert) {
        Button("OK", role: .cancel) {}
      }
    }
  }

  private var isEnglish: Bool { locale.identifier.lowercased().hasPrefix("en") }
  private var avatarTitle: String { isEnglish ? "Choose avatar" : "Выбор аватара" }
  private var selfieTitle: String { isEnglish ? "My selfie" : "Моё селфи" }
  private var takeSelfieTitle: String { isEnglish ? "Take a selfie" : "Сделать селфи" }
  private var closeTitle: String { isEnglish ? "Close" : "Закрыть" }
  private var cameraUnavailableTitle: String { isEnglish ? "Camera is unavailable" : "Камера недоступна" }
}

enum OwnerSelfieStore {
  static let revisionKey = "ownerAvatarSelfieRevision"

  private static var fileURL: URL? {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("owner-avatar-selfie.jpg")
  }

  static func load() -> UIImage? {
    guard let fileURL else { return nil }
    return UIImage(contentsOfFile: fileURL.path)
  }

  static func save(_ image: UIImage) -> Bool {
    guard let fileURL, let data = image.jpegData(compressionQuality: 0.9) else { return false }
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: fileURL, options: .atomic)
      return true
    } catch {
      print("Ошибка сохранения селфи: \(error.localizedDescription)")
      return false
    }
  }
}

private struct SelfieCameraPicker: UIViewControllerRepresentable {
  let onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraDevice = .front
    picker.allowsEditing = true
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: SelfieCameraPicker

    init(parent: SelfieCameraPicker) {
      self.parent = parent
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
      if let image {
        parent.onImagePicked(image)
      }
      parent.dismiss()
    }
  }
}
