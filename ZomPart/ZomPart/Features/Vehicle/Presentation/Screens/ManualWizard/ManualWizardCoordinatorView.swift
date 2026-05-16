import SwiftUI
import SBDesignSystem

struct ManualWizardCoordinatorView: View {

  let viewModel: ManualWizardViewModel

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)

      case .loaded:
        ManualStepView(viewModel: viewModel)

      case .empty:
        EmptyView()

      case .error(let message):
        VStack {
          Text(message)
            .font(.sbBodyRegularDefault)
            .foregroundStyle(Color.sbStatusError)

          Button(Localized.Common.retry.localized) {
            Task { await viewModel.startWizard() }
          }
          .font(.sbBodySemiboldDefault)
          .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.large)
      }
    }
    .background(Color.sbSurfacePrimary)
    .navigationTitle(Localized.Garage.manualEntry.localized)
    .task {
      if viewModel.state == .idle {
        await viewModel.startWizard()
      }
    }
  }
}
