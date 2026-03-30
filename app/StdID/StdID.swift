import Code39
import OSLog
import SwiftUI
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let ssoStuNo: String
}

struct Provider: TimelineProvider {
    private static let logger = Logger(subsystem: Constants.loggerSubsystem, category: "StdID")
    func placeholder(in _: Context) -> SimpleEntry { SimpleEntry(date: .now, ssoStuNo: "") }

    func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: .now, ssoStuNo: "123456789")
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date()
        let stuNo = fetchSsoStuNo()
        Provider.logger.info("fetchSsoStuNo() completed")
        let entry = SimpleEntry(date: now, ssoStuNo: stuNo)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchSsoStuNo() -> String {
        let defaults = UserDefaults(suiteName: Constants.appGroupSuiteName)
        defaults?.synchronize()
        guard let value = defaults?.string(forKey: Constants.ssoTokenKey) else {
            Provider.logger.info("ssoStuNo not found, returning default value.")
            return ""
        }
        Provider.logger.info("Retrieved ssoStuNo")
        return value
    }
}

struct StdIDEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(spacing: 8) {
            if entry.ssoStuNo.count > 3 {
                Code39View(entry.ssoStuNo).frame(width: 296, height: 96).padding(
                    .init(top: 5, leading: 20, bottom: 5, trailing: 20))
                Text(verbatim: "\(entry.ssoStuNo)").foregroundStyle(.black)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.text.rectangle.trianglebadge.exclamationmark.fill")
                        .font(.system(size: 60, weight: .semibold))
                    Text(String(localized: "widget.notLoggedIn"))
                        .font(.caption).fontWeight(.medium)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.padding(12).foregroundStyle(.black).background(Color.white)
    }
}

struct StdID: Widget {
    let kind: String = "StdIDWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                StdIDEntryView(entry: entry).containerBackground(Color.white, for: .widget)
                    .environment(\.colorScheme, .light)
            } else {
                StdIDEntryView(entry: entry).environment(\.colorScheme, .light)
            }
        }.configurationDisplayName(String(localized: "widget.stdid.displayName")).description(
            String(localized: "widget.stdid.description")
        ).supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) { StdID() } timeline: {
    SimpleEntry(date: .now, ssoStuNo: "A12345678")

    SimpleEntry(date: .now, ssoStuNo: "")
}
