//
//  DateFormatters.swift
//  MarsConquest
//
//  Кто:
//  Евгений Зотчик — автор проекта
//  Atlas — AI-ассистент разработки
//
//  Что можно менять руками:
//  - представление дат; оно влияет только на текст на экране, не на дату в базе.
//
import Foundation

enum DateFormatters {

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
}
