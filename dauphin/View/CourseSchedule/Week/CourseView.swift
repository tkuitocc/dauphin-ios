//
//  CourseView.swift
//  dauphin
//
//  Course card component for timeline view
//

import SwiftUI

struct CourseView: View {
    let course: Course
    let height: CGFloat
    let yOffset: CGFloat

    private var courseColor: Color {
        CourseColors.color(for: course.name)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(courseColor.opacity(0.85))
            .frame(height: max(height - 4, 20))  // Fixed 4pt gap for even spacing
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(courseColor, lineWidth: 1.5)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(course.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.9))
                        Text(course.room)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "number.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.9))
                        Text(course.stdNo)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
                .padding(8),
                alignment: .topLeading
            )
            .shadow(color: courseColor.opacity(0.3), radius: 2, x: 0, y: 1)
            .offset(y: yOffset)
            .padding(.horizontal, 4)
    }
}