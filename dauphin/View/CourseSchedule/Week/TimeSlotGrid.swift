//
//  TimeSlotGrid.swift
//  dauphin
//
//  Grid component for timeline view
//

import SwiftUI

struct TimeSlotGrid: View {
  let numberOfSlots: Int
  let totalHeight: CGFloat

  var body: some View {
    VStack(spacing: 0) {
      ForEach(0..<numberOfSlots, id: \.self) { _ in
        Rectangle()
          .stroke(Color.gray.opacity(0.4), lineWidth: 0.3)
          .frame(height: totalHeight / CGFloat(numberOfSlots))
      }
    }
  }
}
