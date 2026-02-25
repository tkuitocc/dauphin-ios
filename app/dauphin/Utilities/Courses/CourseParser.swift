import Foundation

private struct APIResponse: Decodable {
    let stuelelist: [CourseDTO]?
    let cells: [CellDTO]?
}

private struct CourseDTO: Decodable {
    let week: String
    let chCosName: String?
    let enCosName: String?
    let note: String?
    let remark: String?
    let room: String?
    let cosNo: String?
    let cosEleSeq: String?
    let teachNameEn: String?
    let teachName: String?
    let seatNo: String?
    let timePlace: TimePlace?
    let timePlaseText: String?
    let sess1: String?
    let sess2: String?
    let sess3: String?

    enum CodingKeys: String, CodingKey {
        case week
        case chCosName = "ch_cos_name"
        case enCosName = "en_cos_name"
        case note, room, remark
        case cosNo = "cos_no"
        case cosEleSeq = "cos_ele_seq"
        case teachName = "teach_name"
        case teachNameEn = "teach_name_en"
        case seatNo = "seat_no"
        case timePlace = "timePlase"
        case timePlaseText = "time_plase"
        case sess1, sess2, sess3
    }
    struct TimePlace: Decodable { let sesses: [String] }
}

private struct CellDTO: Decodable {
    let weekNo: String?
    let sessNo: String?
    let chCosName: String?
    let enCosName: String?
    let teachName: String?
    let teachNameEn: String?
    let seatNo: String?
    let note: String?
    let room: String?

    enum CodingKeys: String, CodingKey {
        case weekNo = "weekno"
        case sessNo = "sessno"
        case chCosName = "ch_cos_name"
        case enCosName = "en_cos_name"
        case teachName = "teach_name"
        case teachNameEn = "teach_name_en"
        case seatNo = "seatno"
        case note, room
    }
}

protocol CourseParser { func parse(_ data: Data) throws -> [Course] }

struct DefaultCourseParser: CourseParser {
    let htmlStrip: (String) -> String
    let sessionToStart: (Int) -> Date?
    let sessionToEnd: (Int) -> Date?

    func parse(_ data: Data) throws -> [Course] {
        let api = try JSONDecoder().decode(APIResponse.self, from: data)

        var stueItems: [Course] = []
        for row in api.stuelelist ?? [] {
            guard let course = makeCourse(from: row) else { continue }
            stueItems.append(course)
        }

        if !stueItems.isEmpty {
            return dedupeAndMerge(stueItems)
        }

        var cellItems: [Course] = []
        for row in api.cells ?? [] {
            guard let course = makeCourse(from: row) else { continue }
            cellItems.append(course)
        }
        return dedupeAndMerge(cellItems)
    }

    private func makeCourse(from row: CourseDTO) -> Course? {
        guard let week = Int(row.week), (1 ... 7).contains(week) else { return nil }
        let sessions = parseSessionNumbers(from: row)
        guard let firstSession = sessions.first, let lastSession = sessions.last,
            let start = sessionToStart(firstSession), let end = sessionToEnd(lastSession)
        else { return nil }

        let name = cleanCourseName(row.chCosName)
        guard !name.isEmpty else { return nil }

        let enName = cleanOptional(row.enCosName)
        let room = cleanPrimaryToken(row.room) ?? ""
        let teacher = cleanPrimaryToken(row.teachName) ?? ""
        let teachNameEn = cleanOptional(row.teachNameEn)
        let seatNo = cleanPrimaryToken(row.seatNo)
        let note = cleanOptional(row.note) ?? ""
        let remark = cleanOptional(row.remark)
        let cosNo = cleanOptional(row.cosNo)
        let cosEleSeq = cleanOptional(row.cosEleSeq)

        let startMinute = minuteOfDay(from: start)
        let endMinute = minuteOfDay(from: end)

        return Course(
            name: name,
            enName: enName,
            cosNo: cosNo,
            cosEleSeq: cosEleSeq,
            room: room,
            teacher: teacher,
            teachers: [teacher],
            time: sessions.map(String.init).joined(separator: ", "),
            sessionNumbers: sessions,
            startTime: start,
            endTime: end,
            stdNo: seatNo ?? "",
            weekday: week,
            note: note,
            remark: [remark, teachNameEn].compactMap { $0 }.joined(separator: " | "),
            startMinuteOfDay: startMinute,
            endMinuteOfDay: endMinute,
            durationMinutes: max(0, endMinute - startMinute),
            sortKey: week * 10_000 + startMinute,
            sourceProvider: "stuelelist")
    }

