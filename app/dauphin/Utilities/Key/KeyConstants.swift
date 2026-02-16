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

            KeychainManager.shared.save(key, forKey: "AES256KEY")
            KeychainManager.shared.save(iv, forKey: "AES256IV")
            logger.info("API keys successfully saved to Keychain")
        } catch {
            logger.error("Failed to load or decode 'api.plist': \(error.localizedDescription)")
            throw error
        }
    }
}
