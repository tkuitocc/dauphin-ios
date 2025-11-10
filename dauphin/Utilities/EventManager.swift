import EventKit

@MainActor
final class EventManager {
  let eventStore = EKEventStore()

  /// iOS 17+ 用寫入權限；舊版自動回退
  func requestWriteAccess() async -> Bool {
    if #available(iOS 17, *) {
      return await withCheckedContinuation { cont in
        eventStore.requestWriteOnlyAccessToEvents { granted, _ in
          cont.resume(returning: granted)
        }
      }
    } else {
      return await withCheckedContinuation { cont in
        eventStore.requestAccess(to: .event) { granted, _ in
          cont.resume(returning: granted)
        }
      }
    }
  }

  /// 將你的模型轉成 EKEvent，給編輯器預填
  func makeEKEvent(from ce: CalendarEvent) -> EKEvent {
    let ek = EKEvent(eventStore: eventStore)
    ek.title = ce.event
    ek.startDate = ce.startDate
    ek.endDate = ce.endDate
    ek.isAllDay = Calendar.current.isDate(ce.startDate, inSameDayAs: ce.endDate)
    ek.calendar =
      eventStore.defaultCalendarForNewEvents
      ?? eventStore.calendars(for: .event).first!
    return ek
  }
}
