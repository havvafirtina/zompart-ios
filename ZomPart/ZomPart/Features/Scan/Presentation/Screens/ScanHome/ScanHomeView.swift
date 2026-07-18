import SwiftUI
import SBDesignSystem

struct ScanHomeView: View {

    let viewModel: ScanHomeViewModel
    let onStartPhotoScan: (VehicleDomain) -> Void
    let onStartTextScan: (VehicleDomain) -> Void
    let onAddVehicle: () -> Void
    let onHistory: () -> Void
    @State private var showVehiclePicker = false

    var body: some View {
        Group {
            switch viewModel.vehiclesState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                noVehiclesState

            case .loaded:
                ScrollView {
                    VStack {
                        vehicleSelector
                        scanDescription
                        scanOptions
                    }
                    .sbPadding(.large)
                }

            case .error(let message):
                errorState(message)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Tab.scan.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoSubtitleView()
                    .frame(height: 26)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    onHistory()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .task {
            if viewModel.vehiclesState == .idle {
                await viewModel.loadVehicles()
            }
        }
        .sheet(isPresented: $showVehiclePicker) {
            vehiclePickerSheet
        }
    }

    // MARK: - No Vehicles

    private var noVehiclesState: some View {
        VStack {
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Scan.noVehicles.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.small)

            Text(Localized.Scan.addVehicleFirst.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                onAddVehicle()
            } label: {
                Text(Localized.Garage.addVehicle.localizedKey)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextOnAccent)
                    .sbHorizontalPadding(.xLarge)
                    .sbControlHeight(.regular)
                    .background(Color.sbAccentPrimary)
                    .sbCornerRadius(.default)
            }
            .sbVerticalPadding(.large)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Vehicle Selector

    private var vehicleSelector: some View {
        Button {
            showVehiclePicker = true
        } label: {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color.sbAccentPrimary)

                VStack(alignment: .leading) {
                    Text(Localized.Scan.selectVehicle.localizedKey)
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)

                    if let vehicle = viewModel.selectedVehicle {
                        Text(vehicleTitle(vehicle))
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
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

    // MARK: - Description

    private var scanDescription: some View {
        VStack(alignment: .leading) {
            Text(Localized.Scan.howItWorks.localizedKey)
                .font(.sbBodyMediumDefault)
                .foregroundStyle(Color.sbTextPrimary)

            Text(Localized.Scan.subtitle.localizedKey)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sbVerticalPadding(.large)
    }

    // MARK: - Scan Options

    private var scanOptions: some View {
        VStack(spacing: 16) {
            scanOptionCard(
                icon: "camera.viewfinder",
                title: Localized.Scan.scanWithPhoto.localized,
                subtitle: Localized.Scan.scanWithPhotoSubtitle.localized
            ) {
                guard let vehicle = viewModel.selectedVehicle else { return }
                onStartPhotoScan(vehicle)
            }

            scanOptionCard(
                icon: "text.magnifyingglass",
                title: Localized.Scan.scanWithText.localized,
                subtitle: Localized.Scan.scanWithTextSubtitle.localized
            ) {
                guard let vehicle = viewModel.selectedVehicle else { return }
                onStartTextScan(vehicle)
            }
        }
    }

    private func scanOptionCard(
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
        .disabled(viewModel.selectedVehicle == nil)
    }

    // MARK: - Vehicle Picker Sheet

    private var sheetDetent: PresentationDetent {
        let count = viewModel.vehicles.count
        let rowHeight: CGFloat = 72
        let navBarHeight: CGFloat = 56
        let padding: CGFloat = 32
        let totalHeight = CGFloat(count) * rowHeight + navBarHeight + padding
        let maxFraction = min(totalHeight / UIScreen.main.bounds.height, 0.6)
        return .fraction(max(0.25, maxFraction))
    }

    private var vehiclePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.vehicles, id: \.id) { vehicle in
                    Button {
                        viewModel.selectedVehicle = vehicle
                        showVehiclePicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(vehicleTitle(vehicle))
                                    .font(.sbBodySemiboldDefault)
                                    .foregroundStyle(Color.sbTextPrimary)

                                Text(vehicleSubtitle(vehicle))
                                    .font(.sbBodyRegularSmall)
                                    .foregroundStyle(Color.sbTextSecondary)
                            }

                            Spacer()

                            if viewModel.selectedVehicle?.id == vehicle.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.sbAccentPrimary)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.sbBorderSubtle)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle(Localized.Scan.selectVehicle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localized.Common.cancel.localized) {
                        showVehiclePicker = false
                    }
                }
            }
        }
        .presentationDetents([sheetDetent])
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(message)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button(Localized.Common.retry.localized) {
                Task { await viewModel.loadVehicles() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func vehicleTitle(_ vehicle: VehicleDomain) -> String {
        let year = vehicle.year.map { String($0) } ?? ""
        return [year, vehicle.make.displayCased, vehicle.model.displayCased]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func vehicleSubtitle(_ vehicle: VehicleDomain) -> String {
        if let plate = vehicle.plate, !plate.isEmpty {
            return plate
        } else if let vin = vehicle.vin, !vin.isEmpty {
            return vin
        }
        return vehicle.resolveMethod.rawValue
    }
}
