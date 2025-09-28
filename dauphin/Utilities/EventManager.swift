//
//  EventManager.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//

import EventKit
import OSLog

class EventManager {
  let eventStore = EKEventStore()
  private static let logger = Logger(
    subsystem: "group.cantpr09ram.dauphin", category: "EventManager"
  )

    /// Request access and add an event in one step
    func requestAccessAndAddEvent(event: CalendarEvent) {
        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { [weak self] granted, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        EventManager.logger.info("Calendar access granted")
                        self.addEvent(event: event)
                    } else {
                        EventManager.logger.error("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        EventManager.logger.info("Calendar access granted")
                        self.addEvent(event: event)
                    } else {
                        EventManager.logger.error("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }

    /// Add an event to the calendar
    private func addEvent(event: CalendarEvent) {
        let calendars = eventStore.calendars(for: .event)
        EventManager.logger.debug("Available calendars: \(calendars.count)")

    let calendar = selectModifiableCalendar(from: calendars) ?? createLocalCalendar()

        guard let calendar = calendar else {
            EventManager.logger.error("No modifiable calendar found")
            return
        }

    let calendarEvent = EKEvent(eventStore: eventStore)
    calendarEvent.title = event.event
    calendarEvent.startDate = event.startDate
    calendarEvent.endDate = event.endDate
    calendarEvent.calendar = calendar
    if event.startDate == event.endDate {
      calendarEvent.isAllDay = true
    }

        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
            EventManager.logger.info("Event added successfully: \(event.event)")
        } catch {
            EventManager.logger.error("Failed to save event: \(error.localizedDescription)")
        }
    }

  /// Helper function to select a modifiable calendar
  private func selectModifiableCalendar(from calendars: [EKCalendar]) -> EKCalendar? {
    // Prioritize the default calendar
    if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
      return defaultCalendar
    }
    // Fallback to a local or CalDAV calendar
    return calendars.first(where: {
      $0.allowsContentModifications && ($0.type == .local || $0.type == .calDAV)
    })
  }

  /// Create a new local calendar if no modifiable calendar is found
  private func createLocalCalendar() -> EKCalendar? {
    let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
    newCalendar.title = "My Custom Calendar"

        // Use a local source if available
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            EventManager.logger.error("No local calendar source available")
            return nil
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            EventManager.logger.info("Custom calendar created successfully")
            return newCalendar
        } catch {
            EventManager.logger.error("Failed to create calendar: \(error.localizedDescription)")
            return nil
        }
    }
}
