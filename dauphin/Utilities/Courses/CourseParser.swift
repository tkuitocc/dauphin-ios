import Foundation

private struct APIResponse: Decodable { let stuelelist: [CourseDTO] }

private struct CourseDTO: Decodable {
  let week: String
  let chCosName: String?
  let note: String?
  let room: String?
  let teachName: String?
  let seatNo: String?
  let timePlace: TimePlace?
  enum CodingKeys: String, CodingKey {
    case week
    case chCosName = "ch_cos_name"
    case note, room
    case teachName = "teach_name"
    case seatNo   = "seat_no"
    case timePlace = "timePlase"
  }
  struct TimePlace: Decodable { let sesses: [String] }
}

protocol CourseParser {
  func parse(_ data: Data) throws -> [Course]
}

struct DefaultCourseParser: CourseParser {
  let htmlStrip: (String) -> String
  let sessionToStart: (Int) -> Date?
  let sessionToEnd: (Int) -> Date?

  func parse(_ data: Data) throws -> [Course] {
    let api = try JSONDecoder().decode(APIResponse.self, from: data)
    var items: [Course] = []

    for c in api.stuelelist {
      guard
        let week = Int(c.week), (1...7).contains(week),
        let sesses = c.timePlace?.sesses,
        let f = sesses.first.flatMap(Int.init),
        let l = sesses.last.flatMap(Int.init),
        let start = sessionToStart(f),
        let end   = sessionToEnd(l)
      else { continue }

      // 所有 unknown → ""
      let raw = htmlStrip(c.chCosName ?? "")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
      let name = raw.split(separator: ",", maxSplits: 1).first.map(String.init) ?? raw

      let roomRaw = htmlStrip(c.room ?? "")
      let room = roomRaw.split(separator: ",", maxSplits: 1).first.map(String.init) ?? roomRaw

      let teacherRaw = htmlStrip(c.teachName ?? "")
      let teacher = teacherRaw.split(separator: ",", maxSplits: 1).first.map(String.init) ?? teacherRaw

      let seatRaw = htmlStrip(c.seatNo ?? "")
      let seatNo = seatRaw.split(separator: ",", maxSplits: 1).first.map(String.init) ?? seatRaw

      let time = sesses.joined(separator: ", ")
      let finalRoom = room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : room
      let note = htmlStrip(c.note ?? "")

      items.append(
        Course(name: name,
               room: finalRoom,
               teacher: teacher,
               time: time,
               startTime: start,
               endTime: end,
               stdNo: seatNo,
               weekday: week,
               note: note)
      )
    }

    return dedupeAndMerge(items)
  }

  private func dedupeAndMerge(_ input: [Course]) -> [Course] {
    var seen = Set<Course>()
    var unique: [Course] = []
    for c in input { if seen.insert(c).inserted { unique.append(c) } }

    var merged: [Course] = []
    for course in unique {
      if let idx = merged.firstIndex(where: { e in
        e.name == course.name && e.room == course.room && e.time == course.time
        && e.stdNo == course.stdNo && e.weekday == course.weekday
        && e.startTime == course.startTime && e.endTime == course.endTime && e.note == course.note
      }) {
        var m = merged[idx]
        var t = Set(m.teacher.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        t.insert(course.teacher)
        m.teacher = t.sorted().joined(separator: ", ")
        merged[idx] = m
      } else {
        merged.append(course)
      }
    }
    CourseLogger.logger.info("Successfully parsed \(merged.count) courses")
    return merged
  }
}
