import Foundation

@MainActor
@Observable
final class DeleteAccountViewModel {

    enum Phase {
        case confirm
        case otpSent
        case deleting
    }

    private(set) var phase: Phase = .confirm
    private(set) var state: ViewState<Bool> = .idle
    var otpCode = ""

    private let userEmail: String
    private let authRepository: AuthRepositoryProtocol
    private let authStateManager: AuthStateManager

    init(
        userEmail: String,
        authRepository: AuthRepositoryProtocol,
        authStateManager: AuthStateManager
    ) {
        self.userEmail = userEmail
        self.authRepository = authRepository
        self.authStateManager = authStateManager
    }

    func requestDeletion() async {
        state = .loading
        do {
            _ = try await authRepository.requestAccountDeletion()
            phase = .otpSent
            state = .idle
        } catch {
            state = .error(Localized.Error.network.localized)
        }
    }

    func confirmDeletion() async {
        guard !otpCode.isEmpty else { return }
        state = .loading
        phase = .deleting
        do {
            _ = try await authRepository.confirmAccountDeletion(email: userEmail, token: otpCode)
            state = .loaded(true)
            authStateManager.logout()
        } catch {
            phase = .otpSent
            state = .error(Localized.Auth.errorOtpInvalid.localized)
        }
    }
}
