//
//  AboutProjectView.swift
//
//  Зачем:
//  Кратко объясняет назначение и историю Mars LogBook и даёт официальные ссылки проекта.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - текст истории и назначение проекта;
//  - ссылки на сайт и социальные страницы проекта.
//

import SwiftUI

struct AboutProjectView: View {
  @Environment(\.locale) private var locale

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Image(systemName: "globe.europe.africa.fill")
            .font(.system(size: 34))
            .foregroundStyle(Color(red: 0.77, green: 0.28, blue: 0.16))

          Text("Mars LogBook")
            .font(AppFont.font(.largeTitle))
            .foregroundStyle(.primary)

          Text(isEnglish
            ? "A personal logbook for Terraforming Mars expeditions."
            : "Личный журнал экспедиций в настольной игре «Покорение Марса».")
            .font(AppFont.font(.body))
            .foregroundStyle(.secondary)
        }

        infoCard(
          title: isEnglish ? "Why this project exists" : "Зачем появился проект",
          text: isEnglish
            ? "Mars LogBook keeps the results, players, and details of each game together, so the story of your expeditions does not end when game night is over. It is a free, local-first companion: your journal stays on your iPhone, works without an account, and can be backed up as a file."
            : "Mars LogBook помогает хранить результаты, составы и подробности партий, чтобы история экспедиций не терялась после игрового вечера. Это бесплатный локальный помощник: журнал остаётся на iPhone, работает без учётной записи и переносится резервным файлом.")

        infoCard(
          title: isEnglish ? "How it began" : "Краткая история",
          text: isEnglish
            ? "The project began with a simple need: to record our own Terraforming Mars games and find the results later. What started as a scorekeeping tool grew into a personal game archive with player profiles, statistics, achievements, and a host mode for managing a game from one iPhone."
            : "Всё началось с простой задачи: записывать результаты своих партий в «Покорение Марса» и возвращаться к ним позже. Помощник для подсчёта постепенно вырос в личный архив с профилями игроков, статистикой, достижениями и режимом ведущего для одного iPhone.")

        VStack(alignment: .leading, spacing: 12) {
          Text(isEnglish ? "Project links" : "Ссылки проекта")
            .font(AppFont.font(.headline))

          projectLink(
            title: isEnglish ? "VK Community" : "ВКонтакте",
            subtitle: isEnglish ? "Mars LogBook" : "Mars LogBook",
            systemImage: "person.2",
            url: URL(string: "https://vk.ru/club239875778")!
          )

          projectLink(
            title: isEnglish ? "Telegram Community" : "Telegram",
            subtitle: "Mars LogBook",
            systemImage: "paperplane",
            url: URL(string: "https://t.me/mars_logbook")!
          )

          projectLink(
            title: isEnglish ? "Project website" : "Сайт проекта",
            subtitle: "leprikon-cmd.github.io/MarsConquest",
            systemImage: "globe",
            url: URL(string: "https://leprikon-cmd.github.io/MarsConquest/")!
          )

          projectLink(
            title: "GitHub",
            subtitle: "github.com/Leprikon-cmd/MarsConquest",
            systemImage: "chevron.left.forwardslash.chevron.right",
            url: URL(string: "https://github.com/Leprikon-cmd/MarsConquest")!
          )

          projectLink(
            title: isEnglish ? "Support" : "Поддержка",
            subtitle: "log.book.mars@gmail.com",
            systemImage: "envelope",
            url: URL(string: "mailto:log.book.mars@gmail.com")!
          )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))

        Text(isEnglish
          ? "Mars LogBook is an unofficial, non-commercial companion app. It is not affiliated with or endorsed by FryxGames. Terraforming Mars is a trademark of FryxGames."
          : "Mars LogBook — неофициальное некоммерческое приложение-помощник. Проект не связан с FryxGames и не поддерживается правообладателем. Terraforming Mars — товарный знак FryxGames.")
          .font(AppFont.font(.footnote))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 4)
      }
      .padding()
    }
    .navigationTitle(isEnglish ? "About the Project" : "О проекте")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func infoCard(title: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(AppFont.font(.headline))
      Text(text)
        .font(AppFont.font(.body))
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
  }

  private func projectLink(
    title: String,
    subtitle: String,
    systemImage: String,
    url: URL
  ) -> some View {
    Link(destination: url) {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(AppFont.font(.body))
          Text(subtitle)
            .font(AppFont.font(.footnote))
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "arrow.up.right")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
