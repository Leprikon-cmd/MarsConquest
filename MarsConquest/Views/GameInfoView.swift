//
//  GameInfoView.swift
//
//  Зачем:
//  Оформляет реквизиты архивной записи на экране завершения экспедиции.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Назначение файла:
//  - шапка архивного журнала
//  - реквизиты завершённой экспедиции
//
//  Что можно менять руками:
//  - тексты реквизитов, типографику, прозрачность и интервалы архивной страницы.
//
import SwiftUI

struct GameInfoView: View {
    @Environment(\.locale) private var locale

    /// Дата текущей партии.
    let date: Date
    
    /// Название выбранного игрового поля.
    let gameField: String
    
    /// Количество поколений / длительность партии. До уточнения не задано.
    @Binding var generation: Int?

    /// Режим ведущего уже зафиксировал поколение, поэтому ручной пикер не показывается.
    let isGenerationLocked: Bool

    /// Показывать ли шкалу дополнения «Венера».
    let hasVenus: Bool

    /// Уровень шкалы терраформирования Венеры. До уточнения не задан.
    @Binding var venusTerraformingScale: Int?

    private let venusTerraformingValues = Array(stride(from: 0, through: 30, by: 2))
    
    var body: some View {
        let localizedGameField = GameField.localizedName(
            persistedName: gameField,
            referenceID: nil,
            locale: locale
        )

        VStack(spacing: 16) {
            Text("ЖУРНАЛ ЭКСПЕДИЦИИ")
                .font(AppFont.font(.title3))
                .tracking(2.4)
                .frame(maxWidth: .infinity)

            HStack(alignment: .firstTextBaseline) {
                Text(localizedGameField.uppercased(with: locale))
                    .font(AppFont.font(.headline))
                    .tracking(1.2)

                Spacer()

                Text(date, formatter: DateFormatters.shortDate)
                    .font(AppFont.font(.subheadline))
                    .monospacedDigit()
            }

            Divider()

            if isGenerationLocked {
                archiveReadOnlyRow(title: "Поколение", value: generation.map(String.init) ?? "—")
            } else {
                archiveDetailRow(title: "Поколение", selection: $generation, values: Array(5...20)) { value in
                    "\(value)"
                }
            }

            if hasVenus {
                archiveDetailRow(
                    title: "Шкала Венеры",
                    selection: $venusTerraformingScale,
                    values: venusTerraformingValues
                ) { value in
                    "\(value)%"
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func archiveReadOnlyRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.font(.body))
            Spacer()
            Text(value)
                .font(AppFont.font(.body).weight(.bold))
                .foregroundStyle(.red)
        }
    }

    private func archiveDetailRow(
        title: String,
        selection: Binding<Int?>,
        values: [Int],
        label: @escaping (Int) -> String
    ) -> some View {
        HStack {
            Text(title)
                .font(AppFont.font(.body))
            Spacer()

            Menu {
                Button("—") {
                    selection.wrappedValue = nil
                }
                ForEach(values, id: \.self) { value in
                    Button(label(value)) {
                        selection.wrappedValue = value
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selection.wrappedValue.map(label) ?? "—")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(AppFont.fixed(10))
                }
                .font(AppFont.font(.body).weight(.bold))
                .foregroundStyle(.red)
            }
            .accessibilityLabel(title)
            .accessibilityIdentifier(
                title == "Поколение"
                    ? "game-info-generation-menu"
                    : "game-info-venus-menu"
            )
            .frame(maxWidth: 112)
        }
    }
}
