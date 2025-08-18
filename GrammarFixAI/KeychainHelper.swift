//
//  KeychainHelper.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 17/08/25.
//

import Foundation
import Security

final class KeychainHelper {
    private let group = "com.lancy.grammarfixai"
    static let shared = KeychainHelper()
    private init() {}
    
    // Save to Keychain
    func save(service: String, account: String, data: Data) {
        // Delete existing item first
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccessGroup as String   : group,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
        
        // Add new keychain item
        let attributes: [String: Any] = [
            kSecClass as String             : kSecClassGenericPassword,
            kSecAttrAccessGroup as String   : group,
            kSecAttrService as String       : service,
            kSecAttrAccount as String       : account,
            kSecValueData as String         : data
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                print("Keychain save failed: \(errorMessage)")
            } else {
                print("Keychain save failed with status code: \(status)")
            }
        } else {
            print("✅ Keychain save succeeded")
        }
    }
    
    // Retrieve from Keychain
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String             : kSecClassGenericPassword,
            kSecAttrAccessGroup as String   : group,
            kSecAttrService as String       : service,
            kSecAttrAccount as String       : account,
            kSecReturnData as String        : true,
            kSecMatchLimit as String        : kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }
    
    // Delete from Keychain
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String             : kSecClassGenericPassword,
            kSecAttrAccessGroup as String   : group,
            kSecAttrService as String       : service,
            kSecAttrAccount as String       : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
