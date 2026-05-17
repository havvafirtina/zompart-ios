import Foundation

@MainActor
@Observable
final class OTPVerifyViewModel {

    private(set) var state: ViewState<Bool> = .idle
    var otpCode = ""

    let email: String

    private let authRepository: AuthRepositoryProtocol
    private let onVerified: (AuthSessionDomain) -> Void

    init(
        email: String,
        authRepository: AuthRepositoryProtocol,
        onVerified: @escaping (AuthSessionDomain) -> Void
    ) {
        self.email = email
        self.authRepository = authRepository
        self.onVerified = onVerified
    }

    func verify() async {
        guard !otpCode.isEmpty else { return }
        state = .loading
        do {
            let session = try await authRepository.verifyOTP(email: email, token: otpCode)
            state = .loaded(true)
            onVerified(session)
        } catch let error as AuthError {
            state = .error(Self.message(for: error))
        } catch {
            state = .error(Localized.Auth.errorUnknown.localized)
        }
    }

    private static func message(for error: AuthError) -> String {
        switch error {
        case .otpInvalid:
            Localized.Auth.errorOtpInvalid.localized
        case .tokenExpired:
            Localized.Error.tokenExpired.localized
        case .network:
            Localized.Auth.errorNetwork.localized
        default:
            Localized.Auth.errorUnknown.localized
        }
    }
}
