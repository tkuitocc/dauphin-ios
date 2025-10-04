import Foundation

protocol NextUpService {
  func nextUp(from weekly: [Course], now: Date) -> [Course]
}

struct DefaultNextUpService: NextUpService {
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

    // 過濾掉今天之前；今天只保留距離開始 > 20 分鐘者；未來天全保留
    return sorted.filter { c in
      if c.weekday < today { return false }
      if c.weekday > today { return true }
      let sh = cal.component(.hour, from: c.startTime)
      let sm = cal.component(.minute, from: c.startTime)
      guard let start = cal.date(bySettingHour: sh, minute: sm, second: 0, of: now) else { return false }
      return start.timeIntervalSince(now) > 0
    }
  }
}

func countCoursesToday(_ weeklySchedule: [Course], currentDate now: Date = Date()) -> Int {
  let cal = Calendar.current
  let sys = cal.component(.weekday, from: now)
  let today = (sys == 1) ? 7 : (sys - 1)
  return weeklySchedule.lazy.filter { $0.weekday == today }.count
}