import SwiftUI

// MARK: - Data Models

// Model for AES configuration
struct AESInfo: Decodable {
    let IV: String
    let KEY: String
}

// Model for an individual API service
struct APIInfo: Decodable {
    let url: String
    let key: String
}

// Top-level configuration model matching the plist structure
struct APIConfiguration: Decodable {
    let AES: AESInfo
    let services: [String: APIInfo]
}
