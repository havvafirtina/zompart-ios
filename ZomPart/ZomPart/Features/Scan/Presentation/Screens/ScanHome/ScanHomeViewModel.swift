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

    func loadVehicles() async {
        vehiclesState = .loading
        do {
            try await fetchAndApply()
        } catch is CancellationError {
            if case .loading = vehiclesState { vehiclesState = .idle }
        } catch let error as VehicleError {
            vehiclesState = .error(error.localizedMessage)
        } catch {
            vehiclesState = .error(Localized.Error.unknown.localized)
        }
    }

    /// Optimistically inserts the freshly resolved vehicle, then reconciles with
    /// the server without blanking the current content to a spinner.
    func onVehicleAdded(vehicle: VehicleDomain) async {
        var deletedIds = Set(UserDefaults.standard.stringArray(forKey: Self.deletedIdsKey) ?? [])
        if deletedIds.contains(vehicle.id) {
            deletedIds.remove(vehicle.id)
            UserDefaults.standard.set(Array(deletedIds), forKey: Self.deletedIdsKey)
        }
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.insert(vehicle, at: 0)
        if selectedVehicle == nil {
            selectedVehicle = vehicle
        }
        vehiclesState = .loaded(vehicles)
        // reconcile silently — on failure the optimistic data stays on screen
        try? await fetchAndApply()
    }

    private func fetchAndApply() async throws {
        let deletedIds = Set(UserDefaults.standard.stringArray(forKey: Self.deletedIdsKey) ?? [])
        let all = try await vehicleRepository.listVehicles()
        let filtered = all.filter { !deletedIds.contains($0.id) }
        vehicles = filtered
        if selectedVehicle == nil || !filtered.contains(where: { $0.id == selectedVehicle?.id }) {
            selectedVehicle = filtered.first
        }
        vehiclesState = filtered.isEmpty ? .empty : .loaded(filtered)
    }
}
