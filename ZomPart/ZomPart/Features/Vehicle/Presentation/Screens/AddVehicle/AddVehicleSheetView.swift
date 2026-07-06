import SwiftUI
import SBDesignSystem

struct AddVehicleSheetView: View {

    enum Route: Hashable {
        case vinScanner
        case plateScanner
    }

    let env: AppEnvironment
    let onVehicleAdded: (VehicleDomain) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                // VIN recognition is intentionally hidden from the UI (plate is the
                // primary path). The vinScanner route below stays dormant so the
                // flow can be re-enabled by re-adding this entry point.
                methodButton(
                    icon: "car.rear.and.tire.marks",
                    title: Localized.Garage.scanPlate.localized,
                    subtitle: Localized.Garage.scanPlateSubtitle.localized
                ) {
                    path.append(.plateScanner)
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
                        viewModel: VehicleModule.makeVINScannerViewModel(env: env) { vehicle in
                            onVehicleAdded(vehicle)
                            dismiss()
                        }
                    )
                case .plateScanner:
                    PlateScannerView(
                        viewModel: VehicleModule.makePlateScannerViewModel(env: env) { vehicle in
                            onVehicleAdded(vehicle)
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
