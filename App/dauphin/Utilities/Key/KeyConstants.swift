import Foundation
import OSLog

enum KeyConstants {
  private static let logger = Logger(
    subsystem: "group.cantpr09ram.dauphin", category: "KeyConstants")

  static func loadAPIKeys() async throws {
    if let key = KeychainManager.shared.get(forKey: "AES256KEY"),
      let iv = KeychainManager.shared.get(forKey: "AES256IV"),
      !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !iv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      APIKeys.storage["AES256KEY"] = key
      APIKeys.storage["AES256IV"] = iv
      logger.info("API keys loaded from Keychain")
      return
    }

    guard let url = Bundle.main.url(forResource: "api", withExtension: "plist") else {
      logger.error("Unable to find 'api.plist' in the main bundle")
      throw NSError(
        domain: "KeyConstants", code: 404,
        userInfo: [NSLocalizedDescriptionKey: "api.plist file not found in main bundle."])
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = PropertyListDecoder()
      let aesDict = try decoder.decode([String: AES].self, from: data)

      guard let aes = aesDict["AES"] else {
        logger.error("'AES' key not found in plist")
        throw NSError(
          domain: "KeyConstants", code: 404,
          userInfo: [NSLocalizedDescriptionKey: "'AES' key not found in plist."])
      }

      let key = aes.key.trimmingCharacters(in: .whitespacesAndNewlines)
      let iv = aes.iv.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !key.isEmpty, !iv.isEmpty else {
        logger.error("AES key or IV is empty")
        throw NSError(
          domain: "KeyConstants", code: 422,
          userInfo: [NSLocalizedDescriptionKey: "AES key or IV is empty."])
      }

      APIKeys.storage["AES256IV"] = iv
      APIKeys.storage["AES256KEY"] = key

      // 將 API keys 儲存到 Keychain（假設 KeychainManager 已實作）
      for (key, value) in APIKeys.storage {
        KeychainManager.shared.save(value, forKey: key)
      }
      logger.info("API keys successfully saved to Keychain")
    } catch {
      logger.error("Failed to load or decode 'APIKEYS.plist': \(error.localizedDescription)")
      throw error
    }
  }

  enum APIKeys {
    fileprivate(set) static var storage = [String: String]()

    static var aes256Iv: String {
      guard let value = storage["AES256IV"] else {
        logger.error("'AES256IV' not found in storage")
        preconditionFailure("AES256IV missing from storage")
      }
      return value
    }

    static var aes256Key: String {
      guard let value = storage["AES256KEY"] else {
        logger.error("'AES256KEY' not found in storage")
        preconditionFailure("AES256KEY missing from storage")
      }
      return value
    }
  }
}
