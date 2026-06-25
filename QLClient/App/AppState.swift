import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { rawValue }

  var title: String {
    switch self {
    case .system:
      return "跟随系统"
    case .light:
      return "白天模式"
    case .dark:
      return "夜间模式"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system:
      return nil
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }
}

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var session: QingLongSession?
  @Published private(set) var accounts: [StoredCredentials] = []
  @Published var isRestoringSession = true
  @Published var signInError: String?

  private let credentialStore = CredentialStore()

  var api: QingLongAPI? {
    guard let session else { return nil }
    return QingLongAPI(baseURL: session.baseURL, token: session.token)
  }

  init() {
    Task { await restoreSession() }
  }

  func restoreSession() async {
    defer { isRestoringSession = false }
    accounts = credentialStore.loadAccounts()
    guard let stored = credentialStore.load() else { return }
    session = makeSession(from: stored)
  }

  @discardableResult
  func signIn(baseURL: String, clientID: String, clientSecret: String) async -> Bool {
    signInError = nil
    do {
      let normalizedURL = try QingLongAPI.normalizedBaseURL(from: baseURL)
      let client = QingLongAPI(baseURL: normalizedURL)
      let token = try await client.authenticate(clientID: clientID, clientSecret: clientSecret)
      let credentials = StoredCredentials(
        baseURL: normalizedURL,
        clientID: clientID,
        clientSecret: clientSecret,
        token: token.token,
        expiration: token.expiration
      )
      credentialStore.save(credentials)
      accounts = credentialStore.loadAccounts()
      session = makeSession(from: credentials)
      return true
    } catch {
      signInError = error.localizedDescription
      return false
    }
  }

  func refreshToken() async throws {
    guard var stored = credentialStore.load() else { return }
    let client = QingLongAPI(baseURL: stored.baseURL)
    let token = try await client.authenticate(clientID: stored.clientID, clientSecret: stored.clientSecret)
    stored.token = token.token
    stored.expiration = token.expiration
    credentialStore.save(stored)
    accounts = credentialStore.loadAccounts()
    session = makeSession(from: stored)
  }

  func switchAccount(id: String) {
    guard let stored = credentialStore.setActiveAccount(id: id) else { return }
    signInError = nil
    accounts = credentialStore.loadAccounts()
    session = makeSession(from: stored)
  }

  func deleteAccount(id: String) {
    let next = credentialStore.deleteAccount(id: id)
    accounts = credentialStore.loadAccounts()
    if let next {
      session = makeSession(from: next)
    } else {
      session = nil
    }
  }

  func signOut() {
    if let session {
      deleteAccount(id: session.accountID)
    } else {
      credentialStore.delete()
      accounts = []
      session = nil
    }
  }

  private func makeSession(from stored: StoredCredentials) -> QingLongSession {
    QingLongSession(
      accountID: stored.id,
      baseURL: stored.baseURL,
      clientID: stored.clientID,
      token: stored.token,
      expiration: stored.expiration
    )
  }
}

struct QingLongSession: Equatable {
  let accountID: String
  let baseURL: URL
  let clientID: String
  let token: String
  let expiration: Int
}
