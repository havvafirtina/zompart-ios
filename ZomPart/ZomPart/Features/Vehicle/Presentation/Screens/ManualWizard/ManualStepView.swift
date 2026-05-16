import SwiftUI
import SBDesignSystem

struct ManualStepView: View {

  let viewModel: ManualWizardViewModel

  var body: some View {
    VStack(alignment: .leading) {
      stepHeader

      if viewModel.state == .loading {
        ProgressView()
          .frame(maxWidth: .infinity)
          .sbVerticalPadding(.large)
      } else {
        optionsList
      }
    }
    .sbPadding(.large)
    .background(Color.sbSurfacePrimary)
  }

  private var stepHeader: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(stepTitle)
          .font(.sbTitleSemiboldLarge)
          .foregroundStyle(Color.sbTextPrimary)

        if viewModel.isOptional {
          Text(Localized.Common.skip.localized)
            .font(.sbBodyRegularSmall)
            .foregroundStyle(Color.sbTextTertiary)
        }
      }

      Spacer()

      if viewModel.isOptional {
        Button(Localized.Common.skip.localized) {
          Task { await viewModel.skipStep() }
        }
        .font(.sbBodySemiboldDefault)
        .foregroundStyle(Color.sbAccentPrimary)
      }
    }
    .sbVerticalPadding(.medium)
  }

  private var optionsList: some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.options, id: \.self) { option in
          Button {
            Task { await viewModel.selectOption(option) }
          } label: {
            HStack {
              Text(option)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextPrimary)
              Spacer()
              Image(systemName: "chevron.right")
                .font(.sbBodyRegularXSmall)
                .foregroundStyle(Color.sbTextTertiary)
            }
            .sbPadding(.medium)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.medium)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var stepTitle: String {
    guard let step = viewModel.currentStep else { return "" }
    switch step {
    case .year: return Localized.Garage.selectYear.localized
    case .make: return Localized.Garage.selectMake.localized
    case .model: return Localized.Garage.selectModel.localized
    case .trim: return Localized.Garage.selectTrim.localized
    case .engine: return Localized.Garage.selectEngine.localized
    }
  }
}
