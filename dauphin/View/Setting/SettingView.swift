//
//  SettingView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

struct SettingView: View {
  @ObservedObject var viewModel: AuthViewModel
  @StateObject private var courseViewModel = CourseViewModel()
  @State private var showingClearCacheAlert = false
  @State private var cacheCleared = false

  var body: some View {
    NavigationView {
      List {
        NavigationLink(destination: LibMainView(viewModel: viewModel)) {
          Label(
            title: { Text("Account") },
            icon: { Image(systemName: "person.crop.circle") }
          )
        }

        NavigationLink(destination: AboutUsView()) {
          Label(
            title: { Text("About Us") },
            icon: { Image(systemName: "figure.wave") }
          )
        }

        Section("Data Management") {
          Button(action: {
            showingClearCacheAlert = true
          }) {
            Label(
              title: {
                HStack {
                  Text("Clear Cache")
                  Spacer()
                  if cacheCleared {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                      .transition(.scale)
                  }
                }
              },
              icon: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
            )
          }
          .foregroundColor(Color(UIColor.label))
        }
      }
      .navigationTitle("Setting")
      .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Clear", role: .destructive) {
          clearCache()
        }
      } message: {
        Text(
          "This will remove all cached course data. You'll need to refresh to reload your courses.")
      }

      LibMainView(viewModel: viewModel)
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
