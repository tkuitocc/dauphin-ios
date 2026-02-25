//
//  CourseDetailView.swift
//  dauphin
//
//  Created on 2025-09-19.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @Environment(\.dismiss) var dismiss
    @AppStorage(
        Constants.showEnglishCourseName, store: UserDefaults(suiteName: Constants.appGroupSuiteName)
    ) private var showEnglishCourseName = Course.defaultShowEnglishCourseName()
    @AppStorage(
        Constants.showEnglishTeacherName,
        store: UserDefaults(suiteName: Constants.appGroupSuiteName)) private
        var showEnglishTeacherName = Course.defaultShowEnglishTeacherName()

    // Cache expensive computations
    private let dayOfWeek: String
    private let timeRange: String
    private let hasNote: Bool

    private var displayName: String { course.displayName(showEnglish: showEnglishCourseName) }
    private var useCompactTitle: Bool {
        course.isShowingEnglishName(showEnglish: showEnglishCourseName)
    }

    init(course: Course) {
        self.course = course

        let days = [
            "", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
        ]
        dayOfWeek = days[min(max(course.weekday, 0), days.count - 1)]

        let formatter = CourseDetailView.timeFormatter
        let start = formatter.string(from: course.startTime)
        let end = formatter.string(from: course.endTime)
        timeRange = "\(start) - \(end)"

        hasNote = !course.note.isEmpty
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(title: "Time", content: timeRange, subcontent: dayOfWeek)
                    Divider()
                    detailRow(title: "Location", content: course.room)
                    Divider()
                    detailRow(title: "Seat Number", content: course.stdNo)
                    Divider()
                    detailRow(
                        title: "Instructor",
                        content: course.displayTeacher(showEnglish: showEnglishTeacherName))

                    if hasNote {
                        Divider()
                        detailRow(title: "Note", content: course.note, isNote: true)
                    }
                    let code =
                        course.room.range(of: #"^[A-Za-z]+"#, options: .regularExpression).map {
                            String(course.room[$0]).uppercased()
                        } ?? "X"

                    LandmarkView(coordinate: letterToCoordinate(for: code))

                }.padding(24)

            }.navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .principal) {
                    Text(displayName).font(
                        .system(size: useCompactTitle ? 15 : 17, weight: .semibold)
                    ).lineLimit(1)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    @ViewBuilder private func detailRow(
        title: String, content: String, subcontent: String? = nil, isNote: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(Color(UIColor.secondaryLabel))
                if let subcontent = subcontent {
                    Text(subcontent).font(.system(size: 14)).foregroundColor(
                        Color(UIColor.secondaryLabel))
                }
                Text(content).font(
                    .system(size: isNote ? 14 : 16, weight: isNote ? .regular : .medium)
                ).foregroundColor(Color(UIColor.label)).fixedSize(
                    horizontal: false, vertical: isNote)
            }
        }
    }
}

#Preview {
    CourseDetailView(
        course: Course(
            name: "Programming", room: "E236", teacher: "Dr. Smith", time: "1, 2",
            startTime: Date(), endTime: Date().addingTimeInterval(3600), stdNo: "A12", weekday: 1,
            note: "This is a sample note for the course"))
}
