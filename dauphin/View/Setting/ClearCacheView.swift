//
//  ClearCacheView.swift
//  dauphin
//
//  Extracted clear cache functionality
//

import SwiftUI

struct ClearCacheView: View {
  @StateObject private var courseViewModel = CourseViewModel()
  @State private var showingClearCacheAlert = false
  @State private var cacheCleared = false

  var body: some View {
    VStack(spacing: 20) {
      Text("Clear cached course data to free up storage")

      Button(action: {
        showingClearCacheAlert = true
      }) {
        Label("Clear Cache", systemImage: "trash")
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)

      if cacheCleared {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Cache cleared successfully")
            .foregroundColor(.green)
        }
        .font(.headline)
        .transition(.scale.combined(with: .opacity))
      }
    }
    .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) {
        clearCache()
      }
    } message: {
      Text(
        "This will remove all cached course data. You'll need to refresh to reload your courses.")
    }
  }

  private func clearCache() {
    courseViewModel.clearCache()

    withAnimation(.spring()) {
      cacheCleared = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      withAnimation {
        cacheCleared = false
      }
    }
  }
}

#Preview {
  ClearCacheView()
}
