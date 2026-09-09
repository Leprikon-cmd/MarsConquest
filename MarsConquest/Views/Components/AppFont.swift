//
//  AppFont.swift
//
//  Зачем:
//  Задаёт единую типографику приложения и связывает стили SwiftUI с шрифтом Russo One.
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - имя шрифта и таблицу размеров pointSize; новый шрифт нужно добавить в Assets и Info.plist.
//
import SwiftUI
import UIKit

/// Единая типографика приложения на основе Russo One.
enum AppFont {
    static let name = "RussoOne-Regular"

    static func font(_ style: Font.TextStyle) -> Font {
        .custom(name, size: pointSize(for: style), relativeTo: style)
    }

    static func fixed(_ size: CGFloat) -> Font {
        .custom(name, size: size)
    }

    /// Настраивает элементы UIKit, которые не всегда наследуют SwiftUI font environment.
    static func configureSystemControls() {
        let navigationBar = UINavigationBar.appearance()
        navigationBar.titleTextAttributes = [.font: uiFont(size: 20)]
        navigationBar.largeTitleTextAttributes = [.font: uiFont(size: 34)]

        let barButton = UIBarButtonItem.appearance()
        let barButtonAttributes: [NSAttributedString.Key: Any] = [.font: uiFont(size: 17)]
        barButton.setTitleTextAttributes(barButtonAttributes, for: .normal)
        barButton.setTitleTextAttributes(barButtonAttributes, for: .highlighted)

        let tabBarItem = UITabBarItem.appearance()
        let tabAttributes: [NSAttributedString.Key: Any] = [.font: uiFont(size: 11)]
        tabBarItem.setTitleTextAttributes(tabAttributes, for: .normal)
        tabBarItem.setTitleTextAttributes(tabAttributes, for: .selected)

        let segmentedControl = UISegmentedControl.appearance()
        let segmentAttributes: [NSAttributedString.Key: Any] = [.font: uiFont(size: 13)]
        segmentedControl.setTitleTextAttributes(segmentAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(segmentAttributes, for: .selected)
    }

    private static func uiFont(size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    private static func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}
