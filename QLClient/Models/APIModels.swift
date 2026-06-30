import Foundation

struct APIResponse<T: Decodable>: Decodable {
  let code: Int
  let data: T?
  let message: String?
  let logStatus: String?
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

struct ListEnvelope<Item: Decodable>: Decodable {
  let items: [Item]
  let total: Int?

  enum CodingKeys: String, CodingKey {
    case data
    case total
  }

  init(from decoder: Decoder) throws {
    if var container = try? decoder.unkeyedContainer() {
      var values: [Item] = []
      while !container.isAtEnd {
        values.append(try container.decode(Item.self))
      }
      items = values
      total = values.count
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    items = try container.decodeIfPresent([Item].self, forKey: .data) ?? []
    total = try container.decodeIfPresent(Int.self, forKey: .total)
  }
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
  let createdAt: String?
  let lastRunningTime: Int?
  let lastExecutionTime: Int?

  var title: String {
    if let name, !name.isEmpty { return name }
    return command
  }

  var isEnabled: Bool { isDisabled != 1 }
  var isRunning: Bool { status == 0 }
  var isPinnedOnTop: Bool { isPinned == 1 }

  enum CodingKeys: String, CodingKey {
    case id, name, command, schedule, status, labels, createdAt
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
    createdAt: String?,
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
    self.createdAt = createdAt
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
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    lastRunningTime = try container.decodeIfPresent(Int.self, forKey: .lastRunningTime)
    lastExecutionTime = try container.decodeIfPresent(Int.self, forKey: .lastExecutionTime)
  }
}

struct CronPayload: Encodable {
  let id: Int?
  let name: String?
  let command: String
  let schedule: String
  let labels: [String]?
  let extraSchedules: [String]?
  let taskBefore: String?
  let taskAfter: String?
  let allowMultipleInstances: Int?
  let workDir: String?

  enum CodingKeys: String, CodingKey {
    case id, name, command, schedule, labels
    case extraSchedules = "extra_schedules"
    case taskBefore = "task_before"
    case taskAfter = "task_after"
    case allowMultipleInstances = "allow_multiple_instances"
    case workDir = "work_dir"
  }
}

struct CronLog: Equatable {
  let content: String
  let status: String?
}

struct CronLogFile: Identifiable, Decodable, Hashable {
  let filename: String
  let directory: String
  let time: Double?

  var id: String { "\(directory)/\(filename)" }
  var displayTime: String {
    guard let time else { return "-" }
    let date = Date(timeIntervalSince1970: time / 1000)
    return date.formatted(date: .abbreviated, time: .shortened)
  }
}

struct EnvItem: Identifiable, Decodable, Hashable {
  let id: Int
  let name: String
  let value: String
  let remarks: String?
  let status: Int?
  let isPinned: Int?
  let position: Double?
  let labels: [String]?

  var isEnabled: Bool { status != 1 }
  var isPinnedOnTop: Bool { isPinned == 1 }

  enum CodingKeys: String, CodingKey {
    case id, name, value, remarks, status, labels, isPinned, position
  }

  init(
    id: Int,
    name: String,
    value: String,
    remarks: String?,
    status: Int?,
    isPinned: Int?,
    position: Double?,
    labels: [String]?
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.remarks = remarks
    self.status = status
    self.isPinned = isPinned
    self.position = position
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
    position = try container.decodeFlexibleDoubleIfPresent(forKey: .position)
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

struct ScriptUpdatePayload: Encodable {
  let filename: String
  let path: String
  let content: String
}

struct ScriptRunPayload: Encodable {
  let filename: String
  let path: String
  let content: String
}

struct ScriptStopPayload: Encodable {
  let filename: String
  let path: String
  let pid: Int?
}

struct ScriptDeletePayload: Encodable {
  let filename: String
  let path: String
  let type: String
}

struct CommandRunPayload: Encodable {
  let command: String
}

struct CommandStopPayload: Encodable {
  let command: String?
  let pid: Int?
}

struct FlexibleIntValue: Decodable {
  let value: Int

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(Int.self) {
      self.value = value
    } else if let value = try? container.decode(Double.self) {
      self.value = Int(value)
    } else if let value = try? container.decode(String.self), let intValue = Int(value) {
      self.value = intValue
    } else {
      throw DecodingError.typeMismatch(
        Int.self,
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected an integer pid")
      )
    }
  }
}

struct ScriptFile: Identifiable, Decodable, Hashable {
  let title: String
  let key: String
  let type: ScriptFileType
  let parent: String
  let createTime: Int?
  let size: Int?
  let children: [ScriptFile]?

  var id: String { key.isEmpty ? title : key }
  var isDirectory: Bool { type == .directory }
  var displaySize: String {
    guard let size else { return "-" }
    return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
  }

  enum CodingKeys: String, CodingKey {
    case title, key, type, parent, createTime, size, children
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    key = try container.decodeIfPresent(String.self, forKey: .key) ?? title
    type = try container.decodeIfPresent(ScriptFileType.self, forKey: .type) ?? .file
    parent = try container.decodeIfPresent(String.self, forKey: .parent) ?? ""
    createTime = try container.decodeFlexibleIntIfPresent(forKey: .createTime)
    size = try container.decodeFlexibleIntIfPresent(forKey: .size)
    children = try container.decodeIfPresent([ScriptFile].self, forKey: .children)
  }
}

enum ScriptFileType: String, Decodable, Hashable {
  case directory
  case file
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

  func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
    if let value = try? decodeIfPresent(Int.self, forKey: key) {
      return value
    }
    if let value = try? decodeIfPresent(Double.self, forKey: key) {
      return Int(value)
    }
    if let value = try? decodeIfPresent(String.self, forKey: key) {
      return Int(value)
    }
    return nil
  }

  func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
    if let value = try? decodeIfPresent(Double.self, forKey: key) {
      return value
    }
    if let value = try? decodeIfPresent(Int.self, forKey: key) {
      return Double(value)
    }
    if let value = try? decodeIfPresent(String.self, forKey: key) {
      return Double(value)
    }
    return nil
  }
}
