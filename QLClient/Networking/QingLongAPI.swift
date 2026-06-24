import Foundation

enum QingLongAPIError: LocalizedError {
  case invalidBaseURL
  case missingToken
  case emptyResponse
  case serverMessage(String)
  case unexpectedStatus(Int)

  var errorDescription: String? {
    switch self {
    case .invalidBaseURL:
      return "服务器地址无效"
    case .missingToken:
      return "未登录或 token 已丢失"
    case .emptyResponse:
      return "服务器返回为空"
    case .serverMessage(let message):
      return message
    case .unexpectedStatus(let status):
      return "HTTP \(status)"
    }
  }
}

final class QingLongAPI {
  let baseURL: URL
  private let token: String?
  private let session: URLSession

  init(baseURL: URL, token: String? = nil, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.token = token
    self.session = session
  }

  static func normalizedBaseURL(from rawValue: String) throws -> URL {
    var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.hasSuffix("/") {
      value.removeLast()
    }
    if !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
      value = "http://" + value
    }
    guard let url = URL(string: value), url.scheme != nil, url.host != nil else {
      throw QingLongAPIError.invalidBaseURL
    }
    return url
  }

  func authenticate(clientID: String, clientSecret: String) async throws -> TokenInfo {
    let query = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "client_secret", value: clientSecret)
    ]
    let response: APIResponse<TokenInfo> = try await request(
      "open/auth/token",
      method: "GET",
      queryItems: query,
      requiresToken: false
    )
    guard let data = response.data else { throw QingLongAPIError.emptyResponse }
    return data
  }

  func systemInfo() async throws -> SystemInfo {
    try await dataRequest("open/system")
  }

  func dashboardOverview() async throws -> DashboardOverview {
    try await dataRequest("open/dashboard/overview")
  }

  func crons(searchText: String = "") async throws -> [CronItem] {
    try await dataRequest(
      "open/crons",
      queryItems: [URLQueryItem(name: "searchValue", value: searchText)]
    )
  }

  func runCron(id: Int) async throws {
    try await emptyRequest("open/crons/run", method: "PUT", body: [id])
  }

  func stopCron(id: Int) async throws {
    try await emptyRequest("open/crons/stop", method: "PUT", body: [id])
  }

  func setCronEnabled(id: Int, enabled: Bool) async throws {
    try await emptyRequest("open/crons/\(enabled ? "enable" : "disable")", method: "PUT", body: [id])
  }

  func cronLog(id: Int) async throws -> CronLog {
    let response: APIResponse<String> = try await request("open/crons/\(id)/log", method: "GET")
    return CronLog(content: response.data ?? "", status: response.logStatus)
  }

  func envs(searchText: String = "") async throws -> [EnvItem] {
    try await dataRequest(
      "open/envs",
      queryItems: [URLQueryItem(name: "searchValue", value: searchText)]
    )
  }

  func createEnv(name: String, value: String, remarks: String) async throws {
    let payload = [EnvPayload(name: name, value: value, remarks: remarks, labels: [])]
    try await emptyRequest("open/envs", method: "POST", body: payload)
  }

  func updateEnv(_ env: EnvItem, value: String, remarks: String) async throws {
    let payload = EnvUpdatePayload(
      id: env.id,
      name: env.name,
      value: value,
      remarks: remarks,
      labels: env.labels
    )
    try await emptyRequest("open/envs", method: "PUT", body: payload)
  }

  func setEnvEnabled(id: Int, enabled: Bool) async throws {
    try await emptyRequest("open/envs/\(enabled ? "enable" : "disable")", method: "PUT", body: [id])
  }

  private func dataRequest<T: Decodable>(
    _ path: String,
    queryItems: [URLQueryItem] = []
  ) async throws -> T {
    let response: APIResponse<T> = try await request(path, method: "GET", queryItems: queryItems)
    guard let data = response.data else { throw QingLongAPIError.emptyResponse }
    return data
  }

  private func emptyRequest<Body: Encodable>(
    _ path: String,
    method: String,
    body: Body
  ) async throws {
    let response: APIResponse<IgnoredPayload> = try await request(path, method: method, body: body)
    if response.code != 200 {
      throw QingLongAPIError.serverMessage(response.message ?? "操作失败")
    }
  }

  private func request<T: Decodable, Body: Encodable>(
    _ path: String,
    method: String,
    queryItems: [URLQueryItem] = [],
    body: Body?,
    requiresToken: Bool = true
  ) async throws -> APIResponse<T> {
    var request = URLRequest(url: makeURL(path: path, queryItems: queryItems))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if requiresToken {
      guard let token else { throw QingLongAPIError.missingToken }
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONEncoder.qingLong.encode(body)
    }

    let (data, urlResponse) = try await session.data(for: request)
    if let http = urlResponse as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
      throw QingLongAPIError.unexpectedStatus(http.statusCode)
    }

    let decoded = try JSONDecoder.qingLong.decode(APIResponse<T>.self, from: data)
    if decoded.code != 200 {
      throw QingLongAPIError.serverMessage(decoded.message ?? "请求失败")
    }
    return decoded
  }

  private func request<T: Decodable>(
    _ path: String,
    method: String,
    queryItems: [URLQueryItem] = [],
    requiresToken: Bool = true
  ) async throws -> APIResponse<T> {
    try await request(
      path,
      method: method,
      queryItems: queryItems,
      body: Optional<EmptyRequestBody>.none,
      requiresToken: requiresToken
    )
  }

  private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let joinedPath = ([basePath, requestPath].filter { !$0.isEmpty }).joined(separator: "/")
    components.path = "/" + joinedPath
    components.queryItems = queryItems.filter { !($0.value ?? "").isEmpty }
    return components.url!
  }
}

private extension JSONDecoder {
  static var qingLong: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return decoder
  }
}

private extension JSONEncoder {
  static var qingLong: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .useDefaultKeys
    return encoder
  }
}
