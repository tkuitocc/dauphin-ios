//
//  SettingView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

enum SettingsSection: String, CaseIterable {
  case account = "account"
  case about = "about"
  case cache = "cache"
}

struct SettingView: View {
  @ObservedObject var viewModel: AuthViewModel
  @State private var selectedSection: SettingsSection? = .account
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  var body: some View {
    if horizontalSizeClass == .regular {
      // iPad/Mac layout with sidebar
      NavigationSplitView {
        List(selection: $selectedSection) {
          Label("Account", systemImage: "person.crop.circle")
            .tag(SettingsSection.account)

          Label("About Us", systemImage: "figure.wave")
            .tag(SettingsSection.about)

          Section("Data Management") {
            Label("Clear Cache", systemImage: "trash")
              .tag(SettingsSection.cache)
          }
        }
        .navigationTitle("Settings")
        .listStyle(SidebarListStyle())
      } detail: {
        Group {
          switch selectedSection {
          case .account:
            LibMainView(viewModel: viewModel)
          case .about:
            AboutUsView()
          case .cache:
            ClearCacheView()
          case .none:
            VStack(spacing: 20) {
              Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              Text("Select a setting")
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
          NavigationLink(destination: LibMainView(viewModel: viewModel)) {
            Label("Account", systemImage: "person.crop.circle")
          }

          NavigationLink(destination: AboutUsView()) {
            Label("About Us", systemImage: "figure.wave")
          }

          Section("Data Management") {
            NavigationLink(destination: ClearCacheView()) {
              Label("Clear Cache", systemImage: "trash")
            }
          }
        }
        .navigationTitle("Settings")
      }
    }
  }
}

#Preview {
  SettingView(viewModel: AuthViewModel())
}
