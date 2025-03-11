import SwiftUI
import SwiftData

@main
struct MarsConquestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Game.self, Player.self, Score.self]) // Регистрируем модели
    }
}
