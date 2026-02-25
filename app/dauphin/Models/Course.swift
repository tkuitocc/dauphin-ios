import Foundation
import OSLog
import SwiftUI

enum CourseLogger {
    static let subsystem = "group.cantpr09ram.dauphin"
    static let logger = Logger(subsystem: subsystem, category: "Course")
}

struct Course: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var enName: String?
    var cosNo: String?
    var cosEleSeq: String?
    var room: String
    var teacher: String
    var teacherEn: String?
    var teachers: [String]
    var time: String
    var sessionNumbers: [Int]
    var startTime: Date
    var endTime: Date
    var seatNo: String?
    var weekday: Int  // 約定：1...7 = 週一...週日
    var note: String
    var remark: String?
    var startMinuteOfDay: Int
    var endMinuteOfDay: Int
    var durationMinutes: Int
    var sortKey: Int
    var sourceProvider: String

    var stdNo: String { seatNo ?? "" }

    init(
        id: String? = nil, name: String, enName: String? = nil, cosNo: String? = nil,
        cosEleSeq: String? = nil, room: String, teacher: String, teacherEn: String? = nil,
        teachers: [String]? = nil, time: String, sessionNumbers: [Int] = [], startTime: Date,
        endTime: Date, stdNo: String, weekday: Int, note: String = "", remark: String? = nil,
        startMinuteOfDay: Int? = nil, endMinuteOfDay: Int? = nil, durationMinutes: Int? = nil,
        sortKey: Int? = nil, sourceProvider: String = "stuelelist"
    ) {
        self.name = name
        self.enName = enName
        self.cosNo = cosNo
        self.cosEleSeq = cosEleSeq
        self.room = room
        self.teacher = teacher
        self.teacherEn = Self.normalizeOptional(teacherEn)
        self.teachers = teachers ?? Self.normalizeTeachers(primary: teacher, extras: [])
        self.time = time
        self.sessionNumbers = sessionNumbers
        self.startTime = startTime
        self.endTime = endTime
        let normalizedSeat = Self.normalizeOptional(stdNo)
        self.seatNo = normalizedSeat
        self.weekday = weekday
        self.note = note
        self.remark = remark

        let computedStartMinute = startMinuteOfDay ?? Self.minuteOfDay(startTime)
        let computedEndMinute = endMinuteOfDay ?? Self.minuteOfDay(endTime)
        self.startMinuteOfDay = computedStartMinute
        self.endMinuteOfDay = computedEndMinute
        self.durationMinutes = durationMinutes ?? max(0, computedEndMinute - computedStartMinute)
        self.sortKey = sortKey ?? (weekday * 10_000 + computedStartMinute)
        self.sourceProvider = sourceProvider

        self.id =
            id
            ?? Self.makeStableID(
                name: name, weekday: weekday, sessionNumbers: sessionNumbers,
                startMinuteOfDay: computedStartMinute, endMinuteOfDay: computedEndMinute,
                room: room, cosEleSeq: cosEleSeq, seatNo: normalizedSeat)
    }

    private static func minuteOfDay(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }

    private static func normalizeOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizeTeachers(primary: String, extras: [String]) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        let all = [primary] + extras
        for raw in all {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty, seen.insert(t).inserted else { continue }
            output.append(t)
        }
        if output.isEmpty { return [""] }
        return output
    }

    private static func makeStableID(
        name: String, weekday: Int, sessionNumbers: [Int], startMinuteOfDay: Int,
        endMinuteOfDay: Int, room: String, cosEleSeq: String?, seatNo: String?
    ) -> String {
        let base = [
            name, String(weekday), sessionNumbers.map(String.init).joined(separator: ","),
            String(startMinuteOfDay), String(endMinuteOfDay), room, cosEleSeq ?? "", seatNo ?? "",
        ].joined(separator: "|")
        return "course_\(fnv1a64Hex(base))"
    }

    private static func fnv1a64Hex(_ input: String) -> String {
        let prime: UInt64 = 1_099_511_628_211
        var hash: UInt64 = 14_695_981_039_346_656_037
        for b in input.utf8 {
            hash ^= UInt64(b)
            hash = hash &* prime
        }
        return String(hash, radix: 16, uppercase: false)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, enName, cosNo, cosEleSeq, room, teacher, teacherEn, teachers, time,
            sessionNumbers
        case startTime, endTime, seatNo, stdNo, weekday, note, remark
        case startMinuteOfDay, endMinuteOfDay, durationMinutes, sortKey, sourceProvider
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        name = try c.decode(String.self, forKey: .name)
        enName = try c.decodeIfPresent(String.self, forKey: .enName)
        cosNo = try c.decodeIfPresent(String.self, forKey: .cosNo)
        cosEleSeq = try c.decodeIfPresent(String.self, forKey: .cosEleSeq)
        room = try c.decode(String.self, forKey: .room)
        teacher = try c.decode(String.self, forKey: .teacher)
        teacherEn = Self.normalizeOptional(try c.decodeIfPresent(String.self, forKey: .teacherEn))
        let decodedTeachers = try c.decodeIfPresent([String].self, forKey: .teachers) ?? []
        teachers = Self.normalizeTeachers(primary: teacher, extras: decodedTeachers)
        time = try c.decode(String.self, forKey: .time)
        sessionNumbers = try c.decodeIfPresent([Int].self, forKey: .sessionNumbers) ?? []
        startTime = try c.decode(Date.self, forKey: .startTime)
        endTime = try c.decode(Date.self, forKey: .endTime)

        let oldStdNo = try c.decodeIfPresent(String.self, forKey: .stdNo)
        let newSeatNo = try c.decodeIfPresent(String.self, forKey: .seatNo)
        seatNo = Self.normalizeOptional(newSeatNo ?? oldStdNo)

        weekday = try c.decode(Int.self, forKey: .weekday)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        remark = try c.decodeIfPresent(String.self, forKey: .remark)

        let fallbackStartMinute = Self.minuteOfDay(startTime)
        let fallbackEndMinute = Self.minuteOfDay(endTime)
        startMinuteOfDay =
            try c.decodeIfPresent(Int.self, forKey: .startMinuteOfDay) ?? fallbackStartMinute
        endMinuteOfDay =
            try c.decodeIfPresent(Int.self, forKey: .endMinuteOfDay) ?? fallbackEndMinute
        durationMinutes =
            try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
            ?? max(0, endMinuteOfDay - startMinuteOfDay)
        sortKey =
            try c.decodeIfPresent(Int.self, forKey: .sortKey)
            ?? (weekday * 10_000 + startMinuteOfDay)
        sourceProvider = try c.decodeIfPresent(String.self, forKey: .sourceProvider) ?? "legacy"

        id =
            try c.decodeIfPresent(String.self, forKey: .id)
            ?? Self.makeStableID(
                name: name, weekday: weekday, sessionNumbers: sessionNumbers,
                startMinuteOfDay: startMinuteOfDay, endMinuteOfDay: endMinuteOfDay, room: room,
                cosEleSeq: cosEleSeq, seatNo: seatNo)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(enName, forKey: .enName)
        try c.encodeIfPresent(cosNo, forKey: .cosNo)
        try c.encodeIfPresent(cosEleSeq, forKey: .cosEleSeq)
        try c.encode(room, forKey: .room)
        try c.encode(teacher, forKey: .teacher)
        try c.encodeIfPresent(teacherEn, forKey: .teacherEn)
        try c.encode(teachers, forKey: .teachers)
        try c.encode(time, forKey: .time)
        try c.encode(sessionNumbers, forKey: .sessionNumbers)
        try c.encode(startTime, forKey: .startTime)
        try c.encode(endTime, forKey: .endTime)
        try c.encodeIfPresent(seatNo, forKey: .seatNo)
        try c.encode(seatNo ?? "", forKey: .stdNo)
        try c.encode(weekday, forKey: .weekday)
        try c.encode(note, forKey: .note)
        try c.encodeIfPresent(remark, forKey: .remark)
        try c.encode(startMinuteOfDay, forKey: .startMinuteOfDay)
        try c.encode(endMinuteOfDay, forKey: .endMinuteOfDay)
        try c.encode(durationMinutes, forKey: .durationMinutes)
        try c.encode(sortKey, forKey: .sortKey)
        try c.encode(sourceProvider, forKey: .sourceProvider)
    }
}

