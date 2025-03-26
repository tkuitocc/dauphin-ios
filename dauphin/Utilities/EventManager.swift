//
//  EventManager.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//

import EventKit

class EventManager {
    let eventStore = EKEventStore()

    /// Request access and add an event in one step
    func requestAccessAndAddEvent(event: CalendarEvent) {
        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { [weak self] granted, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        print("Access granted")
                        self.addEvent(event: event)
                    } else {
                        print("Access denied: \(String(describing: error))")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        print("Access granted")
                        self.addEvent(event: event)
                    } else {
                        print("Access denied: \(String(describing: error))")
                    }
                }
            }
        }
    }

    /// Add an event to the calendar
    private func addEvent(event: CalendarEvent) {
        let calendars = eventStore.calendars(for: .event)
        print("Available Calendars: \(calendars.map { $0.title })")

        let calendar = selectModifiableCalendar(from: calendars) ?? createLocalCalendar()

        guard let calendar = calendar else {
            print("No modifiable calendar found.")
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
            print("Event added successfully!")
        } catch {
            print("Failed to save event: \(error)")
        }
    }

    /// Helper function to select a modifiable calendar
    private func selectModifiableCalendar(from calendars: [EKCalendar]) -> EKCalendar? {
        // Prioritize the default calendar
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            return defaultCalendar
        }
        // Fallback to a local or CalDAV calendar
        return calendars.first(where: { $0.allowsContentModifications && ($0.type == .local || $0.type == .calDAV) })
    }

    /// Create a new local calendar if no modifiable calendar is found
    private func createLocalCalendar() -> EKCalendar? {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = "My Custom Calendar"

        // Use a local source if available
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            print("No local source available")
            return nil
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Custom calendar created successfully!")
            return newCalendar
        } catch {
            print("Failed to create calendar: \(error)")
            return nil
        }
    }
}
