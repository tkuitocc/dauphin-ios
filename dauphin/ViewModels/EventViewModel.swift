//
//  EventViewModel.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//
import SwiftUI

class EventViewModel: ObservableObject {
  @Published var events: [CalendarEvent] = []

  func loadXMLData(withQuery query: [String: String]) {
    var components = URLComponents(string: "https://ilifeapi.az.tku.edu.tw/data/xml_cal.ashx?")  // Base URL
    components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }

    guard let url = components?.url else {
      print("Failed to create URL")
      return
    }

    let task = URLSession.shared.dataTask(with: url) { data, _, error in
      if let data = data {
        // Print original data
        if let dataString = String(data: data, encoding: .utf8) {
          print("Original XML Data:")
          print(dataString)
        }

        let parser = XMLParser(data: data)
        let delegate = XMLParserDelegateImplementation()
        parser.delegate = delegate

        if parser.parse() {
          DispatchQueue.main.async {
            self.events = delegate.events
          }
        }
      } else if let error = error {
        print("Error loading data: \(error)")
      }
    }
    task.resume()
  }
}

class XMLParserDelegateImplementation: NSObject, XMLParserDelegate {
  var events: [CalendarEvent] = []
  private var currentElement = ""
  private var currentWeek = ""
  private var currentStartDate: Date?
  private var currentEndDate: Date?
  private var currentWeekday = ""
  private var currentEvent = ""

  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"  // Match your XML date format
    return formatter
  }()

  func parser(
    _: XMLParser, didStartElement elementName: String, namespaceURI _: String?,
    qualifiedName _: String?, attributes _: [String: String] = [:]
  ) {
    currentElement = elementName

    //        Print the title if the element indicates a new data block
    //        if elementName == "cal1" || elementName == "cal" { // Check for both "cal1" and "cal"
    //            print("Starting new data block: \(elementName)")
    //        }
  }

  func parser(_: XMLParser, foundCharacters string: String) {
    let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedString.isEmpty else { return }

    switch currentElement {
    case "週次":
      currentWeek += trimmedString
    case "日期":
      let dates = trimmedString.components(separatedBy: " ~ ")
      if let startDateString = dates.first,
        let startDate = dateFormatter.date(from: startDateString)
      {
        currentStartDate = startDate
      }
      if dates.count > 1, let endDateString = dates.last,
        let endDate = dateFormatter.date(from: endDateString)
      {
        currentEndDate = endDate
      } else {
        currentEndDate = currentStartDate
      }
    case "星期":
      currentWeekday += trimmedString
    case "事項":
      currentEvent += trimmedString
    default:
      break
    }
  }

  func parser(
    _: XMLParser, didEndElement elementName: String, namespaceURI _: String?,
    qualifiedName _: String?
  ) {
    if elementName == "cal1" || elementName == "cal", let startDate = currentStartDate,
      let endDate = currentEndDate
    {
      let event = CalendarEvent(
        week: currentWeek,
        startDate: startDate,
        endDate: endDate,
        weekday: currentWeekday,
        event: currentEvent
      )
      events.append(event)

      // Clear temporary values for the next block
      currentWeek = ""
      currentStartDate = nil
      currentEndDate = nil
      currentWeekday = ""
      currentEvent = ""
    }
  }
}
