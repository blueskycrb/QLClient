import Foundation

struct APIResponse<T: Decodable>: Decodable {
  let code: Int
  let data: T?
  let message: String?
  let logStatus: Int?
}

struct EmptyRequestBody: Encodable {}

struct IgnoredPayload: Decodable {
  init(from decoder: Decoder) throws {}
}

struct TokenInfo: Decodable {
  let token: String
  let tokenType: String?
  let expiration: Int

  enum CodingKeys: String, CodingKey {
    case token
    case tokenType = "token_type"
    case expiration
  }
}

struct SystemInfo: Decodable {
  let isInitialized: Bool?
  let version: String?
  let branch: String?
  let publishTime: Int?
  let changeLog: String?
  let changeLogLink: String?
}

struct DashboardOverview: Decodable {
  let total: Int?
  let enabled: Int?
  let disabled: Int?
  let todayRuns: Int?
  let todaySuccess: Int?
  let todayFail: Int?
  let successRate: String?
  let avgTime: Int?
}

struct CronItem: Identifiable, Decodable, Hashable {
  let id: Int
  let name: String?
  let command: String
  let schedule: String?
  let status: Int?
  let isDisabled: Int?
  let isPinned: Int?
  let labels: [String]?
  let lastRunningTime: Int?
  let lastExecutionTime: Int?

  var title: String {
    if let name, !name.isEmpty { return name }
    return command
  }

  var isEnabled: Bool { isDisabled != 1 }
  var isRunning: Bool { status == 0 }

  enum CodingKeys: String, CodingKey {
    case id, name, command, schedule, status, labels
    case isDisabled, isPinned
    case lastRunningTime = "last_running_time"
    case lastExecutionTime = "last_execution_time"
  }

  init(
    id: Int,
    name: String?,
    command: String,
    schedule: String?,
    status: Int?,
    isDisabled: Int?,
    isPinned: Int?,
    labels: [String]?,
    lastRunningTime: Int?,
    lastExecutionTime: Int?
  ) {
    self.id = id
    self.name = name
    self.command = command
    self.schedule = schedule
    self.status = status
    self.isDisabled = isDisabled
    self.isPinned = isPinned
    self.labels = labels
    self.lastRunningTime = lastRunningTime
    self.lastExecutionTime = lastExecutionTime
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    command = try container.decodeIfPresent(String.self, forKey: .command) ?? ""
    schedule = try container.decodeIfPresent(String.self, forKey: .schedule)
    status = try container.decodeIfPresent(Int.self, forKey: .status)
    isDisabled = try container.decodeIfPresent(Int.self, forKey: .isDisabled)
    isPinned = try container.decodeIfPresent(Int.self, forKey: .isPinned)
    labels = try container.decodeFlexibleStringArrayIfPresent(forKey: .labels)
    lastRunningTime = try container.decodeIfPresent(Int.self, forKey: .lastRunningTime)
    lastExecutionTime = try container.decodeIfPresent(Int.self, forKey: .lastExecutionTime)
  }
}

struct CronLog: Equatable {
  let content: String
  let status: Int?
}

struct EnvItem: Identifiable, Decodable, Hashable {
  let id: Int
  let name: String
  let value: String
  let remarks: String?
  let status: Int?
  let isPinned: Int?
  let labels: [String]?

  var isEnabled: Bool { status != 1 }

  enum CodingKeys: String, CodingKey {
    case id, name, value, remarks, status, labels, isPinned
  }

  init(
    id: Int,
    name: String,
    value: String,
    remarks: String?,
    status: Int?,
    isPinned: Int?,
    labels: [String]?
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.remarks = remarks
    self.status = status
    self.isPinned = isPinned
    self.labels = labels
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
    remarks = try container.decodeIfPresent(String.self, forKey: .remarks)
    status = try container.decodeIfPresent(Int.self, forKey: .status)
    isPinned = try container.decodeIfPresent(Int.self, forKey: .isPinned)
    labels = try container.decodeFlexibleStringArrayIfPresent(forKey: .labels)
  }
}

struct EnvPayload: Encodable {
  let name: String
  let value: String
  let remarks: String
  let labels: [String]
}

struct EnvUpdatePayload: Encodable {
  let id: Int
  let name: String
  let value: String
  let remarks: String
  let labels: [String]?
}

private extension KeyedDecodingContainer {
  func decodeFlexibleStringArrayIfPresent(forKey key: Key) throws -> [String]? {
    if let values = try? decodeIfPresent([String].self, forKey: key) {
      return values
    }
    if let rawValue = try? decodeIfPresent(String.self, forKey: key),
       let data = rawValue.data(using: .utf8),
       let values = try? JSONDecoder().decode([String].self, from: data) {
      return values
    }
    return nil
  }
}
