import Foundation

struct CalendarEvent: Identifiable, Hashable {
    let id: UUID = .init()
    let week: String
    let startDate: Date
    let endDate: Date
    let weekday: String
    let event: String
}
