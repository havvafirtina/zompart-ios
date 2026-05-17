import SwiftUI
import SBDesignSystem

@main
struct ZomPartApp: App {

    private let env: AppEnvironment

    init() {
        self.env = AppEnvironment.build()
    }

    var body: some Scene {
        WindowGroup {
            SBDesignSystemProvider {
                RootView(env: env)
            }
        }
    }
}
