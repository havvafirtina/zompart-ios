import Foundation

@MainActor
@Observable
final class ScanHomeViewModel {

    private(set) var vehiclesState: ViewState<[VehicleDomain]> = .idle
    private(set) var vehicles: [VehicleDomain] = []
    var selectedVehicle: VehicleDomain?

    private let vehicleRepository: VehicleRepositoryProtocol
    private static let deletedIdsKey = "deleted_vehicle_ids"

    init(vehicleRepository: VehicleRepositoryProtocol) {
        self.vehicleRepository = vehicleRepository
    }

    var hasVehicles: Bool { !vehicles.isEmpty }

    func loadVehicles() async {
        vehiclesState = .loading
        do {
            let deletedIds = Set(UserDefaults.standard.stringArray(forKey: Self.deletedIdsKey) ?? [])
            let all = try await vehicleRepository.listVehicles()
            let filtered = all.filter { !deletedIds.contains($0.id) }
            vehicles = filtered
            if selectedVehicle == nil || !filtered.contains(where: { $0.id == selectedVehicle?.id }) {
                selectedVehicle = filtered.first
            }
            vehiclesState = filtered.isEmpty ? .empty : .loaded(filtered)
        } catch {
            if Task.isCancelled { return }
            vehiclesState = .error(Localized.Error.network.localized)
        }
    }
}
