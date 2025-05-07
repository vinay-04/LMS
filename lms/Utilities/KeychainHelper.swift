//
//  KeychainHelper.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import Foundation

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    func save(_ data: String, service: String, account: String) {
        let data = data.data(using: .utf8)!

        let query =
            [
                kSecValueData: data,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary

        SecItemDelete(query)

        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            print("Error: \(status)")
        }
    }

    func read(service: String, account: String) -> String? {
        let query =
            [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
                kSecReturnData: true,
            ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        guard status == errSecSuccess,
            let data = result as? Data,
            let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return string
    }

    func delete(service: String, account: String) {
        let query =
            [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary

        SecItemDelete(query)
    }
}
