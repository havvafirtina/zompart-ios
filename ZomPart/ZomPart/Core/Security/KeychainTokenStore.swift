import Foundation
import Security

protocol TokenPersistence: Sendable {
    func save(accessToken: String, refreshToken: String)
    func loadAccessToken() -> String?
    func loadRefreshToken() -> String?
    func clear()
}

struct KeychainTokenStore: TokenPersistence {

    private let service = "com.zompart.auth"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    func save(accessToken: String, refreshToken: String) {
        set(value: accessToken, for: accessTokenKey)
        set(value: refreshToken, for: refreshTokenKey)
    }

    func loadAccessToken() -> String? {
        get(for: accessTokenKey)
    }

    func loadRefreshToken() -> String? {
        get(for: refreshTokenKey)
    }

    func clear() {
        delete(for: accessTokenKey)
        delete(for: refreshTokenKey)
    }

    private func set(value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func get(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
                    let data = result as? Data,
                    let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
