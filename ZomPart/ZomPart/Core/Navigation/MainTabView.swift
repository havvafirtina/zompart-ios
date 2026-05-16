import SwiftUI
import SBDesignSystem

struct MainTabView: View {

  @Bindable var router: AppRouter
  let env: AppEnvironment

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
        GarageTabPlaceholderView()
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
  }
}
