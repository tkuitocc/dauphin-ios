import Foundation
import OSLog

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
  var weekday: Int
  var note: String = ""
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

func countCoursesToday(_ courses: [Course], date: Date) -> Int {
  let sysWeekday = Calendar.current.component(.weekday, from: date)  // 1=Sun...7=Sat
  let schoolWeekday = mapSystemWeekdayToSchool(sysWeekday)
  return courses.filter { $0.weekday == schoolWeekday }.count
}

func getUpcomingCourses(from weeklySchedule: [Course], currentDate: Date) -> [Course] {
    let calendar = Calendar.current

    let todayWeekdayIndex = calendar.component(.weekday, from: currentDate) - 1
    
    let sortedSchedule = weeklySchedule.sorted { firstCourse, secondCourse in
        if firstCourse.weekday != secondCourse.weekday {
            return firstCourse.weekday < secondCourse.weekday
        } else {
            let (firstEndHour, firstEndMinute) = getCourseEndHourMinute(firstCourse)
            let (secondEndHour, secondEndMinute) = getCourseEndHourMinute(secondCourse)

            let firstCourseEndDate = calendar.date(
                bySettingHour: firstEndHour,
                minute: firstEndMinute,
                second: 0,
                of: currentDate
            )!
            let secondCourseEndDate = calendar.date(
                bySettingHour: secondEndHour,
                minute: secondEndMinute,
                second: 0,
                of: currentDate
            )!

            return firstCourseEndDate < secondCourseEndDate
        }
    }

    if todayWeekdayIndex == 7 {
        return sortedSchedule
    }

    let upcomingCourses = sortedSchedule.filter { course in
        if course.weekday < todayWeekdayIndex {
            return false
        } else if course.weekday == todayWeekdayIndex {
            let (endHour, endMinute) = getCourseEndHourMinute(course)
            let courseEndDate = calendar.date(
                bySettingHour: endHour,
                minute: endMinute,
                second: 0,
                of: currentDate
            )!
            let timeUntilCourseEnds = courseEndDate.timeIntervalSince(currentDate)
            return timeUntilCourseEnds > 20 * 60
        } else {
            return true
        }
    }

    return upcomingCourses
}

func mapSystemWeekdayToSchool(_ w: Int) -> Int {
  return w == 1 ? 7 : (w - 1)
}