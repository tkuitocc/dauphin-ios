//
//  OngoingStatusIndicator.swift
//  dauphin
//
//  Status indicator component for ongoing courses with pulsing animation
//

import SwiftUI

struct OngoingStatusIndicator: View {
    var text: String = "Ongoing"
    var color: Color = .green
    var fontSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                // Outer pulsing circle
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .modifier(PulsingAnimation(finalScale: 1.5, finalOpacity: 0.3, duration: 1.0))

                // Middle pulsing circle
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .modifier(PulsingAnimation(finalScale: 1.3, duration: 1.0))

                // Core dot that pulses
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .modifier(PulsingAnimation(finalScale: 1.2, initialScale: 0.8, duration: 1.0))
            }

            Text(text)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Default green "Ongoing" indicator
        OngoingStatusIndicator()

        // Custom "Live" indicator in red
        OngoingStatusIndicator(text: "Live", color: .red)

        // Custom "Active" indicator in blue with larger text
        OngoingStatusIndicator(text: "Active", color: .blue, fontSize: 14)

        // Custom "In Progress" indicator in orange
        OngoingStatusIndicator(text: "In Progress", color: .orange, fontSize: 11)
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}