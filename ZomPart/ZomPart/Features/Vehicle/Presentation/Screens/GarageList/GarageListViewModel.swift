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
    state = .loading
    do {
      let all = try await vehicleRepository.listVehicles()
      let filtered = all.filter { !deletedIds.contains($0.id) }
      vehicles = filtered
      state = filtered.isEmpty ? .empty : .loaded(filtered)
    } catch {
      state = .error(Localized.Error.network.localized)
    }
  }

  func deleteVehicle(id: String) {
    deletedIds.insert(id)
    UserDefaults.standard.set(Array(deletedIds), forKey: Self.deletedIdsKey)
    vehicles.removeAll { $0.id == id }
    state = vehicles.isEmpty ? .empty : .loaded(vehicles)
  }

  func onVehicleAdded(vehicleId: String? = nil) async {
    if let vehicleId, deletedIds.contains(vehicleId) {
      deletedIds.remove(vehicleId)
      UserDefaults.standard.set(Array(deletedIds), forKey: Self.deletedIdsKey)
    }
    await loadVehicles()
  }
}
