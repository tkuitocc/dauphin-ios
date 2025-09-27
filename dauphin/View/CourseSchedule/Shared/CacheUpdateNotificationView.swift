//
//  CacheUpdateNotificationView.swift
//  dauphin
//
//  Floating notification overlay for cache update status
//

import SwiftUI

struct CacheUpdateNotificationView: View {
    let message: String?
    let isUpdating: Bool

    var body: some View {
        VStack {
            if let message = message {
                HStack {
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .padding(.trailing, 4)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 4)
                    }
                    Text(message)
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            Spacer()
        }
        .padding(.top, 50)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0),
            value: message)
    }
}