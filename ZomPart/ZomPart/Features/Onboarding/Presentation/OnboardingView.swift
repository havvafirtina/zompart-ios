import SwiftUI
import SBDesignSystem

struct OnboardingView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack {
            LogoSubtitleView()
                .frame(width: 220)
                .sbVerticalPadding(.xLarge)

            TabView(selection: $viewModel.currentPage) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            buttons
        }
        .background(Color.sbSurfacePrimary)
    }

    private var buttons: some View {
        HStack {
            if !viewModel.isLastPage {
                Button(Localized.Common.skip.localized) {
                    viewModel.skip()
                }
                .foregroundStyle(Color.sbTextSecondary)
            }

            Spacer()

            Button {
                viewModel.next()
            } label: {
                Text(viewModel.isLastPage ? Localized.Common.done.localized : Localized.Common.next.localized)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextOnAccent)
                    .sbControlHeight(.regular)
                    .sbHorizontalPadding(.xLarge)
                    .background(Color.sbAccentPrimary)
                    .sbCornerRadius(.default)
            }
        }
        .sbHorizontalPadding(.large)
        .sbVerticalPadding(.xLarge)
    }
}
