import Foundation

@MainActor
@Observable
final class ProfileMainViewModel {

    private(set) var isLoggingOut = false
    var showLogoutConfirm = false

    let userEmail: String
    let userName: String

    private let authRepository: AuthRepositoryProtocol
    private let authStateManager: AuthStateManager

    init(
        userEmail: String,
        userName: String,
        authRepository: AuthRepositoryProtocol,
        authStateManager: AuthStateManager
    ) {
        self.userEmail = userEmail
        self.userName = userName
        self.authRepository = authRepository
        self.authStateManager = authStateManager
    }

    func requestLogout() {
        showLogoutConfirm = true
    }

    func confirmLogout() async {
        isLoggingOut = true
        do {
            try await authRepository.logout(scope: .local)
        } catch {
            // logout best-effort
        }
        authStateManager.logout()
        isLoggingOut = false
    }
}