    private func makeCourse(from row: CellDTO) -> Course? {
        guard let weekRaw = row.weekNo, let week = Int(weekRaw), (1 ... 7).contains(week) else {
            return nil
        }
        guard let sessRaw = row.sessNo, let sess = Int(sessRaw) else { return nil }

        let name = cleanCourseName(row.chCosName)
        guard !name.isEmpty else { return nil }

        guard let start = sessionToStart(sess), let end = sessionToEnd(sess) else { return nil }

        let enName = cleanOptional(row.enCosName)
        let room = cleanPrimaryToken(row.room) ?? ""
        let teacher = cleanPrimaryToken(row.teachName) ?? ""
        let teachNameEn = cleanOptional(row.teachNameEn)
        let seatNo = cleanPrimaryToken(row.seatNo)
        let note = cleanOptional(row.note) ?? ""

        let startMinute = minuteOfDay(from: start)
        let endMinute = minuteOfDay(from: end)

        return Course(
            name: name,
            enName: enName,
            room: room,
            teacher: teacher,
            teachers: [teacher],
            time: String(sess),
            sessionNumbers: [sess],
            startTime: start,
            endTime: end,
            stdNo: seatNo ?? "",
            weekday: week,
            note: note,
            remark: teachNameEn,
            startMinuteOfDay: startMinute,
            endMinuteOfDay: endMinute,
            durationMinutes: max(0, endMinute - startMinute),
            sortKey: week * 10_000 + startMinute,
            sourceProvider: "cells")
    }

    private func parseSessionNumbers(from row: CourseDTO) -> [Int] {
        let primary = row.timePlace?.sesses ?? []
        let parsedPrimary = normalizeSessions(primary)
        if !parsedPrimary.isEmpty { return parsedPrimary }

        let fromSessFields = normalizeSessions([row.sess1, row.sess2, row.sess3].compactMap { $0 })
        if !fromSessFields.isEmpty { return fromSessFields }

        return normalizeSessions(parseSessionsFromTimePlaseText(row.timePlaseText ?? ""))
    }

    private func parseSessionsFromTimePlaseText(_ text: String) -> [String] {
        // 格式例：一/06,07,08/E  414
        let comps = text.split(separator: "/", omittingEmptySubsequences: false)
        guard comps.count >= 2 else { return [] }
        return comps[1].split(separator: ",").map(String.init)
    }

