import SwiftUI
import SBDesignSystem

struct VehicleDetailView: View {

    let vehicle: VehicleDomain
    let historyViewModel: HistoryListViewModel
    let onScanTap: (String) -> Void
    let onStartScan: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                vehicleInfoCard
                scanHistorySection
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle("\(vehicle.make) \(vehicle.model)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onStartScan()
                } label: {
                    Image(systemName: "viewfinder")
                }
            }
        }
    }

    private var vehicleInfoCard: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(Color.sbAccentPrimary)

                VStack(alignment: .leading) {
                    Text("\(vehicle.year ?? 0) \(vehicle.make) \(vehicle.model)")
                        .font(.sbTitleSemiboldLarge)
                        .foregroundStyle(Color.sbTextPrimary)

                    if let trim = vehicle.trim {
                        Text(trim)
                            .font(.sbBodyRegularSmall)
                            .foregroundStyle(Color.sbTextSecondary)
                    }
                }
            }

            if let vin = vehicle.vin, !vin.isEmpty {
                detailRow(label: "VIN", value: vin)
            }

            if let plate = vehicle.plate, !plate.isEmpty {
                detailRow(label: Localized.Garage.scanPlate.localized, value: plate)
            }

            if let engine = vehicle.engineCode, !engine.isEmpty {
                detailRow(label: Localized.Garage.selectEngine.localized, value: engine)
            }
        }
        .sbPadding(.large)
        .background(Color.sbSurfaceSecondary)
        .sbCornerRadius(.default)
        .sbShadow(.soft)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextTertiary)
            Spacer()
            Text(value)
                .font(.sbBodyMediumSmall)
                .foregroundStyle(Color.sbTextPrimary)
        }
        .sbVerticalPadding(.small)
    }

    private var scanHistorySection: some View {
        VStack(alignment: .leading) {
            Text(Localized.History.title.localizedKey)
                .font(.sbBodyMediumDefault)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.medium)

            switch historyViewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .sbVerticalPadding(.large)

            case .empty:
                Text(Localized.History.empty.localizedKey)
                    .font(.sbBodyRegularDefault)
                    .foregroundStyle(Color.sbTextSecondary)
                    .frame(maxWidth: .infinity)
                    .sbVerticalPadding(.large)

            case .loaded:
                ForEach(historyViewModel.scans, id: \.id) { scan in
                    HistoryScanRowView(scan: scan) {
                        onScanTap(scan.id)
                    }
                }

            case .error:
                Button(Localized.Common.retry.localized) {
                    Task { await historyViewModel.loadInitial() }
                }
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(Color.sbAccentPrimary)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
