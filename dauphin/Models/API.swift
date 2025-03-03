import SwiftUI

// MARK: - Data Models

// Model for AES configuration
struct AES: Decodable {
    let IV: String
    let KEY: String
}
