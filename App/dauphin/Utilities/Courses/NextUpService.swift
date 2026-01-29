import Foundation

protocol NextUpService {
  func nextUp(from weekly: [Course], now: Date) -> [Course]
}

struct DefaultNextUpService: NextUpService {
  private let upcomingThreshold: TimeInterval = 20 * 60  // 20 分鐘

  func nextUp(from weekly: [Course], now: Date) -> [Course] {
    let cal = Calendar.current
    // Calendar.weekday: 1=Sun...7=Sat → 轉 1=Mon...7=Sun
    let sys = cal.component(.weekday, from: now)
    let today = (sys == 1) ? 7 : (sys - 1)

    // 依 weekday、開始時間排序
    let sorted = weekly.sorted { a, b in
      if a.weekday != b.weekday { return a.weekday < b.weekday }
      let sh1 = cal.component(.hour, from: a.startTime)
      let sm1 = cal.component(.minute, from: a.startTime)
      let sh2 = cal.component(.hour, from: b.startTime)
      let sm2 = cal.component(.minute, from: b.startTime)
      guard
        let s1 = cal.date(bySettingHour: sh1, minute: sm1, second: 0, of: now),
        let s2 = cal.date(bySettingHour: sh2, minute: sm2, second: 0, of: now)
      else { return false }
      return s1 < s2
    }

    let upcoming = sorted.filter { c in
      if c.weekday < today { return false }
      if c.weekday > today { return true }
      guard let end = alignedEndDate(for: c, calendar: cal, reference: now) else { return false }
      return end.timeIntervalSince(now) > upcomingThreshold
    }

    if !upcoming.isEmpty { return upcoming }

    // 星期日 12:00 後若沒有課，預先顯示下週一課程
    if today == 7, cal.component(.hour, from: now) >= 12 {
      return sorted.filter { $0.weekday == 1 }
    }

    return upcoming
  }

  private func alignedEndDate(for course: Course, calendar: Calendar, reference: Date) -> Date? {
    let hour = calendar.component(.hour, from: course.endTime)
    let minute = calendar.component(.minute, from: course.endTime)
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference)
  }
}

func countCoursesToday(_ weeklySchedule: [Course], currentDate now: Date = Date()) -> Int {
  let cal = Calendar.current
  let sys = cal.component(.weekday, from: now)
  let today = (sys == 1) ? 7 : (sys - 1)
  return weeklySchedule.lazy.filter { $0.weekday == today }.count
}
