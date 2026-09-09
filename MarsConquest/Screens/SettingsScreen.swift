//
//  SettingsScreen.swift
//
//  Зачем:
//  Экран глобальных настроек приложения.
//  Здесь задаются дополнения, включённые по умолчанию для новых партий.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - порядок разделов, подписи и иконки; ключи настроек и правила архива находятся в менеджерах;
//  - текст предложения связать чужую историю с владельцем — без автоматической привязки по имени.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
  /// Вызывается, когда настройки открыты во время создания конкретной партии.
  var onExpansionsChanged: ((GameExpansions) -> Void)?

  /// Профиль нужен только в настройках из бортового журнала — для проверки старых партий.
  var ownerProfile: OwnerProfile?

  @State private var expansions = ExpansionSettingsManager.load()
  @AppStorage(MoxieSoundManager.isEnabledKey) private var isMoxieSoundEnabled = false
  @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.automatic.rawValue
  @AppStorage(OwnerAvatarStyle.storageKey) private var ownerAvatarStyleRawValue = OwnerAvatarStyle.commander.rawValue
  @AppStorage(TestModeSettings.isEnabledKey) private var isTestModeEnabled = false
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.locale) private var locale
  @FetchRequest(
    entity: Game.entity(),
    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
  ) private var games: FetchedResults<Game>
  @State private var importMessage = ""
  @State private var showImportAlert = false
  @State private var backupDocument: JournalBackupDocument?
  @State private var showBackupExporter = false
  @State private var showBackupImporter = false
  @State private var pendingBackup: JournalBackup?
  @State private var showRestoreConfirmation = false
  @State private var archiveMessage = ""
  @State private var showArchiveAlert = false
  @State private var importedParticipantChoices: [ImportedParticipantChoice] = []
  @State private var showImportedParticipationPicker = false

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Язык")) {
          Picker("Язык интерфейса", selection: $appLanguageRawValue) {
            ForEach(AppLanguage.allCases) { language in
              Text(language.title)
                .tag(language.rawValue)
            }
          }
        }

        Section(header: Text(avatarStyleSectionTitle)) {
          Picker(avatarStylePickerTitle, selection: $ownerAvatarStyleRawValue) {
            ForEach(OwnerAvatarStyle.builtInCases) { style in
              Text(style.title)
                .tag(style.rawValue)
            }
          }
        }

        Section(header: Text("Дополнения по умолчанию")) {
          Toggle("Прологи", isOn: binding(for: \.hasPrelude))
          Toggle("Венера", isOn: binding(for: \.hasVenus))
          Toggle("Колонии", isOn: binding(for: \.hasColonies))
          Toggle("Эллада и Элизий", isOn: binding(for: \.hasHellasElysium))
          Toggle("Кризис", isOn: binding(for: \.hasTurmoil))
        }

        Section(header: Text(testModeSectionTitle)) {
          Toggle(testModeToggleTitle, isOn: $isTestModeEnabled)
          Text(testModeDescription)
            .font(AppFont.font(.footnote))
            .foregroundStyle(.secondary)
        }

        Section(header: Text("Звук")) {
          Toggle("Звук МОКСИ", isOn: $isMoxieSoundEnabled)
            .onChange(of: isMoxieSoundEnabled) { _, isEnabled in
              MoxieSoundManager.shared.setEnabled(isEnabled)
            }
        }

        Section(header: Text("Импорт")) {
          Button("Импортировать игры из JSON") {
            do {
              let count = try GameImportManager.importFromBundle(
                filename: "mars_import", in: viewContext)
              importMessage = "\(String(localized: "Импортировано игр:", locale: locale)) \(count)"
              showImportAlert = true
            } catch {
              importMessage = "\(String(localized: "Ошибка импорта:", locale: locale)) \(error.localizedDescription)"
              showImportAlert = true
            }
          }
        }

        Section(header: Text(archiveSectionTitle)) {
          Button {
            prepareBackup()
          } label: {
            Label(createBackupTitle, systemImage: "archivebox")
          }

          Button {
            showBackupImporter = true
          } label: {
            Label(restoreBackupTitle, systemImage: "tray.and.arrow.down")
          }

          Text(archiveDescription)
            .font(AppFont.font(.footnote))
            .foregroundStyle(.secondary)
        }

        if hasHistoricalParticipationsToReview, let ownerProfile {
          Section(header: Text("Бортовой журнал")) {
            NavigationLink {
              HistoricalParticipationLinkView(ownerProfile: ownerProfile)
            } label: {
              Label("Проверить прошлые партии", systemImage: "person.text.rectangle")
            }
          }
        }
      }
      .navigationTitle("Настройки")
      // Form не знает о нижней навигации родительского журнала.
      .safeAreaPadding(.bottom, JournalNavigationLayout.contentBottomClearance)
      .alert("Импорт JSON", isPresented: $showImportAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(importMessage)
      }
      .alert(archiveAlertTitle, isPresented: $showArchiveAlert) {
        Button(archiveCloseTitle, role: .cancel) {
          if !importedParticipantChoices.isEmpty {
            showImportedParticipationPicker = true
          }
        }
      } message: {
        Text(archiveMessage)
      }
      .alert(restoreConfirmationTitle, isPresented: $showRestoreConfirmation) {
        Button(restoreCancelTitle, role: .cancel) {
          pendingBackup = nil
        }
        Button(restoreAcceptTitle) {
          acceptPendingBackup()
        }
      } message: {
        Text(restoreConfirmationMessage)
      }
      .fileExporter(
        isPresented: $showBackupExporter,
        document: backupDocument,
        contentType: .json,
        defaultFilename: backupFileName
      ) { result in
        switch result {
        case .success:
          archiveMessage = backupCreatedMessage
        case .failure:
          archiveMessage = archiveUnavailableMessage
        }
        showArchiveAlert = true
        backupDocument = nil
      }
      .fileImporter(
        isPresented: $showBackupImporter,
        allowedContentTypes: [.json]
      ) { result in
        switch result {
        case .success(let url):
          prepareRestoration(from: url)
        case .failure:
          archiveMessage = archiveUnavailableMessage
          showArchiveAlert = true
        }
      }
      .sheet(isPresented: $showImportedParticipationPicker) {
        importedParticipationPicker
      }
    }
  }

  private func binding(for keyPath: WritableKeyPath<GameExpansions, Bool>) -> Binding<Bool> {
    Binding(
      get: { expansions[keyPath: keyPath] },
      set: { newValue in
        expansions[keyPath: keyPath] = newValue
        ExpansionSettingsManager.save(expansions)
        onExpansionsChanged?(expansions)
      }
    )
  }

  private var hasHistoricalParticipationsToReview: Bool {
    guard let ownerID = ownerProfile?.savedPlayerID else { return false }

    return games.contains { game in
      let players = game.players?.allObjects as? [Player] ?? []
      return players.contains {
        ($0.savedPlayerID == nil || $0.savedPlayerID == ownerID) && $0.id != ownerID
      }
    }
  }

  private var isEnglish: Bool {
    locale.identifier.lowercased().hasPrefix("en")
  }

  private func prepareBackup() {
    do {
      let backup = try JournalBackupManager.makeBackup(in: viewContext)
      let data = try JournalBackupManager.encodedData(for: backup)
      backupDocument = JournalBackupDocument(data: data)
      showBackupExporter = true
    } catch {
      archiveMessage = archivePreparationFailedMessage
      showArchiveAlert = true
    }
  }

  private func prepareRestoration(from url: URL) {
    let accessGranted = url.startAccessingSecurityScopedResource()
    defer {
      if accessGranted {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let data = try Data(contentsOf: url)
      pendingBackup = try JournalBackupManager.decode(data)
      showRestoreConfirmation = true
    } catch {
      archiveMessage = archiveRejectedMessage
      showArchiveAlert = true
    }
  }

  private func acceptPendingBackup() {
    guard let pendingBackup else { return }
    importedParticipantChoices = []

    do {
      let report = try JournalBackupManager.restore(pendingBackup, in: viewContext)

      if report.profileRestored {
        restoreCollectionDefaults(from: pendingBackup.profile)
        UserDefaults.standard.set(pendingBackup.avatar.style, forKey: OwnerAvatarStyle.storageKey)
        if let selfie = pendingBackup.avatar.selfieJPEGData {
          _ = OwnerSelfieStore.restoreBackupData(selfie)
        }
      } else {
        importedParticipantChoices = importedParticipationChoices(
          from: pendingBackup,
          report: report
        )
      }

      archiveMessage = restorationCompletedMessage(for: report)
    } catch {
      archiveMessage = archiveRejectedMessage
    }

    self.pendingBackup = nil
    showArchiveAlert = true
  }

  private var importedParticipationPicker: some View {
    NavigationStack {
      List(importedParticipantChoices) { participant in
        Button {
          linkImportedParticipation(participant)
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            Text(participant.displayName)
              .font(AppFont.font(.body))
              .foregroundStyle(.primary)
            Text(importedExpeditionCountTitle(participant.expeditionCount))
              .font(AppFont.font(.footnote))
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle(importedParticipationTitle)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(importedParticipationLaterTitle) {
            importedParticipantChoices = []
            showImportedParticipationPicker = false
          }
        }
      }
      .safeAreaInset(edge: .top) {
        Text(importedParticipationDescription)
          .font(AppFont.font(.footnote))
          .foregroundStyle(.secondary)
          .padding(.horizontal)
          .padding(.vertical, 10)
      }
    }
  }

  private func linkImportedParticipation(_ participant: ImportedParticipantChoice) {
    guard let ownerSavedPlayerID else { return }

    do {
      let linkedCount = try JournalBackupManager.linkImportedParticipation(
        sourceSavedPlayerID: participant.sourceSavedPlayerID,
        to: ownerSavedPlayerID,
        in: viewContext
      )
      importedParticipantChoices = []
      showImportedParticipationPicker = false
      archiveMessage = importedParticipationLinkedMessage(linkedCount)
    } catch {
      archiveMessage = importedParticipationLinkFailedMessage
    }

    showArchiveAlert = true
  }

  private var ownerSavedPlayerID: UUID? {
    ownerProfile?.savedPlayerID ?? OwnerProfileManager.fetch(in: viewContext)?.savedPlayerID
  }

  private func importedParticipationChoices(
    from backup: JournalBackup,
    report: JournalRestoreReport
  ) -> [ImportedParticipantChoice] {
    guard let ownerSavedPlayerID else { return [] }
    let restoredGameIDs = Set(report.restoredGameIDs)
    let profileNames = Dictionary(uniqueKeysWithValues: backup.savedPlayers.map {
      ($0.id, $0.nickname ?? $0.name ?? "Участник")
    })
    let participations = backup.games
      .filter { restoredGameIDs.contains($0.id) }
      .flatMap { game in
        game.players.compactMap { player -> (UUID, String, UUID)? in
          guard let sourceID = player.savedPlayerID, sourceID != ownerSavedPlayerID else { return nil }
          return (sourceID, profileNames[sourceID] ?? player.name ?? "Участник", game.id)
        }
      }
    let groups = Dictionary(grouping: participations, by: { $0.0 })

    return groups.compactMap { sourceID, participations in
      let name = participations.first?.1 ?? "Участник"
      let expeditions = Set(participations.map(\.2)).count
      return ImportedParticipantChoice(
        sourceSavedPlayerID: sourceID,
        displayName: name,
        expeditionCount: expeditions
      )
    }
    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
  }

  private func restoreCollectionDefaults(from profile: JournalBackupOwnerProfile?) {
    guard let profile else { return }
    expansions = GameExpansions(
      hasPrelude: profile.hasPrelude,
      hasVenus: profile.hasVenus,
      hasColonies: profile.hasColonies,
      hasHellasElysium: profile.hasHellasElysium,
      hasTurmoil: profile.hasTurmoil
    )
    ExpansionSettingsManager.save(expansions)
  }

  private var restoreConfirmationMessage: String {
    guard let pendingBackup else { return "" }
    let games = pendingBackup.games.count
    let players = pendingBackup.savedPlayers.count
    if isEnglish {
      return "The archive contains \(games) expeditions and \(players) saved player profiles. Existing journal entries will remain unchanged."
    }
    return "Архив содержит экспедиций: \(games). Сохранённых профилей: \(players). Уже имеющиеся записи журнала останутся без изменений."
  }

  private var backupFileName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return "MarsLogBook-\(formatter.string(from: Date()))"
  }

  private func restorationCompletedMessage(for report: JournalRestoreReport) -> String {
    if report.changedJournal {
      if isEnglish {
        return "The archive has been accepted. Added expeditions: \(report.gamesRestored). Existing entries left unchanged: \(report.gamesAlreadyPresent)."
      }
      return "Архив принят. Внесено экспедиций: \(report.gamesRestored). Существующие записи без изменений: \(report.gamesAlreadyPresent)."
    }
    return isEnglish
      ? "The archive has already been reflected in this journal."
      : "Сведения этого архива уже отражены в журнале."
  }

  private var archiveSectionTitle: String { isEnglish ? "Journal archive" : "Архив журнала" }
  private var importedParticipationTitle: String { isEnglish ? "Identify yourself" : "Указать себя" }
  private var importedParticipationLaterTitle: String { isEnglish ? "Not now" : "Не сейчас" }
  private var importedParticipationDescription: String {
    isEnglish
      ? "The archive has been accepted. If you are among these participants, identify yourself explicitly. The app never links people by name."
      : "Архив принят. Если среди этих участников есть вы, укажите себя явно. По имени приложение никого не связывает."
  }
  private var importedParticipationLinkFailedMessage: String {
    isEnglish
      ? "The personal link could not be updated. The journal remains unchanged."
      : "Не удалось обновить личную привязку. Журнал остался без изменений."
  }
  private var createBackupTitle: String { isEnglish ? "Create backup" : "Создать резервную копию" }
  private var restoreBackupTitle: String { isEnglish ? "Restore journal archive" : "Восстановить архив журнала" }
  private var archiveDescription: String {
    isEnglish
      ? "The archive contains journal history, saved profiles, collection, and personal avatar. Device preferences remain on this iPhone."
      : "Копия содержит историю журнала, сохранённые профили, коллекцию и личный аватар. Настройки этого iPhone останутся на устройстве."
  }
  private var archiveAlertTitle: String { isEnglish ? "Journal archive" : "Архив журнала" }
  private var archiveCloseTitle: String { isEnglish ? "Close" : "Закрыть" }
  private var backupCreatedMessage: String {
    isEnglish ? "The journal archive is ready." : "Архив журнала подготовлен."
  }
  private var archiveUnavailableMessage: String {
    isEnglish ? "The archive could not be prepared. The journal remains unchanged." : "Архив не удалось подготовить. Журнал остался без изменений."
  }
  private var archivePreparationFailedMessage: String {
    isEnglish ? "The archive cannot be prepared until every journal entry has a permanent identifier." : "Архив нельзя подготовить, пока у каждой записи журнала нет постоянного идентификатора."
  }
  private var archiveRejectedMessage: String {
    isEnglish ? "The archive was not accepted. The journal remains unchanged." : "Архив не принят. Журнал остался без изменений."
  }
  private var restoreConfirmationTitle: String { isEnglish ? "Accept archive" : "Принять архив" }
  private var restoreCancelTitle: String { isEnglish ? "Cancel" : "Отмена" }
  private var restoreAcceptTitle: String { isEnglish ? "Accept archive" : "Принять архив" }

  private func importedExpeditionCountTitle(_ count: Int) -> String {
    if isEnglish {
      return count == 1 ? "One imported expedition" : "Imported expeditions: \(count)"
    }
    return count == 1 ? "Одна внесённая экспедиция" : "Внесено экспедиций: \(count)"
  }

  private func importedParticipationLinkedMessage(_ count: Int) -> String {
    if isEnglish {
      return count == 1
        ? "One entry is now part of your personal journal."
        : "Entries added to your personal journal: \(count)."
    }
    return count == 1
      ? "Одна запись включена в личный журнал."
      : "Записей включено в личный журнал: \(count)."
  }

  private var avatarStyleSectionTitle: String {
    isEnglish ? "Personal avatar" : "Аватар пользователя"
  }

  private var avatarStylePickerTitle: String {
    isEnglish ? "Avatar" : "Аватар"
  }

  private var testModeSectionTitle: String {
    isEnglish ? "Testing" : "Тестирование"
  }

  private var testModeToggleTitle: String {
    isEnglish ? "Test mode" : "Тестовый режим"
  }

  private var testModeDescription: String {
    isEnglish
      ? "Automatically fills a color, corporation, and two preludes when adding players."
      : "Автоматически подставляет цвет, корпорацию и два пролога при добавлении игроков."
  }
}

/// Один стабильный профиль участника из только что внесённых партий чужого архива.
private struct ImportedParticipantChoice: Identifiable {
  let sourceSavedPlayerID: UUID
  let displayName: String
  let expeditionCount: Int

  var id: UUID { sourceSavedPlayerID }
}
