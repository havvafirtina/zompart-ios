import SwiftUI
import SBDesignSystem

struct CatalogArticlesView: View {

    let env: AppEnvironment
    let vehicleId: String
    let category: CatalogCategoryDomain
    @State private var viewModel: CatalogArticlesViewModel?

    var body: some View {
        Group {
            switch viewModel?.state {
            case .none, .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                VStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.sbTextTertiary)

                    Text(Localized.Catalog.empty.localizedKey)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextSecondary)
                }
                .sbPadding(.xLarge)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let page):
                articlesList(page)

            case .error(let message):
                VStack {
                    Text(message)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextSecondary)
                        .multilineTextAlignment(.center)

                    Button(Localized.Common.retry.localized) {
                        Task { await viewModel?.load() }
                    }
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbAccentPrimary)
                }
                .sbPadding(.xLarge)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = CatalogModule.makeCatalogArticlesViewModel(
                    env: env,
                    vehicleId: vehicleId,
                    category: category
                )
            }
            await viewModel?.load()
        }
    }

    private func articlesList(_ page: CatalogArticlesPageDomain) -> some View {
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
    }
}
