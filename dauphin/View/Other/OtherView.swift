//
//  OtherView.swift
//  dauphin
//
//  Created by \u8b19 on 11/25/24.
//

import SwiftUI

enum OtherSection: String, CaseIterable {
  case calendar = "calendar"
  case library = "library"
  case map = "map"
}

struct OtherView: View {
  @ObservedObject var authViewModel: AuthViewModel
  @State private var selectedSection: OtherSection? = .calendar
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  var body: some View {
    if horizontalSizeClass == .regular {
      // iPad/Mac layout with sidebar
      NavigationSplitView {
        List(selection: $selectedSection) {
          Label("Calendar", systemImage: "calendar")
            .tag(OtherSection.calendar)

          Label("Library", systemImage: "books.vertical.fill")
            .tag(OtherSection.library)

          Label("Campus Map", systemImage: "map.fill")
            .tag(OtherSection.map)
        }
        .navigationTitle("Other")
        .listStyle(SidebarListStyle())
      } detail: {
        Group {
          switch selectedSection {
          case .calendar:
            EventView()
          case .library:
            LibraryView(authViewModel: authViewModel)
          case .map:
            WifiView()
          case .none:
            VStack(spacing: 20) {
              Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              Text("Select an option")
                .font(.title2)
                .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
          }
        }
      }
    } else {
      // iPhone layout with navigation stack
      NavigationView {
        List {
          NavigationLink(destination: EventView()) {
            Label("Calendar", systemImage: "calendar")
          }

          NavigationLink(destination: LibraryView(authViewModel: authViewModel)) {
            Label("Library", systemImage: "books.vertical.fill")
          }

          NavigationLink(destination: WifiView()) {
            Label("Campus Map", systemImage: "map.fill")
          }
        }
        .navigationTitle("Other")
      }
    }
  }
}

#Preview {
  OtherView(authViewModel: AuthViewModel())
}
