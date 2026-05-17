import SwiftUI
import SBDesignSystem

struct DisambiguationView: View {

    let viewModel: DisambiguationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                headerSection
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

    private var alternativesList: some View {
        VStack {
            ForEach(Array(viewModel.alternatives.enumerated()), id: \.offset) { _, alt in
                Button {
                    Task { await viewModel.selectPart(partCandidateId: alt.partNumber) }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(alt.name)
                                .font(.sbBodySemiboldDefault)
                                .foregroundStyle(Color.sbTextPrimary)

                            Text(alt.partNumber)
                                .font(.sbBodyRegularSmall)
                                .foregroundStyle(Color.sbTextSecondary)
                        }

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
