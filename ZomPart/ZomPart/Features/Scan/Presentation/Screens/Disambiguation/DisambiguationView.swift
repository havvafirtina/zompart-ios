import SwiftUI
import SBDesignSystem

struct DisambiguationView: View {

    @Bindable var viewModel: DisambiguationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                headerSection
                if !viewModel.questions.isEmpty {
                    questionsSection
                }
                alternativesList
                if case .error(let message) = viewModel.state {
                    Text(message)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbStatusError)
                        .sbVerticalPadding(.small)
                }
                manualSearchSection
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Scan.disambiguationTitle.localized)
        .disabled(viewModel.state == .loading)
        .overlay {
            if viewModel.state == .loading {
                ProgressView()
            }
        }
    }

    // Escape hatch when no alternative matches: MANUAL_SEARCH on the same scan.
    private var manualSearchSection: some View {
        VStack(alignment: .leading) {
            Text(Localized.Scan.manualSearchNoneOfThese.localizedKey)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextSecondary)

            HStack {
                TextField(
                    Localized.Scan.manualSearchPlaceholder.localized,
                    text: $viewModel.manualQuery
                )
                .font(.sbBodyMediumDefault)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .sbPadding(.medium)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.medium)

                Button {
                    Task { await viewModel.manualSearch() }
                } label: {
                    Text(Localized.Scan.manualSearchAction.localizedKey)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .sbPadding(.medium)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.medium)
                }
                .disabled(viewModel.manualQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sbVerticalPadding(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading) {
            Text(Localized.Scan.disambiguationTitle.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)

            Text(Localized.Scan.disambiguationSubtitle.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
        }
        .sbVerticalPadding(.medium)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.questions, id: \.id) { question in
                VStack(alignment: .leading) {
                    Text(question.question)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbTextPrimary)

                    ForEach(question.options, id: \.self) { option in
                        Text("• \(option)")
                            .font(.sbBodyRegularDefault)
                            .foregroundStyle(Color.sbTextSecondary)
                    }
                }
                .sbPadding(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.sbAccentSubtle)
                .sbCornerRadius(.medium)
            }
        }
        .sbVerticalPadding(.small)
    }

    private var alternativesList: some View {
        VStack {
            ForEach(Array(viewModel.alternatives.enumerated()), id: \.offset) { _, alt in
                Button {
                    Task { await viewModel.selectPart(partCandidateId: alt.id) }
                } label: {
                    HStack {
                        Text(alt.name)
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)

                        Spacer()

                        Text("\(Int(alt.confidence * 100))%")
                            .font(.sbBodyMediumSmall)
                            .foregroundStyle(Color.sbAccentPrimary)

                        Image(systemName: "chevron.right")
                            .font(.sbBodyRegularXSmall)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                    .sbPadding(.large)
                    .background(Color.sbSurfaceSecondary)
                    .sbCornerRadius(.default)
                    .sbShadow(.soft)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
