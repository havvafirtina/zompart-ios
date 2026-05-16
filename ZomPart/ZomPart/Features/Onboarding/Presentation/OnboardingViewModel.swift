import Foundation

@Observable
@MainActor
final class OnboardingViewModel {

  var currentPage: Int = 0

  let pages: [OnboardingPage] = [
    OnboardingPage(
      symbol: "camera.viewfinder",
      titleKey: "onboarding.page1.title",
      subtitleKey: "onboarding.page1.subtitle"
    ),
    OnboardingPage(
      symbol: "sparkles",
      titleKey: "onboarding.page2.title",
      subtitleKey: "onboarding.page2.subtitle"
    ),
    OnboardingPage(
      symbol: "tag.fill",
      titleKey: "onboarding.page3.title",
      subtitleKey: "onboarding.page3.subtitle"
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
  let titleKey: String
  let subtitleKey: String
}
