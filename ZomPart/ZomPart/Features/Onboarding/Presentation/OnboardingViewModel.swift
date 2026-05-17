import Foundation

@Observable
@MainActor
final class OnboardingViewModel {

    var currentPage: Int = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "camera.viewfinder",
            title: Localized.Onboarding.page1Title,
            subtitle: Localized.Onboarding.page1Subtitle
        ),
        OnboardingPage(
            symbol: "sparkles",
            title: Localized.Onboarding.page2Title,
            subtitle: Localized.Onboarding.page2Subtitle
        ),
        OnboardingPage(
            symbol: "tag.fill",
            title: Localized.Onboarding.page3Title,
            subtitle: Localized.Onboarding.page3Subtitle
        )
    ]

    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    func next() {
        if isLastPage {
            onFinish()
        } else {
            currentPage += 1
        }
    }

    func skip() {
        onFinish()
    }
}

struct OnboardingPage {
    let symbol: String
    let title: Localized.Onboarding
    let subtitle: Localized.Onboarding
}
