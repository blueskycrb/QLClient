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
    guard let stored = credentialStore.load() else { return }
    session = QingLongSession(
      baseURL: stored.baseURL,
      clientID: stored.clientID,
      token: stored.token,
      expiration: stored.expiration
    )
  }

  func signIn(baseURL: String, clientID: String, clientSecret: String) async {
    signInError = nil
    do {
      let normalizedURL = try QingLongAPI.normalizedBaseURL(from: baseURL)
      let client = QingLongAPI(baseURL: normalizedURL)
      let token = try await client.authenticate(clientID: clientID, clientSecret: clientSecret)
      let newSession = QingLongSession(
        baseURL: normalizedURL,
        clientID: clientID,
        token: token.token,
        expiration: token.expiration
      )
      credentialStore.save(
        StoredCredentials(
          baseURL: normalizedURL,
          clientID: clientID,
          clientSecret: clientSecret,
          token: token.token,
          expiration: token.expiration
        )
      )
      session = newSession
    } catch {
      signInError = error.localizedDescription
    }
  }

  func refreshToken() async throws {
    guard var stored = credentialStore.load() else { return }
    let client = QingLongAPI(baseURL: stored.baseURL)
    let token = try await client.authenticate(clientID: stored.clientID, clientSecret: stored.clientSecret)
    stored.token = token.token
    stored.expiration = token.expiration
    credentialStore.save(stored)
    session = QingLongSession(
      baseURL: stored.baseURL,
      clientID: stored.clientID,
      token: token.token,
      expiration: token.expiration
    )
  }

  func signOut() {
    credentialStore.delete()
    session = nil
  }
}

struct QingLongSession: Equatable {
  let baseURL: URL
  let clientID: String
  let token: String
  let expiration: Int
}
