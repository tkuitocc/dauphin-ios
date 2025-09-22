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
  @StateObject private var courseViewModel = CourseViewModel()
  @State private var showingClearCacheAlert = false
  @State private var cacheCleared = false
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
            Label {
              HStack {
                Text("Clear Cache")
                Spacer()
                if cacheCleared {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .transition(.scale)
                }
              }
            } icon: {
              Image(systemName: "trash")
                .foregroundColor(.red)
            }
            .tag(SettingsSection.cache)
            .contentShape(Rectangle())
            // .onTapGesture {
            //   selectedSection = .cache
            //   showingClearCacheAlert = true
            // }
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
          case .cache, .none:
            VStack(spacing: 20) {
              Image(systemName: selectedSection == .cache ? "trash" : "gear")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              Text(selectedSection == .cache ? "Cache Management" : "Select a setting")
                .font(.title2)
                .foregroundColor(.gray)
              if selectedSection == .cache {
                Button("Clear Cache") {
                  showingClearCacheAlert = true
                }
                .buttonStyle(.borderedProminent)
              }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
          }
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
          Button("Cancel", role: .cancel) {}
          Button("Clear", role: .destructive) {
            clearCache()
          }
        } message: {
          Text(
            "This will remove all cached course data. You'll need to refresh to reload your courses."
          )
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
            Button(action: {
              showingClearCacheAlert = true
            }) {
              Label {
                HStack {
                  Text("Clear Cache")
                  Spacer()
                  if cacheCleared {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                      .transition(.scale)
                  }
                }
              } icon: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
            }
            .foregroundColor(Color(UIColor.label))
          }
        }
        .navigationTitle("Settings")
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
          Button("Cancel", role: .cancel) {}
          Button("Clear", role: .destructive) {
            clearCache()
          }
        } message: {
          Text(
            "This will remove all cached course data. You'll need to refresh to reload your courses."
          )
        }
      }
    }
  }

  private func clearCache() {
    // Use CourseViewModel's clearCache method
    courseViewModel.clearCache()

    // Show success indicator
    withAnimation {
      cacheCleared = true
    }

    // Reset the indicator after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      withAnimation {
        cacheCleared = false
      }
    }
  }
}

#Preview {
  SettingView(viewModel: AuthViewModel())
}
