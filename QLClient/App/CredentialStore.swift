import Foundation
import Security

struct StoredCredentials: Codable, Identifiable, Hashable {
  var baseURL: URL
  var clientID: String
  var clientSecret: String
  var token: String
  var expiration: Int

  var id: String {
    "\(baseURL.absoluteString)|\(clientID)"
  }

  var displayName: String {
    baseURL.host ?? baseURL.absoluteString
  }

  var detailText: String {
    clientID
  }
}

private struct CredentialVault: Codable {
  var activeID: String?
  var accounts: [StoredCredentials]
}

final class CredentialStore {
  private let service = "com.blueskycrb.qlclient.credentials"
  private let vaultAccount = "accounts-v2"
  private let legacyAccount = "default"

  func save(_ credentials: StoredCredentials) {
    var vault = loadVault()
    if let index = vault.accounts.firstIndex(where: { $0.id == credentials.id }) {
      vault.accounts[index] = credentials
    } else {
      vault.accounts.append(credentials)
    }
    vault.activeID = credentials.id
    saveVault(vault)
  }

  func load() -> StoredCredentials? {
    let vault = loadVault()
    if let activeID = vault.activeID,
       let active = vault.accounts.first(where: { $0.id == activeID }) {
      return active
    }
    return vault.accounts.first
  }

  func loadAccounts() -> [StoredCredentials] {
    loadVault().accounts
  }

  func setActiveAccount(id: String) -> StoredCredentials? {
    var vault = loadVault()
    guard let account = vault.accounts.first(where: { $0.id == id }) else { return nil }
    vault.activeID = id
    saveVault(vault)
    return account
  }

  func deleteAccount(id: String) -> StoredCredentials? {
    var vault = loadVault()
    vault.accounts.removeAll { $0.id == id }
    if vault.activeID == id {
      vault.activeID = vault.accounts.first?.id
    }
    saveVault(vault)
    return load()
  }

  func delete() {
    deleteKeychainItem(account: vaultAccount)
    deleteKeychainItem(account: legacyAccount)
  }

  private func loadVault() -> CredentialVault {
    if let data = readKeychainData(account: vaultAccount),
       let vault = try? JSONDecoder().decode(CredentialVault.self, from: data) {
      return vault
    }

    if let legacy = loadLegacyCredentials() {
      let vault = CredentialVault(activeID: legacy.id, accounts: [legacy])
      saveVault(vault)
      deleteKeychainItem(account: legacyAccount)
      return vault
    }

    return CredentialVault(activeID: nil, accounts: [])
  }

  private func saveVault(_ vault: CredentialVault) {
    guard let data = try? JSONEncoder().encode(vault) else { return }
    deleteKeychainItem(account: vaultAccount)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: vaultAccount,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    SecItemAdd(query as CFDictionary, nil)
  }

  private func loadLegacyCredentials() -> StoredCredentials? {
    guard let data = readKeychainData(account: legacyAccount) else { return nil }
    return try? JSONDecoder().decode(StoredCredentials.self, from: data)
  }

  private func readKeychainData(account: String) -> Data? {
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
    return data
  }

  private func deleteKeychainItem(account: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    SecItemDelete(query as CFDictionary)
  }
}