extension Course {
    func isShowingEnglishName(showEnglish: Bool) -> Bool {
        guard showEnglish, let enName,
            !enName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }
        return true
    }

    func displayName(showEnglish: Bool) -> String {
        if isShowingEnglishName(showEnglish: showEnglish) { return enName ?? name }
        return name
    }

    func displayTeacher(showEnglish: Bool) -> String {
        guard showEnglish, let teacherEn,
            !teacherEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return teacher }
        return teacherEn
    }

    static func defaultShowEnglishCourseName() -> Bool {
        shouldShowEnglishCourseName(forPreferredLanguage: Locale.preferredLanguages.first)
    }

    static func defaultShowEnglishTeacherName() -> Bool {
        shouldShowEnglishCourseName(forPreferredLanguage: Locale.preferredLanguages.first)
    }

    static func shouldShowEnglishCourseName(forPreferredLanguage preferredLanguage: String?) -> Bool
    {
        guard let preferredLanguage else { return true }
        let normalized = preferredLanguage.lowercased().replacingOccurrences(of: "_", with: "-")
        let isTraditionalChinese =
            normalized.hasPrefix("zh-hant") || normalized.hasPrefix("zh-tw")
            || normalized.hasPrefix("zh-hk") || normalized.hasPrefix("zh-mo")
        return !isTraditionalChinese
    }
}

// 共用 HH:mm formatter，避免多次建立
private let hhmmFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = .current
    return f
}()

func stringToTime(_ timeString: String) -> Date? { hhmmFormatter.date(from: timeString) }

func formatTime(_ date: Date?) -> String {
    guard let date else { return "ERROR" }
    return hhmmFormatter.string(from: date)
}

// 將節次映射成時間（維持你原本僅有時分的邏輯）
public func sessionToStartTime(session: Int) -> Date? {
    let startHour = [
        1: 8, 2: 9, 3: 10, 4: 11, 5: 12, 6: 13, 7: 14, 8: 15, 9: 16, 10: 17, 11: 18, 12: 19, 13: 20,
        14: 21,
    ][session]
    guard let hour = startHour else { return nil }
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = 10
    return Calendar.current.date(from: comps)
}

public func sessionToEndTime(session: Int) -> Date? {
    let endHour = [
        1: 9, 2: 10, 3: 11, 4: 12, 5: 13, 6: 14, 7: 15, 8: 16, 9: 17, 10: 18, 11: 19, 12: 20,
        13: 21, 14: 22,
    ][session]
    guard let hour = endHour else { return nil }
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = 0
    return Calendar.current.date(from: comps)
}
