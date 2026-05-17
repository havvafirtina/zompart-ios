import SwiftUI
import SBDesignSystem

struct MainTabView: View {

    @Bindable var router: AppRouter
    let env: AppEnvironment
    @State private var garageViewModel: GarageListViewModel?
    @State private var scanHomeViewModel: ScanHomeViewModel?
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
                ProfileTabPlaceholderView()
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
                    await garageViewModel?.onVehicleAdded(vehicleId: vehicleId)
                    await scanHomeViewModel?.loadVehicles()
                }
            }
        }
    }

    // MARK: - Scan Tab

    private var scanTab: some View {
        let vm = scanHomeViewModel ?? {
            let created = ScanModule.makeScanHomeViewModel(env: env)
            Task { @MainActor in scanHomeViewModel = created }
            return created
        }()

        return ScanHomeView(
            viewModel: vm,
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
                viewModel: ScanModule.makeScanInputViewModel(
                    env: env,
                    vehicleId: vehicleId
                ) { scan in
                    router.scanPath.append(.scanProcessing(scanId: scan.scanId))
                }
            )

        case .scanInputText(let vehicleId):
            ScanInputView(
                viewModel: ScanModule.makeScanInputViewModel(
                    env: env,
                    vehicleId: vehicleId
                ) { scan in
                    router.scanPath.append(.scanProcessing(scanId: scan.scanId))
                }
            )

        case .scanProcessing(let scanId):
            ScanProcessingView(
                viewModel: ScanModule.makeScanProcessingViewModel(
                    env: env,
                    scanId: scanId
                ) { result in
                    handleProcessResult(result)
                }
            )

        case .scanResult(let scanId, let partName, let partNumber):
            ScanResultView(
                partName: partName,
                partNumber: partNumber,
                onViewOffers: {
                    router.scanPath.append(.offers(scanId: scanId))
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

        switch result {
        case .offersReady(let scanId, let part):
            router.scanPath.append(.scanResult(scanId: scanId, partName: part.name, partNumber: part.partNumber))

        case .disambiguation(let scanId, let alternatives, _):
            router.scanPath.append(.scanProcessing(scanId: scanId))
            _ = alternatives

        case .failed(_, _):
            break
        }
    }

    // MARK: - Garage Tab

    private var garageTab: some View {
        let vm = garageViewModel ?? {
            let created = VehicleModule.makeGarageListViewModel(env: env)
            Task { @MainActor in garageViewModel = created }
            return created
        }()

        return GarageListView(
            viewModel: vm,
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
            if let vehicle = garageViewModel?.vehicles.first(where: { $0.id == vehicleId }) {
                VehicleDetailView(
                    vehicle: vehicle,
                    historyViewModel: HistoryModule.makeHistoryListViewModel(env: env, vehicleId: vehicleId),
                    onScanTap: { scanId in
                        router.selectedTab = .scan
                        router.scanPath = [.scanDetail(scanId: scanId)]
                    },
                    onStartScan: {
                        router.selectedTab = .scan
                    }
                )
            }
        }
    }
}
