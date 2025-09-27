//
//  DateItem.swift
//  dauphin
//
//  Model for date selection in CourseScheduleByDayView
//

import Foundation

struct DateItem: Identifiable {
    let id = UUID()
    let day: Int
    let weekday: String
    let isSelected: Bool
}