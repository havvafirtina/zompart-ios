import SwiftUI
import SBDesignSystem

struct AddVehicleSheetView: View {

  enum Route: Hashable {
    case vinScanner
    case plateScanner
    case manualWizard
  }

  let env: AppEnvironment
  let onVehicleAdded: () -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var path: [Route] = []

  var body: some View {
    NavigationStack(path: $path) {
      VStack {
        methodButton(
          icon: "barcode.viewfinder",
          title: Localized.Garage.scanVIN.localized,
          subtitle: Localized.Garage.scanVINSubtitle.localized
        ) {
          path.append(.vinScanner)
        }

        methodButton(
          icon: "car.rear.and.tire.marks",
          title: Localized.Garage.scanPlate.localized,
          subtitle: Localized.Garage.scanPlateSubtitle.localized
        ) {
          path.append(.plateScanner)
        }

        methodButton(
          icon: "hand.tap.fill",
          title: Localized.Garage.manualEntry.localized,
          subtitle: Localized.Garage.manualEntrySubtitle.localized
        ) {
          path.append(.manualWizard)
        }

        Spacer()
      }
      .sbPadding(.large)
      .background(Color.sbSurfacePrimary)
      .navigationTitle(Localized.Garage.addVehicle.localized)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Localized.Common.cancel.localized) { dismiss() }
        }
      }
      .navigationDestination(for: Route.self) { route in
        switch route {
        case .vinScanner:
          VINScannerView(
            viewModel: VehicleModule.makeVINScannerViewModel(env: env) {
              onVehicleAdded()
              dismiss()
            }
          )
        case .plateScanner:
          PlateScannerView(
            viewModel: VehicleModule.makePlateScannerViewModel(env: env) {
              onVehicleAdded()
              dismiss()
            }
          )
        case .manualWizard:
          ManualWizardCoordinatorView(
            viewModel: VehicleModule.makeManualWizardViewModel(env: env) {
              onVehicleAdded()
              dismiss()
            }
          )
        }
      }
    }
  }

  private func methodButton(
    icon: String,
    title: String,
    subtitle: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(Color.sbAccentPrimary)
          .frame(width: 44)

        VStack(alignment: .leading) {
          Text(title)
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbTextPrimary)

          Text(subtitle)
            .font(.sbBodyRegularSmall)
            .foregroundStyle(Color.sbTextSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.sbBodyRegularSmall)
          .foregroundStyle(Color.sbTextTertiary)
      }
      .sbPadding(.large)
      .background(Color.sbSurfaceSecondary)
      .sbCornerRadius(.default)
      .sbShadow(.soft)
    }
    .buttonStyle(.plain)
  }
}
