//
//  OwnerProfileGateView.swift
//
//  Зачем:
//  Решает, показать регистрацию владельца или его уже готовый журнал.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - нет: это навигационная развилка, не визуальный экран.
//
import CoreData
import SwiftUI

/// Решает, открыть регистрацию владельца или уже существующий главный экран.
struct OwnerProfileGateView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @State private var didLoadOwner = false
  @State private var ownerProfile: OwnerProfile?

  var body: some View {
    Group {
      if didLoadOwner {
        if let ownerProfile {
          ContentView(ownerProfile: ownerProfile)
        } else {
          OwnerProfileSetupView {
            ownerProfile = OwnerProfileManager.fetch(in: viewContext)
          }
        }
      } else {
        ZStack {
          Image("fon")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()

          ProgressView()
            .tint(.white)
        }
      }
    }
    .onAppear(perform: loadOwner)
  }

  private func loadOwner() {
    ownerProfile = OwnerProfileManager.fetch(in: viewContext)
    didLoadOwner = true
  }
}
