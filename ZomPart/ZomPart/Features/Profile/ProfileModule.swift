import Foundation

enum ProfileModule {

    @MainActor
    static func makeProfileMainViewModel(
        authRepository: AuthRepositoryProtocol,
        authStateManager: AuthStateManager
    ) -> ProfileMainViewModel {
        ProfileMainViewModel(
            userEmail: authStateManager.userEmail,
            userName: authStateManager.userName,
            authRepository: authRepository,
            authStateManager: authStateManager
        )
    }

    @MainActor
    static func makeDeleteAccountViewModel(
        authRepository: AuthRepositoryProtocol,
        authStateManager: AuthStateManager
    ) -> DeleteAccountViewModel {
        DeleteAccountViewModel(
            userEmail: authStateManager.userEmail,
            authRepository: authRepository,
            authStateManager: authStateManager
        )
    }
}
