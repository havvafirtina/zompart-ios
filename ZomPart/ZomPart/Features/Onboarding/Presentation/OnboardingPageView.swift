import SwiftUI
import SBDesignSystem

struct OnboardingPageView: View {

  let page: OnboardingPage

  var body: some View {
    VStack {
      Spacer()

      Image(systemName: page.symbol)
        .font(.system(size: 80))
        .foregroundStyle(Color.sbAccentPrimary)

      Text(page.title.localizedKey)
        .font(.sbTitleSemiboldXLarge)
        .foregroundStyle(Color.sbTextPrimary)
        .multilineTextAlignment(.center)
        .sbVerticalPadding(.medium)

      Text(page.subtitle.localizedKey)
        .font(.sbBodyRegularDefault)
        .foregroundStyle(Color.sbTextSecondary)
        .multilineTextAlignment(.center)
        .sbHorizontalPadding(.xLarge)

      Spacer()
      Spacer()
    }
  }
}
