import SwiftUI
import SBDesignSystem

struct HistoryListView: View {

    let viewModel: HistoryListViewModel
    let onScanTap: (String) -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                emptyState

            case .loaded:
                scanList

            case .error(let message):
                errorState(message)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.History.title.localized)
        .task {
            if viewModel.state == .idle {
                await viewModel.loadInitial()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.transientError {
                transientErrorBanner(message)
            }
        }
    }

    /// Failed refresh/loadMore keeps the old data on screen — without this
    /// banner the user believes the list is up to date.
    private func transientErrorBanner(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbStatusError)

            Text(message)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextPrimary)
        }
        .sbPadding(.medium)
        .background(Color.sbStatusErrorSubtle)
        .sbCornerRadius(.medium)
        .sbPadding(.large)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(3))
            viewModel.clearTransientError()
        }
        .onTapGesture {
            viewModel.clearTransientError()
        }
        .accessibilityElement(children: .combine)
    }

    private var scanList: some View {
        List {
            ForEach(viewModel.scans, id: \.id) { scan in
                HistoryScanRowView(scan: scan) {
                    onScanTap(scan.id)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .onAppear {
                    if scan.id == viewModel.scans.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(Localized.History.empty.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Task { await viewModel.loadInitial() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
