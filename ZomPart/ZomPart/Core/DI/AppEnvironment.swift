import Foundation
import SBNetworking

struct AppEnvironment: Sendable {

    let httpClient: HTTPClient
    let tokenProvider: ZomPartAuthTokenProvider
    let featureFlags: FeatureFlagClient
    let config: AppConfig

    static func build() -> AppEnvironment {
        let keychain = KeychainTokenStore()
        let tokenProvider = ZomPartAuthTokenProvider(tokenPersistence: keychain)
        let environment = DefaultEnvironment(authTokenProvider: tokenProvider)
        let httpClient = HTTPClient(client: environment)
        let featureFlags = LocalFeatureFlagClient()
        let config = AppConfig.current()

        return AppEnvironment(
            httpClient: httpClient,
            tokenProvider: tokenProvider,
            featureFlags: featureFlags,
            config: config
        )
    }
}
