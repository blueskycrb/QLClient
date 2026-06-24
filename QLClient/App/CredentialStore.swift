import Foundation
import Security

struct StoredCredentials: Codable {
  var baseURL: URL
  var clientID: String
  var clientSecret: String
  var token: String
  var expiration: Int
}

final class CredentialStore {
  private let service = "com.blueskycrb.qlclient.credentials"
  private let account = "default"

  func save(_ credentials: StoredCredentials) {
    guard let data = try? JSONEncoder().encode(credentials) else { return }
    delete()

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    SecItemAdd(query as CFDictionary, nil)
  }

  func load() -> StoredCredentials? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return try? JSONDecoder().decode(StoredCredentials.self, from: data)
  }

  func delete() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    SecItemDelete(query as CFDictionary)
  }
}
