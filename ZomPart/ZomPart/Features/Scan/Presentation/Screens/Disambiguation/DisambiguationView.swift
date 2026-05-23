import SwiftUI
import SBDesignSystem

struct DisambiguationView: View {

    let viewModel: DisambiguationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                headerSection
                if !viewModel.questions.isEmpty {
                    questionsSection
                }
                alternativesList
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
                    Task { await viewModel.selectPart(partCandidateId: alt.partNumber) }
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
