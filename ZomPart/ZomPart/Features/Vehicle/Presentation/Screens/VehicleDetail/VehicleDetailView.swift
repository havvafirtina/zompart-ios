import SwiftUI
import SBDesignSystem

struct VehicleDetailView: View {

    let env: AppEnvironment
    let vehicle: VehicleDomain
    let historyViewModel: HistoryListViewModel
    let onScanTap: (String) -> Void
    let onStartScan: () -> Void
    @State private var showCatalog = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                vehicleInfoCard
                browseCatalogButton
                scanHistorySection
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .sheet(isPresented: $showCatalog) {
            CatalogBrowseView(env: env, vehicleId: vehicle.id)
        }
        .navigationTitle("\(vehicle.make.displayCased) \(vehicle.model.displayCased)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onStartScan()
                } label: {
                    Image(systemName: "viewfinder")
                }
            }
        }
        .task {
            if historyViewModel.state == .idle {
                await historyViewModel.loadInitial()
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
                    Text("\(vehicle.year ?? 0) \(vehicle.make.displayCased) \(vehicle.model.displayCased)")
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
                detailRow(label: Localized.Garage.vinLabel.localized, value: vin)
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

    // Entry to the TecDoc catalog browser (vehicle-parts / parts-search).
    // Only meaningful for plate-resolved vehicles carrying a tecdoc_ktype;
    // for others the backend answers CATALOG_LOOKUP_FAILED and the sheet
    // shows its friendly error state.
    private var browseCatalogButton: some View {
        Button {
            showCatalog = true
        } label: {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(Color.sbAccentPrimary)

                Text(Localized.Catalog.browse.localizedKey)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

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
        .sbVerticalPadding(.medium)
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
