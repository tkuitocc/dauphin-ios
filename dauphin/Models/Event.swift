import Foundation

struct CalendarEvent: Identifiable {
  var id = UUID()
  let week: String
  let startDate: Date
  let endDate: Date
  let weekday: String
  let event: String
}
