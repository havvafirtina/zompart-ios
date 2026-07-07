import Foundation

/// Owns the ViewModels used by tab roots and navigation destinations.
///
/// SwiftUI re-evaluates `navigationDestination` closures (and tab content)
/// on any ancestor state change — theme, tab badge, auth animation. Creating
/// a ViewModel inline there produces a fresh instance per evaluation, losing
/// in-flight user state (photos, OTP progress, running tasks). This cache
/// hands back the same instance until the owning flow is explicitly
/// invalidated. Deliberately not @Observable: filling the cache during body
/// evaluation must not invalidate views.
@MainActor
final class ViewModelCache {

    private var historyListVMs: [String: HistoryListViewModel] = [:]
    private var scanDetailVMs: [String: ScanDetailViewModel] = [:]
    private var offersListVMs: [String: OffersListViewModel] = [:]
    private var scanInputVMs: [String: ScanInputViewModel] = [:]
    private var scanProcessingVMs: [String: ScanProcessingViewModel] = [:]
    private var disambiguationVMs: [String: DisambiguationViewModel] = [:]
    private var scanFailedVMs: [String: ScanFailedViewModel] = [:]
    private var scanHomeVMInstance: ScanHomeViewModel?
    private var garageListVMInstance: GarageListViewModel?
    private var profileMainVMInstance: ProfileMainViewModel?
    private var deleteAccountVMInstance: DeleteAccountViewModel?

    // MARK: - Tab roots

    func scanHomeVM(env: AppEnvironment) -> ScanHomeViewModel {
        if let existing = scanHomeVMInstance { return existing }
        let vm = ScanModule.makeScanHomeViewModel(
            env: env,
            vehicleRepository: VehicleModule.makeVehicleRepository(httpClient: env.httpClient)
        )
        scanHomeVMInstance = vm
        return vm
    }

    func garageListVM(env: AppEnvironment) -> GarageListViewModel {
        if let existing = garageListVMInstance { return existing }
        let vm = VehicleModule.makeGarageListViewModel(env: env)
        garageListVMInstance = vm
        return vm
    }

    func profileMainVM(env: AppEnvironment, authStateManager: AuthStateManager) -> ProfileMainViewModel {
        if let existing = profileMainVMInstance { return existing }
        let vm = ProfileModule.makeProfileMainViewModel(
            authRepository: AuthModule.makeAuthRepository(httpClient: env.httpClient),
            authStateManager: authStateManager
        )
        profileMainVMInstance = vm
        return vm
    }

    // MARK: - Scan flow destinations

    func scanInputVM(
        env: AppEnvironment,
        mode: ScanInputMode,
        vehicleId: String,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) -> ScanInputViewModel {
        let key = "\(mode)-\(vehicleId)"
        if let existing = scanInputVMs[key] { return existing }
        let vm = ScanModule.makeScanInputViewModel(
            env: env,
            mode: mode,
            vehicleId: vehicleId,
            onScanCreated: onScanCreated
        )
        scanInputVMs[key] = vm
        return vm
    }

    func scanProcessingVM(
        env: AppEnvironment,
        scanId: String,
        onResult: @escaping (ScanProcessResultDomain) -> Void
    ) -> ScanProcessingViewModel {
        if let existing = scanProcessingVMs[scanId] { return existing }
        let vm = ScanModule.makeScanProcessingViewModel(env: env, scanId: scanId, onResult: onResult)
        scanProcessingVMs[scanId] = vm
        return vm
    }

    func disambiguationVM(
        env: AppEnvironment,
        scanId: String,
        kind: DisambiguationKindDomain,
        reason: String?,
        alternatives: [ScanAlternativeDomain],
        questions: [ScanQuestionDomain],
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) -> DisambiguationViewModel {
        if let existing = disambiguationVMs[scanId] { return existing }
        let vm = ScanModule.makeDisambiguationViewModel(
            env: env,
            scanId: scanId,
            kind: kind,
            reason: reason,
            alternatives: alternatives,
            questions: questions,
            onResolved: onResolved
        )
        disambiguationVMs[scanId] = vm
        return vm
    }

    func scanFailedVM(
        env: AppEnvironment,
        scanId: String,
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) -> ScanFailedViewModel {
        if let existing = scanFailedVMs[scanId] { return existing }
        let vm = ScanModule.makeScanFailedViewModel(env: env, scanId: scanId, onResolved: onResolved)
        scanFailedVMs[scanId] = vm
        return vm
    }

    // MARK: - History / Offers destinations

    func historyListVM(env: AppEnvironment, vehicleId: String? = nil) -> HistoryListViewModel {
        let key = vehicleId ?? "all"
        if let existing = historyListVMs[key] { return existing }
        let vm = HistoryModule.makeHistoryListViewModel(env: env, vehicleId: vehicleId)
        historyListVMs[key] = vm
        return vm
    }

    func scanDetailVM(env: AppEnvironment, scanId: String) -> ScanDetailViewModel {
        if let existing = scanDetailVMs[scanId] { return existing }
        let vm = HistoryModule.makeScanDetailViewModel(env: env, scanId: scanId)
        scanDetailVMs[scanId] = vm
        return vm
    }

    func offersListVM(env: AppEnvironment, scanId: String) -> OffersListViewModel {
        if let existing = offersListVMs[scanId] { return existing }
        let vm = OfferModule.makeOffersListViewModel(env: env, scanId: scanId)
        offersListVMs[scanId] = vm
        return vm
    }

    // MARK: - Profile destinations

    func deleteAccountVM(env: AppEnvironment, authStateManager: AuthStateManager) -> DeleteAccountViewModel {
        if let existing = deleteAccountVMInstance { return existing }
        let vm = ProfileModule.makeDeleteAccountViewModel(
            authRepository: AuthModule.makeAuthRepository(httpClient: env.httpClient),
            authStateManager: authStateManager
        )
        deleteAccountVMInstance = vm
        return vm
    }

    // MARK: - Invalidation

    func invalidateHistory() {
        historyListVMs.removeAll()
        scanDetailVMs.removeAll()
        offersListVMs.removeAll()
    }

    func invalidateScanDetail(scanId: String) {
        scanDetailVMs.removeValue(forKey: scanId)
        offersListVMs.removeValue(forKey: scanId)
    }

    /// Called when the scan navigation stack is popped to root: the next
    /// scan is a new session, so input/processing/selection state is stale.
    func invalidateScanFlow() {
        scanInputVMs.removeAll()
        scanProcessingVMs.removeAll()
        disambiguationVMs.removeAll()
        scanFailedVMs.removeAll()
    }

    func invalidateScanProcessing() {
        scanProcessingVMs.removeAll()
    }

    func invalidateDeleteAccount() {
        deleteAccountVMInstance = nil
    }
}
