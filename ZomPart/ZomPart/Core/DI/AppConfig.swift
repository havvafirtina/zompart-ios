import Foundation

struct AppConfig: Sendable {

  enum Environment: String, Sendable {
    case debug
    case release
    case local
  }

  let environment: Environment

  static func current() -> AppConfig {
    let envString: String = PlistReader.value(for: "APP_ENV")
    let env = Environment(rawValue: envString.lowercased()) ?? .debug
    return AppConfig(environment: env)
  }
}
