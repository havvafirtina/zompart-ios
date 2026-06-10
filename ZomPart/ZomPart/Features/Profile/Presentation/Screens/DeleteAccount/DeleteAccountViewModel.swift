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
        } catch let error as AuthError {
            state = .error(error.deletionErrorMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
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
        } catch let error as AuthError {
            phase = .otpSent
            state = .error(error.deletionErrorMessage)
        } catch {
            phase = .otpSent
            state = .error(Localized.Error.unknown.localized)
        }
    }
}

// Deletion-flow-specific messages for the shared `AuthError` type.
private extension AuthError {

    var deletionErrorMessage: String {
        switch self {
        case .noPendingDeletionRequest:
            return Localized.Profile.errorNoPendingDeletion.localized
        case .deletionRequestExpired:
            return Localized.Profile.errorDeletionRequestExpired.localized
        case .deletionFailed:
            return Localized.Profile.errorDeletionFailed.localized
        case .otpInvalid:
            return Localized.Auth.errorOtpInvalid.localized
        case .network:
            return Localized.Error.network.localized
        default:
            return Localized.Error.unknown.localized
        }
    }
}
