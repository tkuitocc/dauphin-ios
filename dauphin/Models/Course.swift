import Foundation
import OSLog
import SwiftUI

enum CourseLogger {
  static let logger = Logger(
    subsystem: "group.cantpr09ram.dauphin", category: "Course"
  )
}

struct Course: Identifiable, Hashable, Codable {
  var id = UUID()
  var name: String
  var room: String
  var teacher: String
  var time: String
  var startTime: Date
  var endTime: Date
  var stdNo: String
  var weekday: Int     // 約定：1...7 = 週一...週日
  var note: String = ""
}

// 共用 HH:mm formatter，避免多次建立
private let hhmmFormatter: DateFormatter = {
  let f = DateFormatter()
  f.dateFormat = "HH:mm"
  f.timeZone = .current
  return f
}()

func stringToTime(_ timeString: String) -> Date? {
  hhmmFormatter.date(from: timeString)
}

func formatTime(_ date: Date?) -> String {
  guard let date else { return "ERROR" }
  return hhmmFormatter.string(from: date)
}

// 將節次映射成時間（維持你原本僅有時分的邏輯）
public func sessionToStartTime(session: Int) -> Date? {
  let startHour = [
    1: 8, 2: 9, 3: 10, 4: 11, 5: 12, 6: 13, 7: 14, 8: 15,
    9: 16, 10: 17, 11: 18, 12: 19, 13: 20, 14: 21
  ][session]
  guard let hour = startHour else { return nil }
  var comps = DateComponents()
  comps.hour = hour
  comps.minute = 10
  return Calendar.current.date(from: comps)
}

public func sessionToEndTime(session: Int) -> Date? {
  let endHour = [
    1: 9, 2: 10, 3: 11, 4: 12, 5: 13, 6: 14, 7: 15, 8: 16,
    9: 17, 10: 18, 11: 19, 12: 20, 13: 21, 14: 22
  ][session]
  guard let hour = endHour else { return nil }
  var comps = DateComponents()
  comps.hour = hour
  comps.minute = 0
  return Calendar.current.date(from: comps)
}

// 對外函式名稱與簽名不變；內部使用改良邏輯
func getNextUpCourses(from weeklySchedule: [Course]) -> [Course] {
  DefaultNextUpService().nextUp(from: weeklySchedule, now: Date())
}
