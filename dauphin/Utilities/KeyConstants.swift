import Foundation
import OSLog

enum KeyConstants {
    private static let logger = Logger(subsystem: "com.dauphin.app", category: "KeyConstants")

    static func loadAPIKeys() async throws {
        guard let url = Bundle.main.url(forResource: "api", withExtension: "plist") else {
            logger.error("Unable to find 'api.plist' in the main bundle")
            throw NSError(domain: "KeyConstants", code: 404, userInfo: [NSLocalizedDescriptionKey: "api.plist file not found in main bundle."])
        }

    do {
      let data = try Data(contentsOf: url)
      let decoder = PropertyListDecoder()
      let aesDict = try decoder.decode([String: AES].self, from: data)

            guard let aes = aesDict["AES"] else {
                logger.error("'AES' key not found in plist")
                throw NSError(domain: "KeyConstants", code: 404, userInfo: [NSLocalizedDescriptionKey: "'AES' key not found in plist."])
            }

      APIKeys.storage["AES256IV"] = aes.iv
      APIKeys.storage["AES256KEY"] = aes.key


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

        static var AES256IV: String {
            if let value = storage["AES256IV"] {
                return value
            } else {
                logger.warning("'AES256IV' not found in storage. Returning default value")
                return "NOTHING1"
            }
        }

        static var AES256KEY: String {
            if let value = storage["AES256KEY"] {
                return value
            } else {
                logger.warning("'AES256KEY' not found in storage. Returning default value")
                return "NOTHING2"
            }
        }
    }
}
