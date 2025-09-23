//
//  Course.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import Foundation

struct Course: Identifiable, Hashable, Codable {
  var id = UUID()
  var name: String
  var room: String
  var teacher: String
  var time: String
  var startTime: Date
  var endTime: Date
  var stdNo: String
  var weekday: Int
  var note: String = ""
}

func getNextUpCourses(from weeklySchedule: [Course]) -> [Course] {
  let calendar = Calendar.current
  let now = Date()

  let todayWeekday = calendar.component(.weekday, from: now) - 1
  // log
  print(todayWeekday)
  let sortedCourses = weeklySchedule.sorted { course1, course2 in
    if course1.weekday != course2.weekday {
      return course1.weekday < course2.weekday
    } else {
      let (endHour1, endMinute1) = getCourseEndHourMinute(course1)
      let (endHour2, endMinute2) = getCourseEndHourMinute(course2)

      let endDate1 = calendar.date(bySettingHour: endHour1, minute: endMinute1, second: 0, of: now)!
      let endDate2 = calendar.date(bySettingHour: endHour2, minute: endMinute2, second: 0, of: now)!

      return endDate1 < endDate2
    }
  }

  if todayWeekday == 7 {
    return sortedCourses
  }

  let upcomingCourses = sortedCourses.filter { course in
    if course.weekday < todayWeekday {
      return false
    } else if course.weekday == todayWeekday {
      let (endHour, endMinute) = getCourseEndHourMinute(course)
      let courseEndDate = calendar.date(
        bySettingHour: endHour, minute: endMinute, second: 0, of: now)!
      let timeDifference = courseEndDate.timeIntervalSince(now)
      return timeDifference > 20 * 60
    } else {
      return true
    }
  }
  return upcomingCourses
}

func getCourseStartHourMinute(_ course: Course) -> (hour: Int, minute: Int) {
  let calendar = Calendar.current
  let startHour = calendar.component(.hour, from: course.startTime)
  let startMinute = calendar.component(.minute, from: course.startTime)
  return (startHour, startMinute)
}

func getCourseEndHourMinute(_ course: Course) -> (hour: Int, minute: Int) {
  let calendar = Calendar.current
  let endHour = calendar.component(.hour, from: course.endTime)
  let endMinute = calendar.component(.minute, from: course.endTime)
  return (endHour, endMinute)
}

func stringToTime(_ timeString: String) -> Date? {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"
  formatter.timeZone = TimeZone.current

  return formatter.date(from: timeString)
}

func formatTime(_ date: Date?) -> String {
  guard let date = date else {
    return "ERROR"
  }
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"
  return formatter.string(from: date)
}
