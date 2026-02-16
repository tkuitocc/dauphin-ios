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

            let parsed: [CalendarEvent] = try await withCheckedThrowingContinuation { cont in
                Task.detached {
                    let parser = XMLParser(data: data)
                    let delegate = XMLParserDelegateImplementation()
                    parser.delegate = delegate
                    if parser.parse() {
                        cont.resume(returning: delegate.events)
                    } else if let err = parser.parserError {
                        cont.resume(throwing: err)
                    } else {
                        cont.resume(
                            throwing: NSError(
                                domain: "XMLParser", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Unknown parse failure"]))
                    }
                }
            }

            self.events = parsed
        } catch { Self.logger.error("Error loading XML data: \(error.localizedDescription)") }
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

    private static let cal = Calendar(identifier: .gregorian)

    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.calendar = cal
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let ymdLooseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.calendar = cal
        f.dateFormat = "yyyy-M-d"
        return f
    }()

    private static let mdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.calendar = cal
        f.dateFormat = "MM-dd"
        return f
    }()

    private static func parseDate(_ s: Substring, fallbackYear: Int?) -> Date? {
        let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = ymdFormatter.date(from: str) { return d }
        if let d = ymdLooseFormatter.date(from: str) { return d }
        if let year = fallbackYear, let md = mdFormatter.date(from: str) {
            let comps = cal.dateComponents([.month, .day], from: md)
            var c = DateComponents(calendar: cal, timeZone: TimeZone(secondsFromGMT: 0))
            c.year = year
            c.month = comps.month
            c.day = comps.day
            return cal.date(from: c)
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
                let start = Self.parseDate(
                    startStr, fallbackYear: Self.cal.component(.year, from: Date()))
            else {
                currentStartDate = nil
                currentEndDate = nil
                return
            }
            currentStartDate = start
            // end
            if let endStr = parts.dropFirst().first {
                let y = Self.cal.component(.year, from: start)
                currentEndDate = Self.parseDate(endStr, fallbackYear: y) ?? start
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
