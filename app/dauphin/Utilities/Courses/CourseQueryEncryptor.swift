import Foundation

protocol CourseQueryEncrypting { @MainActor func encryptedQuery(stdNo: String) -> String? }

struct DefaultCourseQueryEncryptor: CourseQueryEncrypting {
    @MainActor func encryptedQuery(stdNo: String) -> String? {
        guard let key = KeychainManager.shared.get(forKey: Constants.keychainAESKey),
            let iv = KeychainManager.shared.get(forKey: Constants.keychainAESIV)
        else { return nil }

        let helper = CustomAES256Helper(key: key, iv: iv)
        return helper.encrypt(data: "20220901200540356," + stdNo)
    }
}