    private func normalizeSessions(_ values: [String]) -> [Int] {
        let numbers = values.compactMap { raw -> Int? in
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return nil }
            return Int(t)
        }
        return Array(Set(numbers)).sorted()
    }

    private func cleanCourseName(_ raw: String?) -> String {
        cleanOptional(raw) ?? ""
    }

    private func cleanPrimaryToken(_ raw: String?) -> String? {
        guard let cleaned = cleanOptional(raw) else { return nil }
        return cleaned.split(separator: ",", maxSplits: 1).first.map(String.init)
    }

    private func cleanOptional(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let noHtml = htmlStrip(raw)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        let trimmed = noHtml.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return trimmed
    }

    private func minuteOfDay(from date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }

    private func dedupeAndMerge(_ input: [Course]) -> [Course] {
        struct CourseKey: Hashable {
            let name: String
            let enName: String?
            let cosNo: String?
            let cosEleSeq: String?
            let room: String
            let teacher: String
            let time: String
            let sessionNumbers: [Int]
            let startTime: Date
            let endTime: Date
            let seatNo: String?
            let weekday: Int
            let note: String
            let remark: String?
            let sourceProvider: String

            init(course: Course) {
                self.name = course.name
                self.enName = course.enName
                self.cosNo = course.cosNo
                self.cosEleSeq = course.cosEleSeq
                self.room = course.room
                self.teacher = course.teacher
                self.time = course.time
                self.sessionNumbers = course.sessionNumbers
                self.startTime = course.startTime
                self.endTime = course.endTime
                self.seatNo = course.seatNo
                self.weekday = course.weekday
                self.note = course.note
                self.remark = course.remark
                self.sourceProvider = course.sourceProvider
            }
        }

        var seen = Set<CourseKey>()
        var unique: [Course] = []
        for c in input where seen.insert(CourseKey(course: c)).inserted { unique.append(c) }

        struct MergeKey: Hashable {
            let name: String
            let enName: String?
            let cosNo: String?
            let cosEleSeq: String?
            let room: String
            let time: String
            let sessionNumbers: [Int]
            let startTime: Date
            let endTime: Date
            let seatNo: String?
            let weekday: Int
            let note: String
            let remark: String?
            let sourceProvider: String
        }

        var mergedByKey: [MergeKey: Course] = [:]
        for course in unique {
            let key = MergeKey(
                name: course.name,
                enName: course.enName,
                cosNo: course.cosNo,
                cosEleSeq: course.cosEleSeq,
                room: course.room,
                time: course.time,
                sessionNumbers: course.sessionNumbers,
                startTime: course.startTime,
                endTime: course.endTime,
                seatNo: course.seatNo,
                weekday: course.weekday,
                note: course.note,
                remark: course.remark,
                sourceProvider: course.sourceProvider)

            if var existing = mergedByKey[key] {
                var set = Set(existing.teachers)
                for t in course.teachers where !t.isEmpty { set.insert(t) }
                if !course.teacher.isEmpty { set.insert(course.teacher) }
                let ordered = set.sorted()
                existing.teachers = ordered
                existing.teacher = ordered.joined(separator: ", ")
                mergedByKey[key] = existing
            } else {
                var normalized = course
                let teacherSet = Set((course.teachers + [course.teacher]).filter { !$0.isEmpty })
                let ordered = teacherSet.sorted()
                normalized.teachers = ordered
                normalized.teacher = ordered.joined(separator: ", ")
                mergedByKey[key] = normalized
            }
        }
        let merged = mergedByKey.values.sorted { lhs, rhs in
            if lhs.weekday != rhs.weekday { return lhs.weekday < rhs.weekday }
            if lhs.startMinuteOfDay != rhs.startMinuteOfDay {
                return lhs.startMinuteOfDay < rhs.startMinuteOfDay
            }
            return lhs.name < rhs.name
        }
        let compressed = mergeAdjacentMeetings(merged)
        CourseLogger.logger.info("Successfully parsed \(compressed.count) courses")
        return compressed
    }

    private func mergeAdjacentMeetings(_ courses: [Course]) -> [Course] {
        struct MergeLineKey: Hashable {
            let name: String
            let enName: String?
            let cosNo: String?
            let cosEleSeq: String?
            let room: String
            let teacher: String
            let teachers: [String]
            let seatNo: String?
            let weekday: Int
            let note: String
            let remark: String?
            let sourceProvider: String
        }

        let grouped = Dictionary(grouping: courses) {
            MergeLineKey(
                name: $0.name,
                enName: $0.enName,
                cosNo: $0.cosNo,
                cosEleSeq: $0.cosEleSeq,
                room: $0.room,
                teacher: $0.teacher,
                teachers: $0.teachers,
                seatNo: $0.seatNo,
                weekday: $0.weekday,
                note: $0.note,
                remark: $0.remark,
                sourceProvider: $0.sourceProvider)
        }

        var output: [Course] = []
        for (_, group) in grouped {
            let sorted = group.sorted {
                if $0.weekday != $1.weekday { return $0.weekday < $1.weekday }
                return $0.startMinuteOfDay < $1.startMinuteOfDay
            }

            var accumulator: Course?
            for course in sorted {
                guard var current = accumulator else {
                    accumulator = course
                    continue
                }

                if canMergeContiguous(current, course) {
                    current = buildMergedCourse(lhs: current, rhs: course)
                    accumulator = current
                } else {
                    output.append(current)
                    accumulator = course
                }
            }
            if let accumulator { output.append(accumulator) }
        }

        return output.sorted {
            if $0.weekday != $1.weekday { return $0.weekday < $1.weekday }
            if $0.startMinuteOfDay != $1.startMinuteOfDay {
                return $0.startMinuteOfDay < $1.startMinuteOfDay
            }
            return $0.name < $1.name
        }
    }

    private func canMergeContiguous(_ lhs: Course, _ rhs: Course) -> Bool {
        guard lhs.weekday == rhs.weekday else { return false }
        guard let lhsMax = lhs.sessionNumbers.max(), let rhsMin = rhs.sessionNumbers.min() else {
            return false
        }
        return lhsMax + 1 == rhsMin
    }

    private func buildMergedCourse(lhs: Course, rhs: Course) -> Course {
        let sessions = Array(Set(lhs.sessionNumbers + rhs.sessionNumbers)).sorted()
        let start = lhs.startMinuteOfDay <= rhs.startMinuteOfDay ? lhs : rhs
        let end = lhs.endMinuteOfDay >= rhs.endMinuteOfDay ? lhs : rhs
        let teachers = Array(Set(lhs.teachers + rhs.teachers + [lhs.teacher, rhs.teacher]))
            .filter { !$0.isEmpty }
            .sorted()

        return Course(
            name: lhs.name,
            enName: lhs.enName,
            cosNo: lhs.cosNo,
            cosEleSeq: lhs.cosEleSeq,
            room: lhs.room,
            teacher: teachers.joined(separator: ", "),
            teachers: teachers,
            time: sessions.map(String.init).joined(separator: ", "),
            sessionNumbers: sessions,
            startTime: start.startTime,
            endTime: end.endTime,
            stdNo: lhs.seatNo ?? "",
            weekday: lhs.weekday,
            note: lhs.note,
            remark: lhs.remark,
            startMinuteOfDay: start.startMinuteOfDay,
            endMinuteOfDay: end.endMinuteOfDay,
            durationMinutes: max(0, end.endMinuteOfDay - start.startMinuteOfDay),
            sortKey: lhs.weekday * 10_000 + start.startMinuteOfDay,
            sourceProvider: lhs.sourceProvider)
    }
}
