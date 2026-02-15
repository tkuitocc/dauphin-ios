import Code39
import OSLog
import SwiftUI
import WidgetKit

struct SimpleEntry: TimelineEntry {
  let date: Date
  let ssoStuNo: String
}

struct Provider: TimelineProvider {
  private static let logger = Logger(subsystem: "group.cantpr09ram.dauphin", category: "StdID")
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
    Provider.logger.info("fetchSsoStuNo() → \(stuNo, privacy: .public)")
    let entry = SimpleEntry(date: now, ssoStuNo: stuNo)

    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func fetchSsoStuNo() -> String {
    let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
    defaults?.synchronize()
    if let value = defaults?.string(forKey: Constants.ssoTokenKey) {
      Provider.logger.info("Retrieved ssoStuNo: \(value, privacy: .public)")
      return value
    } else {
      Provider.logger.info("ssoStuNo not found, returning default value.")
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
        Text("\(entry.ssoStuNo)")
          .foregroundStyle(.black)
      } else {
        VStack(spacing: 8) {
          Image(systemName: "person.text.rectangle.trianglebadge.exclamationmark.fill")
            .font(.system(size: 60, weight: .semibold))
          Text("尚未登入")
            .font(.caption)
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .padding(12)
    .foregroundStyle(.black)
    .background(Color.white)
  }
}

struct StdID: Widget {
  let kind: String = "StdIDWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        StdIDEntryView(entry: entry)
          .containerBackground(Color.white, for: .widget)
          .environment(\.colorScheme, .light)
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

  SimpleEntry(date: .now, ssoStuNo: "")
}
