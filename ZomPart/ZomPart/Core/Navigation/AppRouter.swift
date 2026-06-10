import SwiftUI

@Observable
@MainActor
final class AppRouter {

    enum Tab: Int, Hashable {
        case scan
        case garage
        case profile
    }

    enum ScanRoute: Hashable {
        case scanInputPhoto(vehicleId: String)
        case scanInputText(vehicleId: String)
        case scanProcessing(scanId: String)
        case disambiguation(scanId: String, alternatives: [ScanAlternativeDomain], questions: [ScanQuestionDomain])
        case scanResult(scanId: String, part: ScanPartSummaryDomain)
        case scanFailed(scanId: String, reason: String)
        case offers(scanId: String)
        case history
        case scanDetail(scanId: String)
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

    var selectedTab: Tab = .scan
    var scanPath: [ScanRoute] = []
    var garagePath: [GarageRoute] = []
    var profilePath: [ProfileRoute] = []

    func resetScanFlow() {
        scanPath = []
    }

    func resetAll() {
        scanPath = []
        garagePath = []
        profilePath = []
        selectedTab = .scan
    }
}
