import SwiftUI

enum OnboardingModule {

    @MainActor
    static func makeOnboardingView(onFinish: @escaping () -> Void) -> some View {
        OnboardingView(viewModel: OnboardingViewModel(onFinish: onFinish))
    }
}
