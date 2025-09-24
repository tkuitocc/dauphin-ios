import Foundation
import OSLog

private let keyConstantsLogger = Logger(
  subsystem: "group.cantpr09ram.dauphin", category: "KeyConstants"
)

enum KeyConstants {
  static func loadAPIKeys() async throws {
    guard let url = Bundle.main.url(forResource: "api", withExtension: "plist") else {
      keyConstantsLogger.error("Error: Unable to find 'api.plist' in the main bundle.")
      throw NSError(
        domain: "KeyConstants", code: 404,
        userInfo: [NSLocalizedDescriptionKey: "api.plist file not found in main bundle."])
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = PropertyListDecoder()
      let aesDict = try decoder.decode([String: AES].self, from: data)

      guard let aes = aesDict["AES"] else {
        keyConstantsLogger.error("Error: 'AES' key not found in plist.")
        throw NSError(
          domain: "KeyConstants", code: 404,
          userInfo: [NSLocalizedDescriptionKey: "'AES' key not found in plist."])
      }

      APIKeys.storage["AES256IV"] = aes.iv
      APIKeys.storage["AES256KEY"] = aes.key

      keyConstantsLogger.info(
        "Loaded AES: \(String(describing: aes), privacy: .public)"
      )

      // 將 API keys 儲存到 Keychain（假設 KeychainManager 已實作）
      for (key, value) in APIKeys.storage {
        KeychainManager.shared.save(value, forKey: key)
      }
      keyConstantsLogger.info("API keys successfully saved to Keychain.")
    } catch {
      keyConstantsLogger.error(
        "Error: Failed to load or decode 'APIKEYS.plist'. Details: \(error.localizedDescription, privacy: .public)"
      )
      throw error
    }
  }

  enum APIKeys {
    fileprivate(set) static var storage = [String: String]()

    static var aes256IV: String {
      if let value = storage["AES256IV"] {
        return value
      } else {
        keyConstantsLogger.warning(
          "Warning: 'AES256IV' not found in storage. Returning default value 'NOTHING1'."
        )
        return "NOTHING1"
      }
    }

    static var aes256Key: String {
      if let value = storage["AES256KEY"] {
        return value
      } else {
        keyConstantsLogger.warning(
          "Warning: 'AES256KEY' not found in storage. Returning default value 'NOTHING2'."
        )
        return "NOTHING2"
      }
    }
  }
}
