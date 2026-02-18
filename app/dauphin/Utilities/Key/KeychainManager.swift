//
//  KeychainManager.swift
//  dauphin
//
//  Created by \u8b19 on 11/25/24.
//

import Foundation
import KeychainSwift

@MainActor final class KeychainManager {
    static let shared = KeychainManager()
    private let keychain: KeychainSwift

    private init() { keychain = KeychainSwift() }

    func save(_ value: String, forKey key: String) { keychain.set(value, forKey: key) }

    func get(forKey key: String) -> String? { return keychain.get(key) }

    func delete(forKey key: String) { keychain.delete(key) }
}
