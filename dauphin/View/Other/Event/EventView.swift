//
//  EventView.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//

import SwiftUI

struct EventView: View {
  @StateObject private var viewModel = EventViewModel()
  private let eventManager = EventManager()
  @State private var toggleState = false  // false = Second semester (default)

  var body: some View {
    List(viewModel.events) { event in
      HStack {
        VStack(alignment: .leading) {
          Text(event.event)
            .font(.headline)
          HStack {
            if event.startDate == event.endDate {
              Text("\(event.startDate, formatter: dateFormatter)")
                .font(.footnote)
            } else {
              Text(
                "\(event.startDate, formatter: dateFormatter) - \(event.endDate, formatter: dateFormatter)"
              )
              .font(.footnote)
            }
          }
        }
        Spacer()
        Button(action: {
          eventManager.requestAccessAndAddEvent(event: event)
        }) {
          HStack {
            Image(systemName: "calendar.badge.plus")
              .font(.system(size: 16))
              .foregroundColor(.blue)
          }
          .padding(8)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
        }
      }.padding(2)
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Picker("Semester", selection: $toggleState) {
          Text("First").tag(true)
          Text("Second").tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 140)
        .onChange(of: toggleState) { newValue in
          let queryParameters: [String: String] = newValue ? ["t": "1"] : ["t": "2"]
          viewModel.loadXMLData(withQuery: queryParameters)
          viewModel.objectWillChange.send()
        }
      }
    }
    .onAppear {
      let queryParameters = [
        "t": "2"
      ]
      viewModel.loadXMLData(withQuery: queryParameters)
      // Events loaded
    }
  }
}

private var dateFormatter: DateFormatter {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy M d EEEE"
  formatter.locale = Locale(identifier: "zh_TW")
  return formatter
}

#Preview {
  EventView()
}
