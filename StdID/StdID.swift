import Code39
import OSLog
import SwiftUI
import WidgetKit

private let stdIDLogger = Logger(subsystem: "group.cantpr09ram.dauphin", category: "StdID")

struct SimpleEntry: TimelineEntry {
  let date: Date
  let ssoStuNo: String
}

struct Provider: TimelineProvider {
  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: .now, ssoStuNo: "")
  }

  func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(
      date: .now,
      ssoStuNo: "123456789"
    )
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    let now = Date()
    let stuNo = fetchSsoStuNo()
    stdIDLogger.info("fetchSsoStuNo() → \(stuNo, privacy: .public)")
    let entry = SimpleEntry(date: now, ssoStuNo: stuNo)

    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func fetchSsoStuNo() -> String {
    let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
    defaults?.synchronize()
    if let value = defaults?.string(forKey: Constants.ssoTokenKey) {
      stdIDLogger.info("Retrieved ssoStuNo: \(value, privacy: .public)")
      return value
    } else {
      stdIDLogger.info("ssoStuNo not found, returning default value.")
      return ""
    }
  }
}

struct StdIDEntryView: View {
  var entry: SimpleEntry

  var body: some View {
    VStack(spacing: 8) {
      if entry.ssoStuNo.count > 3 {
        Code39View(entry.ssoStuNo)
          .frame(width: 296, height: 96)
          .padding(.init(top: 5, leading: 20, bottom: 5, trailing: 20))
          .background(Color.white)
        Text("\(entry.ssoStuNo)")
      } else {
        Text("You need to login with SSO")
      }
    }
    .padding(12)
  }
}

struct StdID: Widget {
  let kind: String = "StdIDWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        StdIDEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        StdIDEntryView(entry: entry)
          .environment(\.colorScheme, .light)
      }
    }
    .configurationDisplayName("Student Barcode")
    .description("Showing your StudentID use barcode.")
    .supportedFamilies([.systemMedium])
  }
}

#Preview(as: .systemMedium) {
  StdID()
} timeline: {
  SimpleEntry(date: .now, ssoStuNo: "A12345678")
}
