import SwiftUI
import SBDesignSystem

struct MainTabView: View {

    @Bindable var router: AppRouter
    let env: AppEnvironment
    let authStateManager: AuthStateManager
    let themeManager: ThemeManager
    @State private var showAddVehicle = false
    @State private var vmCache = ViewModelCache()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.scanPath) {
                scanTab
                    .navigationDestination(for: AppRouter.ScanRoute.self) { route in
                        scanDestination(for: route)
                    }
            }
            .tabItem {
                Label(Localized.Tab.scan.localized, systemImage: "viewfinder")
            }
            .tag(AppRouter.Tab.scan)

            NavigationStack(path: $router.garagePath) {
                garageTab
                    .navigationDestination(for: AppRouter.GarageRoute.self) { route in
                        garageDestination(for: route)
                    }
            }
            .tabItem {
                Label(Localized.Tab.garage.localized, systemImage: "car.fill")
            }
            .tag(AppRouter.Tab.garage)

            NavigationStack(path: $router.profilePath) {
                profileTab
                    .navigationDestination(for: AppRouter.ProfileRoute.self) { route in
                        profileDestination(for: route)
                    }
            }
            .tabItem {
                Label(Localized.Tab.profile.localized, systemImage: "person.fill")
            }
            .tag(AppRouter.Tab.profile)
        }
        .tint(Color.sbAccentPrimary)
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleSheetView(env: env) { vehicleId in
                Task {
                    await vmCache.garageListVM(env: env).onVehicleAdded(vehicleId: vehicleId)
                    await vmCache.scanHomeVM(env: env).loadVehicles()
                }
            }
        }
        .onChange(of: router.scanPath) { _, newValue in
            if newValue.isEmpty { vmCache.invalidateScanFlow() }
        }
        .onChange(of: router.profilePath) { _, newValue in
            if newValue.isEmpty { vmCache.invalidateDeleteAccount() }
        }
    }

    // MARK: - Scan Tab

    private var scanTab: some View {
        ScanHomeView(
            viewModel: vmCache.scanHomeVM(env: env),
            onStartPhotoScan: { vehicle in
                router.scanPath.append(.scanInputPhoto(vehicleId: vehicle.id))
            },
            onStartTextScan: { vehicle in
                router.scanPath.append(.scanInputText(vehicleId: vehicle.id))
            },
            onAddVehicle: { showAddVehicle = true },
            onHistory: {
                router.scanPath.append(.history)
            }
        )
    }

    @ViewBuilder
    private func scanDestination(for route: AppRouter.ScanRoute) -> some View {
        switch route {
        case .scanInputPhoto(let vehicleId):
            ScanInputView(
                viewModel: vmCache.scanInputVM(
                    env: env,
                    mode: .photo,
                    vehicleId: vehicleId
                ) { scan in
                    router.scanPath.append(.scanProcessing(scanId: scan.scanId))
                }
            )

        case .scanInputText(let vehicleId):
            ScanInputView(
                viewModel: vmCache.scanInputVM(
                    env: env,
                    mode: .text,
                    vehicleId: vehicleId
                ) { scan in
                    router.scanPath.append(.scanProcessing(scanId: scan.scanId))
                }
            )

        case .scanProcessing(let scanId):
            ScanProcessingView(
                viewModel: vmCache.scanProcessingVM(
                    env: env,
                    scanId: scanId
                ) { result in
                    handleProcessResult(result)
                },
                onCancel: {
                    router.resetScanFlow()
                }
            )

        case .disambiguation(let scanId, let alternatives, let questions):
            DisambiguationView(
                viewModel: vmCache.disambiguationVM(
                    env: env,
                    scanId: scanId,
                    alternatives: alternatives,
                    questions: questions
                ) { feedback in
                    // Selecting a part changes the scan's part and offers —
                    // evict the cached detail/offers VMs so they reload.
                    vmCache.invalidateScanDetail(scanId: scanId)
                    if feedback.nextAction == .showOffers {
                        router.scanPath.append(.offers(scanId: scanId))
                    }
                }
            )

        case .scanResult(let scanId, let part):
            ScanResultView(
                part: part,
                onViewOffers: {
                    router.scanPath.append(.offers(scanId: scanId))
                },
                onGoHome: {
                    router.resetScanFlow()
                }
            )

        case .scanFailed(_, let reason):
            ScanFailedView(
                reason: reason,
                onRetry: {
                    while let last = router.scanPath.last {
                        switch last {
                        case .scanInputPhoto, .scanInputText:
                            return
                        default:
                            router.scanPath.removeLast()
                        }
                    }
                },
                onTextSearch: {
                    let vehicleId = router.scanPath.lazy.compactMap { route -> String? in
                        switch route {
                        case .scanInputPhoto(let v), .scanInputText(let v): return v
                        default: return nil
                        }
                    }.first
                    if let vehicleId {
                        router.scanPath = [.scanInputText(vehicleId: vehicleId)]
                    } else {
                        router.scanPath = []
                    }
                },
                onGoHome: {
                    router.resetScanFlow()
                }
            )

        case .offers(let scanId):
            OffersListView(
                viewModel: vmCache.offersListVM(env: env, scanId: scanId)
            )

        case .history:
            HistoryListView(
                viewModel: vmCache.historyListVM(env: env),
                onScanTap: { scanId in
                    router.scanPath.append(.scanDetail(scanId: scanId))
                }
            )

        case .scanDetail(let scanId):
            ScanDetailView(
                viewModel: vmCache.scanDetailVM(env: env, scanId: scanId),
                onViewOffers: { id in
                    router.scanPath.append(.offers(scanId: id))
                }
            )
        }
    }

    private func handleProcessResult(_ result: ScanProcessResultDomain) {
        vmCache.invalidateHistory()
        vmCache.invalidateScanProcessing()

        switch result {
        case .offersReady(let scanId, let part):
            if let idx = router.scanPath.lastIndex(where: { if case .scanProcessing = $0 { return true }; return false }) {
                router.scanPath.replaceSubrange(idx..., with: [
                    .scanResult(scanId: scanId, part: part)
                ])
            } else {
                router.scanPath.append(.scanResult(scanId: scanId, part: part))
            }

        case .disambiguation(let scanId, let alternatives, let questions):
            if let idx = router.scanPath.lastIndex(where: { if case .scanProcessing = $0 { return true }; return false }) {
                router.scanPath.replaceSubrange(idx..., with: [
                    .disambiguation(scanId: scanId, alternatives: alternatives, questions: questions)
                ])
            } else {
                router.scanPath.append(.disambiguation(scanId: scanId, alternatives: alternatives, questions: questions))
            }

        case .failed(let scanId, let reason):
            if let idx = router.scanPath.lastIndex(where: { if case .scanProcessing = $0 { return true }; return false }) {
                router.scanPath.replaceSubrange(idx..., with: [
                    .scanFailed(scanId: scanId, reason: reason)
                ])
            } else {
                router.scanPath.append(.scanFailed(scanId: scanId, reason: reason))
            }
        }
    }

    // MARK: - Garage Tab

    private var garageTab: some View {
        GarageListView(
            viewModel: vmCache.garageListVM(env: env),
            onAddVehicle: { showAddVehicle = true },
            onVehicleTap: { vehicle in
                router.garagePath.append(.vehicleDetail(vehicleId: vehicle.id))
            }
        )
    }

    @ViewBuilder
    private func garageDestination(for route: AppRouter.GarageRoute) -> some View {
        switch route {
        case .vehicleDetail(let vehicleId):
            vehicleDetailContent(vehicleId: vehicleId)
                .task {
                    let garageVM = vmCache.garageListVM(env: env)
                    if garageVM.vehicles.isEmpty {
                        await garageVM.loadVehicles()
                    }
                }
        }
    }

    @ViewBuilder
    private func vehicleDetailContent(vehicleId: String) -> some View {
        let garageVM = vmCache.garageListVM(env: env)
        if let vehicle = garageVM.vehicles.first(where: { $0.id == vehicleId }) {
            VehicleDetailView(
                vehicle: vehicle,
                historyViewModel: vmCache.historyListVM(env: env, vehicleId: vehicleId),
                onScanTap: { scanId in
                    router.selectedTab = .scan
                    router.scanPath = [.scanDetail(scanId: scanId)]
                },
                onStartScan: {
                    router.selectedTab = .scan
                }
            )
        } else {
            switch garageVM.state {
            case .loading, .idle:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                VStack {
                    Text(message)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextSecondary)
                        .multilineTextAlignment(.center)
                    Button(Localized.Common.retry.localizedKey) {
                        Task { await garageVM.loadVehicles() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sbPadding(.xLarge)
            case .loaded, .empty:
                Text(Localized.Error.vehicleNotFound.localizedKey)
                    .font(.sbBodyRegularDefault)
                    .foregroundStyle(Color.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sbPadding(.xLarge)
            }
        }
    }

    // MARK: - Profile Tab

    private var profileTab: some View {
        ProfileMainView(
            viewModel: vmCache.profileMainVM(env: env, authStateManager: authStateManager),
            themeManager: themeManager,
            onTheme: { router.profilePath.append(.theme) },
            onLanguage: { router.profilePath.append(.language) },
            onAbout: { router.profilePath.append(.about) },
            onDeleteAccount: { router.profilePath.append(.deleteAccount) }
        )
    }

    @ViewBuilder
    private func profileDestination(for route: AppRouter.ProfileRoute) -> some View {
        switch route {
        case .theme:
            ThemePickerView(themeManager: themeManager)
        case .language:
            LanguagePickerView()
        case .about:
            AboutView()
        case .deleteAccount:
            DeleteAccountView(
                viewModel: vmCache.deleteAccountVM(env: env, authStateManager: authStateManager)
            )
        }
    }
}
