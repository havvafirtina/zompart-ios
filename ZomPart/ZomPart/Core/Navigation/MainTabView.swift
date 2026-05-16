import SwiftUI
import SBDesignSystem

struct MainTabView: View {

  @Bindable var router: AppRouter
  let env: AppEnvironment
  @State private var garageViewModel: GarageListViewModel?
  @State private var showAddVehicle = false

  var body: some View {
    TabView(selection: $router.selectedTab) {
      NavigationStack(path: $router.scanPath) {
        ScanTabPlaceholderView()
      }
      .tabItem {
        Label(Localized.Tab.scan.localized, systemImage: "viewfinder")
      }
      .tag(AppRouter.Tab.scan)

      NavigationStack(path: $router.garagePath) {
        garageTab
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
      AddVehicleSheetView(env: env) {
        Task { await garageViewModel?.onVehicleAdded() }
      }
    }
  }

  private var garageTab: some View {
    let vm = garageViewModel ?? {
      let created = VehicleModule.makeGarageListViewModel(env: env)
      Task { @MainActor in garageViewModel = created }
      return created
    }()

    return GarageListView(
      viewModel: vm,
      onAddVehicle: { showAddVehicle = true },
      onVehicleTap: { _ in }
    )
  }
}
