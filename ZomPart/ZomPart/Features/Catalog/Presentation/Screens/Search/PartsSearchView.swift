import SwiftUI
import SBDesignSystem

struct PartsSearchView: View {

    let env: AppEnvironment
    let vehicleId: String?
    @State private var viewModel: PartsSearchViewModel?

    var body: some View {
        VStack(spacing: 0) {
            searchField
            results
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Catalog.searchTitle.localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = CatalogModule.makePartsSearchViewModel(env: env, vehicleId: vehicleId)
            }
        }
    }

    @ViewBuilder
    private var searchField: some View {
        if let viewModel {
            @Bindable var vm = viewModel
            HStack {
                TextField(Localized.Catalog.searchPlaceholder.localized, text: $vm.query)
                    .font(.sbBodyMediumDefault)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.search() } }
                    .sbPadding(.medium)
                    .background(Color.sbSurfaceSecondary)
                    .sbCornerRadius(.medium)

                Button {
                    Task { await viewModel.search() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .sbPadding(.medium)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.medium)
                }
                .disabled(vm.query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .sbHorizontalPadding(.large)
            .sbVerticalPadding(.medium)
        }
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel?.state {
        case .none, .idle:
            Spacer()

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.sbTextTertiary)

                Text(Localized.Catalog.empty.localizedKey)
                    .font(.sbBodyRegularDefault)
                    .foregroundStyle(Color.sbTextSecondary)
            }
            .sbPadding(.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let page):
            List {
                ForEach(page.articles) { part in
                    CatalogPartRowView(part: part)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }

                TecDocAttributionFooter()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

        case .error(let message):
            VStack {
                Text(message)
                    .font(.sbBodyRegularDefault)
                    .foregroundStyle(Color.sbTextSecondary)
                    .multilineTextAlignment(.center)

                Button(Localized.Common.retry.localized) {
                    Task { await viewModel?.search() }
                }
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(Color.sbAccentPrimary)
            }
            .sbPadding(.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
