//
//  JournalBackupDocument.swift
//
//  Зачем:
//  Передаёт JSON-архив системному окну сохранения файла и принимает его обратно.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - тип файла .json менять только вместе с форматом и инструкцией восстановления.
//

import SwiftUI
import UniformTypeIdentifiers

struct JournalBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw JournalBackupError.invalidArchive
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
