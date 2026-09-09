//
//  PlayerAvatarPickerView.swift
//
//  Зачем:
//  Позволяет выбрать аватар участника или сделать снимок для его карточки.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - сетку выбора: minimum 96 и spacing 16; список образов и картинки задаются отдельно.
//
import SwiftUI
import UIKit

struct PlayerAvatarPickerView: View {
  @Binding var selection: String
  @Binding var selfieData: Data?

  @Environment(\.dismiss) private var dismiss
  @State private var showCamera = false
  @State private var cameraDevice: UIImagePickerController.CameraDevice = .front
  @State private var showCameraUnavailableAlert = false

  private let columns = [
    GridItem(.adaptive(minimum: 96), spacing: 16)
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 20) {
          ForEach(OwnerAvatarStyle.builtInCases) { style in
            avatarButton(
              style: style,
              image: Image(style.assetName)
            )
          }

          if let selfieData, let image = UIImage(data: selfieData) {
            avatarButton(
              style: .selfie,
              image: Image(uiImage: image)
            )
          }
        }
        .padding()

        VStack(spacing: 10) {
          Button {
            openCamera(.front)
          } label: {
            Label("Сделать селфи", systemImage: "camera.fill")
              .font(AppFont.font(.headline))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
          .tint(.orange)

          Button {
            openCamera(.rear)
          } label: {
            Label("Сфотографировать игрока", systemImage: "camera.viewfinder")
              .font(AppFont.font(.headline))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
          }
          .buttonStyle(.bordered)
        }
        .padding(.horizontal)
      }
      .navigationTitle("Аватар игрока")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Закрыть") { dismiss() }
        }
      }
      .fullScreenCover(isPresented: $showCamera) {
        SelfieCameraPicker(
          onImagePicked: { image in
          guard let data = image.jpegData(compressionQuality: 0.9) else { return }
          selfieData = data
          selection = OwnerAvatarStyle.selfie.rawValue
          dismiss()
          },
          cameraDevice: cameraDevice
        )
        .ignoresSafeArea()
      }
      .alert("Камера недоступна", isPresented: $showCameraUnavailableAlert) {
        Button("OK", role: .cancel) {}
      }
    }
  }

  private func openCamera(_ device: UIImagePickerController.CameraDevice) {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      showCameraUnavailableAlert = true
      return
    }

    cameraDevice = UIImagePickerController.isCameraDeviceAvailable(device) ? device : .front
    showCamera = true
  }

  private func avatarButton(style: OwnerAvatarStyle, image: Image) -> some View {
    Button {
      selection = style.rawValue
      dismiss()
    } label: {
      VStack(spacing: 8) {
        image
          .resizable()
          .scaledToFill()
          .frame(width: 92, height: 92)
          .clipShape(Circle())
          .overlay {
            Circle()
              .stroke(
                selection == style.rawValue ? Color.orange : Color.secondary.opacity(0.35),
                lineWidth: 3
              )
          }

        Text(style.title)
          .font(AppFont.font(.caption))
          .multilineTextAlignment(.center)
          .foregroundStyle(.primary)
      }
    }
    .buttonStyle(.plain)
  }
}
