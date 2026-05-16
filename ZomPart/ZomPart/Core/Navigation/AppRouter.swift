import SwiftUI

@Observable
@MainActor
final class AppRouter {

  enum Tab: Int, Hashable, CaseIterable {
    case scan
    case garage
    case profile
  }

  enum ScanRoute: Hashable {
    case scanInput(vehicleId: String)
    case scanProcessing(scanId: String)
    case scanResult(scanId: String)
    case offers(scanId: String)
  }

  enum GarageRoute: Hashable {
    case vehicleDetail(vehicleId: String)
  }

  enum ProfileRoute: Hashable {
    case theme
    case language
    case about
    case deleteAccount
  }

  enum SheetType: Identifiable {
    case addVehicle

    var id: String {
      switch self {
      case .addVehicle: "addVehicle"
      }
    }
  }

  var selectedTab: Tab = .scan
  var scanPath: [ScanRoute] = []
  var garagePath: [GarageRoute] = []
  var profilePath: [ProfileRoute] = []
  var activeSheet: SheetType?

  func resetScanFlow() {
    scanPath = []
  }

  func resetAll() {
    scanPath = []
    garagePath = []
    profilePath = []
    activeSheet = nil
    selectedTab = .scan
  }
}
