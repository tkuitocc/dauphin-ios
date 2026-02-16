import Foundation
import OSLog

@MainActor final class EventViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: "group.cantpr09ram.dauphin", category: "EventViewModel")
    @Published private(set) var events: [CalendarEvent] = []

    func loadXMLData(withQuery query: [String: String]) async {
        var components = URLComponents(string: "https://ilifeapi.az.tku.edu.tw/data/xml_cal.ashx")
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components?.url else {
            Self.logger.error("Failed to create URL from components")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
                Self.logger.error("HTTP error: \(http.statusCode)")
                return
            }

            let parsed = try await Self.parseEvents(from: data, timeZone: .current)

            self.events = parsed
        } catch is CancellationError { Self.logger.debug("Cancelled XML load") } catch {
            Self.logger.error("Error loading XML data: \(error.localizedDescription)")
        }
    }

    private static func parseEvents(from data: Data, timeZone: TimeZone) async throws
        -> [CalendarEvent]
    {
        let parseTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()

            let parser = XMLParser(data: data)
            let delegate = XMLParserDelegateImplementation(timeZone: timeZone)
            parser.delegate = delegate

            if parser.parse() {
                try Task.checkCancellation()
                return delegate.events
            }

            if Task.isCancelled { throw CancellationError() }

            if let err = parser.parserError { throw err }

            throw NSError(
                domain: "XMLParser", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown parse failure"])
        }

        return try await withTaskCancellationHandler {
            try await parseTask.value
        } onCancel: {
            parseTask.cancel()
        }
    }
}

final class XMLParserDelegateImplementation: NSObject, XMLParserDelegate {
    var events: [CalendarEvent] = []

    private var currentElement = ""
    private var weekBuf = ""
    private var dateBuf = ""
    private var weekdayBuf = ""
    private var eventBuf = ""
    private var currentStartDate: Date?
    private var currentEndDate: Date?

    private let calendar: Calendar
    private let ymdFormatter: DateFormatter
    private let ymdLooseFormatter: DateFormatter
    private let mdFormatter: DateFormatter

    init(timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar

        ymdFormatter = Self.makeFormatter(
            dateFormat: "yyyy-MM-dd", calendar: calendar, timeZone: timeZone)
        ymdLooseFormatter = Self.makeFormatter(
            dateFormat: "yyyy-M-d", calendar: calendar, timeZone: timeZone)
        mdFormatter = Self.makeFormatter(
            dateFormat: "MM-dd", calendar: calendar, timeZone: timeZone)

        super.init()
    }

    private static func makeFormatter(dateFormat: String, calendar: Calendar, timeZone: TimeZone)
        -> DateFormatter
    {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.calendar = calendar
        formatter.dateFormat = dateFormat
        return formatter
    }

    private func parseDate(_ s: Substring, fallbackYear: Int?) -> Date? {
        let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = ymdFormatter.date(from: str) { return d }
        if let d = ymdLooseFormatter.date(from: str) { return d }
        if let year = fallbackYear, let md = mdFormatter.date(from: str) {
            let comps = calendar.dateComponents([.month, .day], from: md)
            var c = DateComponents(calendar: calendar, timeZone: calendar.timeZone)
            c.year = year
            c.month = comps.month
            c.day = comps.day
            return calendar.date(from: c)
        }
        return nil
    }

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "cal1" || elementName == "cal" {
            weekBuf.removeAll()
            dateBuf.removeAll()
            weekdayBuf.removeAll()
            eventBuf.removeAll()
            currentStartDate = nil
            currentEndDate = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard !string.isEmpty else { return }
        switch currentElement {
        case "週次": weekBuf += string
        case "日期": dateBuf += string
        case "星期": weekdayBuf += string
        case "事項": eventBuf += string
        default: break
        }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "日期" {
            let normalized = dateBuf.replacingOccurrences(of: "～", with: "~").replacingOccurrences(
                of: "〜", with: "~"
            ).replacingOccurrences(of: "\\s*~\\s*", with: "~", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let parts = normalized.split(
                separator: "~", maxSplits: 1, omittingEmptySubsequences: true)
            // start
            guard let startStr = parts.first,
                let start = parseDate(
                    startStr, fallbackYear: calendar.component(.year, from: Date()))
            else {
                currentStartDate = nil
                currentEndDate = nil
                return
            }
            currentStartDate = start
            // end
            if let endStr = parts.dropFirst().first {
                let y = calendar.component(.year, from: start)
                currentEndDate = parseDate(endStr, fallbackYear: y) ?? start
            } else {
                currentEndDate = start
            }

            if let s = currentStartDate, let e = currentEndDate, s > e {
                currentStartDate = e
                currentEndDate = s
            }
        }

        if elementName == "cal1" || elementName == "cal", let start = currentStartDate,
            let end = currentEndDate
        {
            events.append(
                CalendarEvent(
                    week: weekBuf.trimmingCharacters(in: .whitespacesAndNewlines), startDate: start,
                    endDate: end,
                    weekday: weekdayBuf.trimmingCharacters(in: .whitespacesAndNewlines),
                    event: eventBuf.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {}
}
