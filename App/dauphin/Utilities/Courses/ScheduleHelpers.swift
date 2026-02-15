import Foundation

// 舊/其他呼叫：不帶日期，用現在時間
func getUpcomingCourses(from weeklySchedule: [Course]) -> [Course] {
  DefaultNextUpService().nextUp(from: weeklySchedule, now: Date())
}

// 你的 Widget 呼叫：label 為 currentDate
func getUpcomingCourses(from weeklySchedule: [Course], currentDate now: Date) -> [Course] {
  DefaultNextUpService().nextUp(from: weeklySchedule, now: now)
}

// 若還有使用 `date:` 標籤的舊呼叫，也一併支援
func getUpcomingCourses(from weeklySchedule: [Course], date now: Date) -> [Course] {
  DefaultNextUpService().nextUp(from: weeklySchedule, now: now)
}
