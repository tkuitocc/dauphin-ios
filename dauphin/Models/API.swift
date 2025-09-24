import SwiftUI

// MARK: - Data Models

// Model for AES configuration
struct AES: Decodable {
  let iv: String
  let key: String

  private enum CodingKeys: String, CodingKey {
    case iv = "IV"
    case key = "KEY"
  }
}
