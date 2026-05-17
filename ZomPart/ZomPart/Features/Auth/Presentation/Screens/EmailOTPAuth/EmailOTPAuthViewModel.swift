import Foundation

@MainActor
@Observable
final class EmailOTPAuthViewModel {

    private(set) var state: ViewState<Bool> = .idle

    private let authRepository: AuthRepositoryProtocol
    private let onOTPSent: (String, String?) -> Void

    init(
        authRepository: AuthRepositoryProtocol,
        onOTPSent: @escaping (String, String?) -> Void
    ) {
        self.authRepository = authRepository
        self.onOTPSent = onOTPSent
    }

    func sendOTP(
        email: String,
        intent: AuthOTPIntent,
        firstName: String?,
        lastName: String?
    ) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .loading
        do {
            _ = try await authRepository.sendOTP(
                email: trimmedEmail,
                intent: intent,
                firstName: firstName,
                lastName: lastName
            )
            state = .loaded(true)
            let fullName = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            onOTPSent(trimmedEmail, fullName.isEmpty ? nil : fullName)
        } catch let error as AuthError {
            state = .error(Self.message(for: error))
        } catch {
            state = .error(Localized.Auth.errorUnknown.localized)
        }
    }

    private static func message(for error: AuthError) -> String {
        switch error {
        case .validationFailed:
            Localized.Auth.errorValidation.localized
        case .emailAlreadyRegistered:
            Localized.Auth.errorEmailRegistered.localized
        case .emailNotRegistered:
            Localized.Auth.errorEmailNotRegistered.localized
        case .network:
            Localized.Auth.errorNetwork.localized
        default:
            Localized.Auth.errorUnknown.localized
        }
    }
}
