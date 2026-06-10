import Foundation

@MainActor
@Observable
final class ManualWizardViewModel {

    private(set) var state: ViewState<VehicleManualSessionDomain> = .idle
    private(set) var session: VehicleManualSessionDomain?

    private let vehicleRepository: VehicleRepositoryProtocol
    private let onVehicleAdded: () -> Void

    init(
        vehicleRepository: VehicleRepositoryProtocol,
        onVehicleAdded: @escaping () -> Void
    ) {
        self.vehicleRepository = vehicleRepository
        self.onVehicleAdded = onVehicleAdded
    }

    var currentStep: VehicleManualStepDomain? {
        session?.nextStep
    }

    var options: [String] {
        session?.options ?? []
    }

    var isOptional: Bool {
        session?.nextStepIsOptional ?? false
    }

    func startWizard() async {
        state = .loading
        do {
            let existingSession = try await vehicleRepository.fetchManualSession()
            if let existingSession {
                session = existingSession
                state = .loaded(existingSession)
            } else {
                let yearOptions = (1960...Calendar.current.component(.year, from: Date()))
                    .reversed()
                    .map { String($0) }
                let initialSession = VehicleManualSessionDomain(
                    sessionId: "",
                    nextStep: .year,
                    nextStepIsOptional: false,
                    options: Array(yearOptions),
                    completedSteps: []
                )
                session = initialSession
                state = .loaded(initialSession)
            }
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    func selectOption(_ option: String) async {
        guard let step = currentStep else { return }
        state = .loading

        let value: VehicleManualStepValueDomain
        switch step {
        case .year:
            value = .year(Int(option) ?? 0)
        case .make:
            value = .make(option)
        case .model:
            value = .model(option)
        case .trim:
            value = .trim(option)
        case .engine:
            value = .engine(option)
        }

        let sid = session?.sessionId
        let effectiveSessionId = (sid?.isEmpty ?? true) ? nil : sid

        do {
            let result = try await vehicleRepository.submitManualStep(
                value,
                sessionId: effectiveSessionId,
                countryCode: "SE"
            )
            handleResult(result)
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    func skipStep() async {
        guard let step = currentStep, let sessionId = session?.sessionId else { return }
        state = .loading

        let value: VehicleManualStepValueDomain
        switch step {
        case .trim:
            value = .trim(nil)
        case .engine:
            value = .engine(nil)
        default:
            return
        }

        do {
            let result = try await vehicleRepository.submitManualStep(
                value,
                sessionId: sessionId,
                countryCode: "SE"
            )
            handleResult(result)
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func handleResult(_ result: VehicleManualResultDomain) {
        switch result {
        case .resolved:
            onVehicleAdded()
        case .inProgress(let newSession):
            session = newSession
            state = .loaded(newSession)
        }
    }
}
