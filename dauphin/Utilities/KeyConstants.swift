import Foundation

enum KeyConstants {
    static func loadAPIKeys() async throws {
        guard let url = Bundle.main.url(forResource: "api", withExtension: "plist") else {
            print("Error: Unable to find 'api.plist' in the main bundle.")
            throw NSError(domain: "KeyConstants", code: 404, userInfo: [NSLocalizedDescriptionKey: "APIKEYS.plist file not found in main bundle."])
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let aesDict = try decoder.decode([String: AES].self, from: data)
            
            guard let aes = aesDict["AES"] else {
                print("Error: 'AES' key not found in plist.")
                throw NSError(domain: "KeyConstants", code: 404, userInfo: [NSLocalizedDescriptionKey: "'AES' key not found in plist."])
            }
            
            APIKeys.storage["AES256IV"] = aes.IV
            APIKeys.storage["AES256KEY"] = aes.KEY
            
            print("Loaded AES: \(aes)")
            
            // 將 API keys 儲存到 Keychain（假設 KeychainManager 已實作）
            for (key, value) in APIKeys.storage {
                KeychainManager.shared.save(value, forKey: key)
            }
            print("API keys successfully saved to Keychain.")
        } catch {
            print("Error: Failed to load or decode 'APIKEYS.plist'. Details: \(error.localizedDescription)")
            throw error
        }
    }
    
    enum APIKeys {
        static fileprivate(set) var storage = [String: String]()
        
        static var AES256IV: String {
            if let value = storage["AES256IV"] {
                return value
            } else {
                print("Warning: 'AES256IV' not found in storage. Returning default value 'NOTHING1'.")
                return "NOTHING1"
            }
        }
        
        static var AES256KEY: String {
            if let value = storage["AES256KEY"] {
                return value
            } else {
                print("Warning: 'AES256KEY' not found in storage. Returning default value 'NOTHING2'.")
                return "NOTHING2"
            }
        }
    }
}
