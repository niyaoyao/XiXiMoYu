//
//  AESCryptor.swift
//  Eva
//
//  Created by NY on 2025/5/14.
//

import CryptoKit
import Foundation

/// A component for AES-GCM encryption and decryption.
public class AESCryptor {
    
    public enum Error: LocalizedError {
        case invalidKeyLength
        case encryptionFailed(String)
        case decryptionFailed(String)
        case keyDerivationFailed
        case invalidInput
        
        public var errorDescription: String? {
            switch self {
            case .invalidKeyLength:
                return "Key must be 32 bytes for AES-256."
            case .encryptionFailed(let message):
                return "Encryption failed: \(message)"
            case .decryptionFailed(let message):
                return "Decryption failed: \(message)"
            case .keyDerivationFailed:
                return "Failed to derive key from password."
            case .invalidInput:
                return "Invalid input data or parameters."
            }
        }
    }
    
    /// Encrypts a string using AES-GCM with a provided key or password.
    /// - Parameters:
    ///   - message: The string to encrypt.
    ///   - key: A 32-byte key for AES-256 (optional if password is provided).
    ///   - password: A password to derive a key (optional if key is provided).
    /// - Returns: Base64-encoded string containing nonce, ciphertext, and tag.
    public static func encrypt(_ message: String, key: Data? = nil, password: String? = nil) throws -> String {
        guard let data = message.data(using: .utf8) else {
            throw Error.invalidInput
        }
        let encryptedData = try encrypt(data, key: key, password: password)
        return encryptedData.base64EncodedString()
    }
    
    /// Encrypts data using AES-GCM with a provided key or password.
    /// - Parameters:
    ///   - data: The data to encrypt.
    ///   - key: A 32-byte key for AES-256 (optional if password is provided).
    ///   - password: A password to derive a key (optional if key is provided).
    /// - Returns: Data containing nonce, ciphertext, and tag.
    public static func encrypt(_ data: Data, key: Data? = nil, password: String? = nil) throws -> Data {
        let symmetricKey = try getSymmetricKey(key: key, password: password)
        
        do {
            // Encrypt using AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            // Combine nonce, ciphertext, and tag
            return sealedBox.nonce.withUnsafeBytes { nonce in
                sealedBox.ciphertext + sealedBox.tag + Data(nonce)
            }
        } catch {
            throw Error.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypts a Base64-encoded string using AES-GCM with a provided key or password.
    /// - Parameters:
    ///   - encryptedBase64: Base64-encoded string containing nonce, ciphertext, and tag.
    ///   - key: A 32-byte key for AES-256 (optional if password is provided).
    ///   - password: A password to derive a key (optional if key is provided).
    /// - Returns: The decrypted string.
    public static func decrypt(_ encryptedBase64: String, key: Data? = nil, password: String? = nil) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            throw Error.invalidInput
        }
        let decryptedData = try decrypt(encryptedData, key: key, password: password)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw Error.decryptionFailed("Failed to convert decrypted data to string.")
        }
        return decryptedString
    }
    
    public static func decryptString(_ encryptedBase64: String, password: String? = nil) -> String? {
        let keyStr = "com.bear.yao.xi.evaai.aescryptor"
        guard let key = keyStr.data(using: .utf8) else {
            return nil
        }
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            return nil
        }
        do {
            let decryptedData = try decrypt(encryptedData, key: key, password: password)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                return nil
            }
            return decryptedString
        } catch {
            return nil
        }
    }
    
    /// Decrypts data using AES-GCM with a provided key or password.
    /// - Parameters:
    ///   - encryptedData: Data containing nonce, ciphertext, and tag.
    ///   - key: A 32-byte key for AES-256 (optional if password is provided).
    ///   - password: A password to derive a key (optional if key is provided).
    /// - Returns: The decrypted data.
    public static func decrypt(_ encryptedData: Data, key: Data? = nil, password: String? = nil) throws -> Data {
        let symmetricKey = try getSymmetricKey(key: key, password: password)
        
        // Extract nonce (12 bytes), tag (16 bytes), and ciphertext
        let nonceLength = 12
        let tagLength = 16
        guard encryptedData.count > nonceLength + tagLength else {
            throw Error.invalidInput
        }
        
        let nonceData = encryptedData.subdata(in: (encryptedData.count - nonceLength)..<encryptedData.count)
        let tag = encryptedData.subdata(in: (encryptedData.count - nonceLength - tagLength)..<(encryptedData.count - nonceLength))
        let ciphertext = encryptedData.subdata(in: 0..<(encryptedData.count - nonceLength - tagLength))
        
        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            throw Error.decryptionFailed(error.localizedDescription)
        }
    }
    
    /// Generates or derives a symmetric key for AES-256.
    /// - Parameters:
    ///   - key: A provided 32-byte key (optional).
    ///   - password: A password to derive a key (optional).
    /// - Returns: A SymmetricKey for AES-256.
    private static func getSymmetricKey(key: Data?, password: String?) throws -> SymmetricKey {
        if let keyData = key {
            guard keyData.count == 32 else {
                throw Error.invalidKeyLength
            }
            return SymmetricKey(data: keyData)
        } else if let password = password, !password.isEmpty {
            // Derive a 32-byte key from the password using HKDF
            guard let passwordData = password.data(using: .utf8) else {
                throw Error.keyDerivationFailed
            }
            let salt = "AESCryptorSalt".data(using: .utf8)! // Fixed salt for consistency
            let pseudoRandomKey = HMAC<SHA256>.authenticationCode(for: passwordData, using: SymmetricKey(data: salt))
            let derivedKey = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: SymmetricKey(data: Data(pseudoRandomKey)),
                outputByteCount: 32
            )
            return derivedKey
        } else {
            // Generate a random 32-byte key
            return SymmetricKey(size: .bits256)
        }
    }
}

// MARK: - Usage Example
extension AESCryptor {
    public static func example() throws {
        // Example 1: Encrypt and decrypt with a random key
        let message = "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"
        let keyStr = "com.bear.yao.xi.evaai.aescryptor"

        guard let key = keyStr.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }

        print("Key: \(key)")
        let encrypted = try encrypt(message, key: key)
        print("Encrypted (Base64): \(encrypted)")
        // let decrypted = try decrypt("L6L12f/NaDYs00YL1VcVTklE4qFU7r+0R1/iMi1uJDKT5BORJKydI95cH2sEqF03Gp5kBvxScbqYeuDzMzg6NUKx31Xc+/b8HJSRi+xovjWwk/vlYqVzKn5pXQFIVHLLj4gibig=", key: key)
        let decrypted = try decrypt(encrypted, key: key)
        print("Decrypted: \(decrypted)")
        
    }
    
     public static func decryptedKey(encrypted: String) -> String? {
         let string = "\(Bundle.appBundleID)ai.aescryptor"

         guard let key = string.data(using: .utf8) else {
             print("Failed to convert string to data")
             return nil
         }

         let decrypted = try? decrypt(encrypted, key: key)
        
         return decrypted
     }
}

// do {
//    try AESCryptor.example()
// } catch  {
//    print(error)

// }
