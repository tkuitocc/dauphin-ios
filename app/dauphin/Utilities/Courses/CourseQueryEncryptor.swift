import Foundation
import OSLog

protocol CourseQueryEncryptor { @MainActor func encryptedQuery(stdNo: String) -> String? }

struct DefaultCourseQueryEncryptor: CourseQueryEncryptor {
    private static let logger = Logger(
        subsystem: Constants.loggerSubsystem, category: "CourseQueryEncryptor")

    @MainActor func encryptedQuery(stdNo: String) -> String? {
        guard let key = KeychainManager.shared.get(forKey: Constants.keychainAESKey),
            let iv = KeychainManager.shared.get(forKey: Constants.keychainAESIV)
        else {
            Self.logger.error("Missing AES key or IV in keychain")
            return nil
        }

        let helper = CustomAES256Helper(key: key, iv: iv)
        return helper.encrypt(data: "20220901200540356," + stdNo)
    }
}
