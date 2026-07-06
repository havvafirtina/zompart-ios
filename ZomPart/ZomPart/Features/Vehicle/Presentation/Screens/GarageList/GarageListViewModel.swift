import Foundation

@MainActor
@Observable
final class GarageListViewModel {

    private(set) var state: ViewState<[VehicleDomain]> = .idle
    private(set) var vehicles: [VehicleDomain] = []

    private let vehicleRepository: VehicleRepositoryProtocol
    private var deletedIds: Set<String>

    private static let deletedIdsKey = "deleted_vehicle_ids"

    init(vehicleRepository: VehicleRepositoryProtocol) {
        self.vehicleRepository = vehicleRepository
        let stored = UserDefaults.standard.stringArray(forKey: Self.deletedIdsKey) ?? []
        self.deletedIds = Set(stored)
    }

    func loadVehicles() async {
        if !vehicles.isEmpty { return await refresh() }
        state = .loading
        do {
            let all = try await vehicleRepository.listVehicles()
            let filtered = all.filter { !deletedIds.contains($0.id) }
            vehicles = filtered
            state = filtered.isEmpty ? .empty : .loaded(filtered)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    func refresh() async {
        do {
            let all = try await vehicleRepository.listVehicles()
            let filtered = all.filter { !deletedIds.contains($0.id) }
            vehicles = filtered
            state = filtered.isEmpty ? .empty : .loaded(filtered)
        } catch is CancellationError {
            // cancelled mid-refresh — next appearance reloads via .task
        } catch {
            // refresh keeps existing data, but never leaves a transient
            // state on screen
            state = vehicles.isEmpty ? .empty : .loaded(vehicles)
        }
    }

    func deleteVehicle(id: String) {
        deletedIds.insert(id)
        UserDefaults.standard.set(Array(deletedIds), forKey: Self.deletedIdsKey)
        vehicles.removeAll { $0.id == id }
        state = vehicles.isEmpty ? .empty : .loaded(vehicles)
    }

    /// Optimistically inserts the freshly resolved vehicle so the list shows it
    /// immediately, then reconciles with the server in the background.
    /// Never blanks the list back to a spinner: even if the reconcile request
    /// fails silently, the new vehicle stays visible.
    func onVehicleAdded(vehicle: VehicleDomain) async {
        if deletedIds.contains(vehicle.id) {
            deletedIds.remove(vehicle.id)
            UserDefaults.standard.set(Array(deletedIds), forKey: Self.deletedIdsKey)
        }
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.insert(vehicle, at: 0)
        state = .loaded(vehicles)
        await refresh()
    }
}
