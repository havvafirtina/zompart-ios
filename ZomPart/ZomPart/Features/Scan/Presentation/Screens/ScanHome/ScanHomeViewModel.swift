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
            let deletedIds = Set(UserDefaults.standard.stringArray(forKey: Self.deletedIdsKey) ?? [])
            let all = try await vehicleRepository.listVehicles()
            let filtered = all.filter { !deletedIds.contains($0.id) }
            vehicles = filtered
            if selectedVehicle == nil || !filtered.contains(where: { $0.id == selectedVehicle?.id }) {
                selectedVehicle = filtered.first
            }
            vehiclesState = filtered.isEmpty ? .empty : .loaded(filtered)
        } catch is CancellationError {
            if case .loading = vehiclesState { vehiclesState = .idle }
        } catch let error as VehicleError {
            vehiclesState = .error(error.localizedMessage)
        } catch {
            vehiclesState = .error(Localized.Error.unknown.localized)
        }
    }
}
