//
//  AESUtils.swift
//  DKCloudFramework_Example
//
//  Created by admin on 2026/2/2.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import Foundation
import CommonCrypto

private let aeskey = "66261909edb397bc"

enum AESUtils {

    // MARK: - 加密（String → Base64 String）
        static func encrypt(
            _ plainText: String
        ) -> String? {

            guard let data = plainText.data(using: .utf8),
                  let encryptedData = crypt(
                        data: data,
                        key: aeskey,
                        operation: CCOperation(kCCEncrypt)
                  ) else {
                return nil
            }

            return encryptedData.base64EncodedString()
        }

        // MARK: - 解密（Base64 String → String）
        static func decrypt(
            _ encryptedBase64: String
        ) -> String? {

            guard let encryptedData = Data(base64Encoded: encryptedBase64),
                  let decryptedData = crypt(
                        data: encryptedData,
                        key: aeskey,
                        operation: CCOperation(kCCDecrypt)
                  ) else {
                return nil
            }

            return String(data: decryptedData, encoding: .utf8)
        }

        // MARK: - Core
        private static func crypt(
            data: Data,
            key: String,
            operation: CCOperation
        ) -> Data? {

            guard let keyData = key.data(using: .utf8) else { return nil }

            let dataLength = data.count
            let outputLength = dataLength + kCCBlockSizeAES128
            var outLength = 0
            var outData = Data(count: outputLength)

            let status = outData.withUnsafeMutableBytes { outBytes -> CCCryptorStatus in
                data.withUnsafeBytes { dataBytes -> CCCryptorStatus in
                    keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in

                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            keyData.count,
                            nil, // ECB 不需要 IV
                            dataBytes.baseAddress,
                            dataLength,
                            outBytes.baseAddress,
                            outputLength,
                            &outLength
                        )
                    }
                }
            }

            guard status == kCCSuccess else { return nil }

            outData.removeSubrange(outLength..<outData.count)
            return outData
        }
}
