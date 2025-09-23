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
  @State private var toggleState = true
  @State private var hasCheckedFirstEvent = false

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
      // First, load first semester to check the date
      if !hasCheckedFirstEvent {
        let queryParameters = [
          "t": "1"
        ]
        viewModel.loadXMLData(withQuery: queryParameters)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          if let firstEvent = viewModel.events.first {
            let month = Calendar.current.component(.month, from: firstEvent.startDate)

            // First semester starts after July (month > 7)
            // Second semester starts after January (month > 1 and month <= 7)
            if month > 7 {
              toggleState = true
            } else {
              toggleState = false
              let queryParameters = [
                "t": "2"
              ]
              viewModel.loadXMLData(withQuery: queryParameters)
            }
          } else {
            toggleState = false
            let queryParameters = [
              "t": "1"
            ]
            viewModel.loadXMLData(withQuery: queryParameters)
          }
          hasCheckedFirstEvent = true
        }
      }
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
