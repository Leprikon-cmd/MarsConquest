//
//  MoxieSoundManager.swift
//  MarsConquest
//
//  Управляет необязательной фоновой дорожкой МОКСИ.
//

import AVFoundation
import Foundation

final class MoxieSoundManager {
    static let shared = MoxieSoundManager()

    static let isEnabledKey = "audio.moxie.isEnabled"

    private var player: AVAudioPlayer?

    private init() { }

    /// Включает или выключает звук и сразу применяет выбор пользователя.
    func setEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: Self.isEnabledKey)

        if isEnabled {
            startIfEnabled()
        } else {
            stop()
        }
    }

    /// Запускает дорожку, только если она разрешена в настройках.
    func startIfEnabled() {
        guard UserDefaults.standard.bool(forKey: Self.isEnabledKey) else { return }

        do {
            try configureAudioSession()

            if player == nil {
                guard let url = Bundle.main.url(forResource: "moxie", withExtension: "wav") else {
                    print("Не найден аудиофайл moxie.wav")
                    return
                }

                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.45
                player?.prepareToPlay()
            }

            guard player?.isPlaying == false else { return }
            player?.play()
        } catch {
            print("Не удалось запустить звук МОКСИ: \(error.localizedDescription)")
        }
    }

    /// Останавливает дорожку при выключении настройки или уходе приложения в фон.
    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        // Режим ambient не игнорирует беззвучный переключатель iPhone
        // и позволяет другой музыке продолжать играть.
        try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
}
