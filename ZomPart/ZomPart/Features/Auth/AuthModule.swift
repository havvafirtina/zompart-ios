import Foundation
import SBNetworking

enum AuthModule {

  static func makeAuthRepository(httpClient: HTTPClient) -> AuthRepositoryProtocol {
    AuthRepository(client: httpClient)
  }

  @MainActor
  static func makeEmailOTPAuthViewModel(
    env: AppEnvironment,
    onOTPSent: @escaping (String) -> Void
  ) -> EmailOTPAuthViewModel {
    EmailOTPAuthViewModel(
      authRepository: makeAuthRepository(httpClient: env.httpClient),
      onOTPSent: onOTPSent
    )
  }

  @MainActor
  static func makeOTPVerifyViewModel(
    env: AppEnvironment,
    email: String,
    onVerified: @escaping (AuthSessionDomain) -> Void
  ) -> OTPVerifyViewModel {
    OTPVerifyViewModel(
      email: email,
      authRepository: makeAuthRepository(httpClient: env.httpClient),
      onVerified: onVerified
    )
  }

}
