import SwiftUI
import SBDesignSystem

struct GarageListView: View {

    let viewModel: GarageListViewModel
    var onAddVehicle: () -> Void
    var onVehicleTap: (VehicleDomain) -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                emptyState

            case .loaded:
                vehicleList

            case .error(let message):
                errorState(message: message)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Tab.garage.localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onAddVehicle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.loadVehicles()
            }
        }
        .refreshable {
            await viewModel.loadVehicles()
        }
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Garage.emptyTitle.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)

            Text(Localized.Garage.emptySubtitle.localizedKey)
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

    private var vehicleList: some View {
        List {
            ForEach(viewModel.vehicles, id: \.id) { vehicle in
                VehicleCardView(vehicle: vehicle) {
                    onVehicleTap(vehicle)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteVehicle(id: vehicle.id)
                    } label: {
                        Label(Localized.Common.delete.localized, systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func errorState(message: String) -> some View {
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
}
