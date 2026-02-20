//
//  CourseDetailView.swift
//  dauphin
//
//  Created on 2025-09-19.
//

import Foundation
import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @Environment(\.dismiss) private var dismiss
    private let viewData: CourseDetailViewData

    init(course: Course) {
        self.course = course
        viewData = CourseDetailViewData(course: course)
    }

    var body: some View {
        NavigationStack {
            List {
                scheduleSection
                detailsSection
                if viewData.hasNote { noteSection }
                mapSection
            }.listStyle(.insetGrouped).navigationTitle(course.name).navigationBarTitleDisplayMode(
                .inline
            ).toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var scheduleSection: some View {
        Section {
            LabeledContent(LocalizedStringKey("course.detail.time"), value: viewData.timeRangeText)
            LabeledContent(LocalizedStringKey("course.detail.day"), value: viewData.dayText)
        } header: {
            Text(LocalizedStringKey("course.detail.section.schedule"))
        }
    }

    private var detailsSection: some View {
        Section {
            LabeledContent(LocalizedStringKey("course.detail.location"), value: course.room)
            LabeledContent(LocalizedStringKey("course.detail.seatNumber"), value: course.stdNo)
            LabeledContent(LocalizedStringKey("course.detail.instructor"), value: course.teacher)
        } header: {
            Text(LocalizedStringKey("course.detail.section.details"))
        }
    }

    private var noteSection: some View {
        Section {
            Text(course.note).font(.body).lineSpacing(3).fixedSize(
                horizontal: false, vertical: true)
        } header: {
            Text(LocalizedStringKey("course.detail.section.note"))
        }
    }

    private var mapSection: some View {
        Section {
            LandmarkView(coordinate: letterToCoordinate(for: viewData.roomCode)).padding(
                .horizontal, 6
            ).padding(.vertical, 4).listRowInsets(
                EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            ).listRowBackground(Color.clear)
        } header: {
            Text(LocalizedStringKey("course.detail.section.map"))
        }
    }
}

// MARK: - View Data

private struct CourseDetailViewData {
    let timeRangeText: String
    let dayText: String
    let hasNote: Bool
    let roomCode: String

    init(course: Course) {
        let formatter = Self.timeFormatter
        let start = formatter.string(from: course.startTime)
        let end = formatter.string(from: course.endTime)
        timeRangeText = "\(start) - \(end)"
        dayText = Self.localizedWeekdayText(for: course.weekday)
        hasNote = !course.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        roomCode =
            course.room.range(of: #"^[A-Za-z]+"#, options: .regularExpression).map {
                String(course.room[$0]).uppercased()
            } ?? "X"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static func localizedWeekdayText(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        let symbols = formatter.weekdaySymbols ?? []
        guard !symbols.isEmpty else { return "" }
        let normalizedWeekday = min(max(weekday, 1), 7)
        let symbolIndex = normalizedWeekday % 7
        return symbols[symbolIndex]
    }
}

#Preview {
    CourseDetailView(
        course: Course(
            name: "Programming", room: "E236", teacher: "Dr. Smith", time: "1, 2",
            startTime: Date(), endTime: Date().addingTimeInterval(3600), stdNo: "A12", weekday: 1,
            note: "This is a sample note for the course"))
}
