import SwiftUI
import SBDesignSystem

struct ScanProcessingView: View {

    let viewModel: ScanProcessingViewModel

    var body: some View {
        VStack {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text(Localized.Scan.processing.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.large)

            Text(viewModel.currentTip)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: viewModel.currentTip)

            if case .error(let message) = viewModel.state {
                VStack {
                    Text(message)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbStatusError)

                    Button(Localized.Common.retry.localized) {
                        Task { await viewModel.startProcessing() }
                    }
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbAccentPrimary)
                }
                .sbVerticalPadding(.large)
            }

            Spacer()
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sbSurfacePrimary)
        .navigationBarBackButtonHidden()
        .task {
            if viewModel.state == .idle {
                await viewModel.startProcessing()
            }
        }
    }
}
