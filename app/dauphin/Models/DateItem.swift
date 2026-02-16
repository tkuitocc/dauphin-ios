import SwiftUI

struct DateItem: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    /// 1 = Monday ... 7 = Sunday
    let day: Int
}
