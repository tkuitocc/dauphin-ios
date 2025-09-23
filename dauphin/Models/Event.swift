//
//  Event.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//
import Foundation

struct CalendarEvent: Identifiable {
  var id = UUID()  // SwiftUI requires an 'id'
  let week: String
  let startDate: Date
  let endDate: Date
  let weekday: String
  let event: String
}
