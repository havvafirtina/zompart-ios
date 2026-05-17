import Foundation
import SBNetworking

enum ProfileModule {

    @MainActor
    static func makeProfileMainViewModel(
        env: AppEnvironment,
        authStateManager: AuthStateManager
    ) -> ProfileMainViewModel {
        ProfileMainViewModel(
            userEmail: authStateManager.userEmail,
            userName: authStateManager.userName,
            authRepository: AuthModule.makeAuthRepository(httpClient: env.httpClient),
            authStateManager: authStateManager
        )
    }

    @MainActor
    static func makeDeleteAccountViewModel(
        env: AppEnvironment,
        authStateManager: AuthStateManager
    ) -> DeleteAccountViewModel {
        DeleteAccountViewModel(
            userEmail: authStateManager.userEmail,
            authRepository: AuthModule.makeAuthRepository(httpClient: env.httpClient),
            authStateManager: authStateManager
        )
    }
}
