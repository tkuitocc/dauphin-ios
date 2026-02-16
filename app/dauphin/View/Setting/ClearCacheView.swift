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
    @State private var clearTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Text("Clear cached course data to free up storage")

            Button(action: { showingClearCacheAlert = true }) {
                Label("Clear Cache", systemImage: "trash")
            }.buttonStyle(.borderedProminent).tint(.red)

            if cacheCleared {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Cache cleared successfully").foregroundColor(.green)
                }.font(.headline).transition(.scale.combined(with: .opacity))
            }
        }.alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearCache() }
        } message: {
            Text(
                "This will remove all cached course data. You'll need to refresh to reload your courses."
            )
        }.onDisappear {
            clearTask?.cancel()
            clearTask = nil
        }
    }

    private func clearCache() {
        courseViewModel.clearCache()

        withAnimation(.spring()) { cacheCleared = true }

        clearTask?.cancel()
        clearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation { cacheCleared = false }
        }
    }
}

#Preview { ClearCacheView() }
