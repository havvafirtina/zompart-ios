import SwiftUI
import SBDesignSystem

struct ScanDetailView: View {

    let viewModel: ScanDetailViewModel
    let onViewOffers: (String) -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let detail):
                detailContent(detail)

            case .empty:
                EmptyView()

            case .error(let message):
                errorState(message)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.History.detailTitle.localized)
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    private func detailContent(_ detail: ScanDetailDomain) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                vehicleSection(detail.vehicle)
                scanInfoSection(detail.scan)
                artifactsSection(detail.artifacts)
                partSection(detail.selectedPart, scanId: detail.scan.id, state: detail.scan.state)
            }
            .sbPadding(.large)
        }
    }

    @ViewBuilder
    private func vehicleSection(_ vehicle: HistoryVehicleSummaryDomain?) -> some View {
        if let vehicle {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color.sbAccentPrimary)

                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                Spacer()
            }
            .sbPadding(.large)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
            .sbShadow(.soft)
        }
    }

    private func scanInfoSection(_ scan: ScanDetailItemDomain) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localized.History.status.localizedKey)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)
                Spacer()
                Text(scan.state)
                    .font(.sbBodyMediumSmall)
                    .foregroundStyle(Color.sbTextPrimary)
            }

            if let inputText = scan.inputText, !inputText.isEmpty {
                VStack(alignment: .leading) {
                    Text(Localized.History.inputText.localizedKey)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextSecondary)

                    Text(inputText)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextPrimary)
                }
                .sbVerticalPadding(.small)
            }
        }
        .sbPadding(.large)
        .background(Color.sbSurfaceSecondary)
        .sbCornerRadius(.default)
        .sbVerticalPadding(.medium)
    }

    @ViewBuilder
    private func artifactsSection(_ artifacts: [ScanArtifactDomain]) -> some View {
        let photos = artifacts.filter { $0.artifactType == .photo || $0.artifactType == .thumbnail }
        if !photos.isEmpty {
            VStack(alignment: .leading) {
                Text(Localized.History.photos.localizedKey)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(photos, id: \.id) { artifact in
                        if let urlString = artifact.thumbnailUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.sbSurfaceTertiary
                            }
                            .frame(height: 80)
                            .clipped()
                            .sbCornerRadius(.medium)
                        }
                    }
                }
            }
            .sbVerticalPadding(.medium)
        }
    }

    @ViewBuilder
    private func partSection(_ part: HistoryPartSummaryDomain?, scanId: String, state: String) -> some View {
        if let part {
            VStack(alignment: .leading) {
                Text(Localized.Scan.resultTitle.localizedKey)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)

                HStack {
                    VStack(alignment: .leading) {
                        Text(part.name)
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)

                        Text(part.partNumber)
                            .font(.sbBodyRegularSmall)
                            .foregroundStyle(Color.sbTextSecondary)
                    }

                    Spacer()

                    if state == "OFFERS_READY" {
                        Button {
                            onViewOffers(scanId)
                        } label: {
                            Text(Localized.Scan.viewOffers.localizedKey)
                                .font(.sbBodySemiboldSmall)
                                .foregroundStyle(Color.sbTextOnAccent)
                                .sbHorizontalPadding(.large)
                                .sbControlHeight(.compact)
                                .background(Color.sbAccentPrimary)
                                .sbCornerRadius(.medium)
                        }
                    }
                }
                .sbPadding(.large)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.default)
                .sbShadow(.soft)
            }
            .sbVerticalPadding(.medium)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(message)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button(Localized.Common.retry.localized) {
                Task { await viewModel.load() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
