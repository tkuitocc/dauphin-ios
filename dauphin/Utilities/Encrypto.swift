//
//  Encrypto.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import CommonCrypto
import CryptoKit
import Foundation
import SwiftUI

class CustomAES256Helper {
  private let AES256IV: String
  private let AES256KEY: String

  init(key: String, iv: String) {
    AES256KEY = key
    AES256IV = iv
  }

  // MARK: - AES-256 Encryption and Decryption

  func encryptDecrypt(data: String, mode: CCOperation) -> String? {
    guard let keyData = AES256KEY.data(using: .utf8),
      let ivData = AES256IV.data(using: .utf8),
      let inputData = mode == CCOperation(kCCEncrypt)
        ? data.data(using: .utf8) : Data(base64Encoded: data)
    else {
      return nil
    }

    let keyLength = size_t(kCCKeySizeAES256)
    let dataOutLength = inputData.count + kCCBlockSizeAES128
    var dataOut = Data(count: dataOutLength)
    var numBytesOut: size_t = 0

    let cryptStatus = dataOut.withUnsafeMutableBytes { dataOutBytes in
      inputData.withUnsafeBytes { dataInBytes in
        ivData.withUnsafeBytes { ivBytes in
          keyData.withUnsafeBytes { keyBytes in
            CCCrypt(
              mode,  // Operation (Encrypt/Decrypt)
              CCAlgorithm(kCCAlgorithmAES),  // Algorithm
              CCOptions(kCCOptionPKCS7Padding),  // Padding
              keyBytes.baseAddress,  // Key
              keyLength,  // Key Length
              ivBytes.baseAddress,  // IV
              dataInBytes.baseAddress,  // Input Data
              inputData.count,  // Input Length
              dataOutBytes.baseAddress,  // Output Buffer
              dataOutLength,  // Output Buffer Length
              &numBytesOut)  // Output Byte Count
          }
        }
      }
    }

    guard cryptStatus == kCCSuccess else {
      return nil
    }

    dataOut.count = numBytesOut
    if mode == CCOperation(kCCEncrypt) {
      return dataOut.base64EncodedString()
    } else {
      return String(data: dataOut, encoding: .utf8)
    }
  }

  func encrypt(data: String) -> String? {
    return encryptDecrypt(data: data, mode: CCOperation(kCCEncrypt))
  }

  func decrypt(data: String) -> String? {
    return encryptDecrypt(data: data, mode: CCOperation(kCCDecrypt))
  }

  // MARK: - SHA-256 Hash Function

  func sha256(_ input: String, length: Int) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
    return String(hashString.prefix(length))
  }

  // MARK: - Generate Random IV

  func generateRandomIV(length: Int = 16) -> String? {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    guard status == errSecSuccess else {
      return nil
    }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }
}
