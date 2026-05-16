import Foundation

enum Localized {

  enum Common: String, LocalizableContent, CaseIterable {
    case ok = "common.ok"
    case cancel = "common.cancel"
    case retry = "common.retry"
    case next = "common.next"
    case skip = "common.skip"
    case done = "common.done"
    case save = "common.save"
    case delete = "common.delete"
    case confirm = "common.confirm"
  }

  enum Tab: String, LocalizableContent, CaseIterable {
    case scan = "tab.scan"
    case garage = "tab.garage"
    case profile = "tab.profile"
  }

  enum Error: String, LocalizableContent, CaseIterable {
    case network = "error.network"
    case unknown = "error.unknown"
    case tokenExpired = "error.tokenExpired"
  }
}
