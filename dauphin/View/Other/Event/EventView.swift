import SwiftUI
import EventKit

struct EventView: View {
  @StateObject private var viewModel = EventViewModel()
  private let eventManager = EventManager()

  @State private var term = ( [8,9,10,11,12, 1].contains(Calendar.current.component(.month, from: Date())) ? 1 : 2 )


  @State private var hasCheckedFirstEvent = false

  struct EditItem: Identifiable { let id = UUID(); let ekEvent: EKEvent }
  @State private var editorItem: EditItem?

  var body: some View {
    List {
      ForEach(viewModel.events, id: \.id) { (event: CalendarEvent) in
        HStack {
          VStack(alignment: .leading) {
            Text(event.event).font(.headline)
            Text(dateRangeText(event)).font(.footnote)
          }
          Spacer()
          Button {
            Task {
              if await eventManager.requestWriteAccess() {
                editorItem = EditItem(ekEvent: eventManager.makeEKEvent(from: event))
              }
            }
          } label: {
            Image(systemName: "calendar.badge.plus")
              .imageScale(.medium)
              .padding(8)
              .background(Color.blue.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          }
        }
        .padding(.vertical, 2)
      }
    }
    .navigationTitle("校務行事曆")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
          Button { term = term == 1 ? 2 : 1 } label: {
            Image(systemName: term == 1 ? "chevron.down" : "chevron.up")
          }
        }
    }
    .sheet(item: $editorItem) { item in
      EventEditSheet(eventStore: eventManager.eventStore, event: item.ekEvent) { vc, _ in
        vc.dismiss(animated: true)
      }
    }
    .task(id: term) {
      await viewModel.loadXMLData(withQuery: ["t": "\(term)"])
    }
    .refreshable {
      await viewModel.loadXMLData(withQuery: ["t": "\(term)"])
    }
  }

  private func dateRangeText(_ e: CalendarEvent) -> String {
    let f = Self.fmt
    return Calendar.current.isDate(e.startDate, inSameDayAs: e.endDate)
      ? f.string(from: e.startDate)
      : "\(f.string(from: e.startDate)) - \(f.string(from: e.endDate))"
  }

  private static let fmt: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy M d EEEE"
    f.locale = Locale(identifier: "zh_TW")
    return f
  }()
}

#Preview {
  NavigationStack {
    EventView()
  }
}
