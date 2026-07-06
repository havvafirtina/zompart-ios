import SwiftUI
import SBDesignSystem

/// Self-contained catalog browser presented as a sheet from the vehicle
/// detail screen. Owns its own NavigationStack; drill-down through the
/// assembly-group tree is client-side over one flat response.
struct CatalogBrowseView: View {

    enum Route: Hashable {
        case node(CatalogCategoryDomain)
        case articles(CatalogCategoryDomain)
        case search
    }

    let env: AppEnvironment
    let vehicleId: String
    @State private var viewModel: CatalogBrowseViewModel?
    @State private var path: [Route] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(Color.sbSurfacePrimary)
                .navigationTitle(Localized.Catalog.title.localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localized.Common.done.localized) { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            path.append(.search)
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
        .task {
            if viewModel == nil {
                viewModel = CatalogModule.makeCatalogBrowseViewModel(env: env, vehicleId: vehicleId)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state {
        case .none, .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            emptyState(Localized.Catalog.empty.localized)

        case .loaded(let page):
            categoryList(page: page, parent: nil)

        case .error(let message):
            errorState(message)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .node(let category):
            if case .loaded(let page) = viewModel?.state {
                categoryList(page: page, parent: category)
                    .background(Color.sbSurfacePrimary)
                    .navigationTitle(category.name)
                    .navigationBarTitleDisplayMode(.inline)
            }

        case .articles(let category):
            CatalogArticlesView(env: env, vehicleId: vehicleId, category: category)

        case .search:
            PartsSearchView(env: env, vehicleId: vehicleId)
        }
    }

    private func categoryList(page: CatalogCategoryPageDomain, parent: CatalogCategoryDomain?) -> some View {
        List {
            ForEach(page.children(of: parent?.id)) { category in
                Button {
                    path.append(page.isLeaf(category) ? .articles(category) : .node(category))
                } label: {
                    categoryRow(category)
                }
                .buttonStyle(.plain)
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

    private func categoryRow(_ category: CatalogCategoryDomain) -> some View {
        HStack {
            Text(category.name)
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(Color.sbTextPrimary)

            Spacer()

            if let count = category.articleCount, count > 0 {
                Text(Localized.Catalog.articlesCount.localized(count))
                    .font(.sbBodyRegularXSmall)
                    .foregroundStyle(Color.sbTextTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.sbBodyRegularXSmall)
                .foregroundStyle(Color.sbTextTertiary)
        }
        .sbPadding(.large)
        .background(Color.sbSurfaceSecondary)
        .sbCornerRadius(.default)
    }

    private func emptyState(_ message: String) -> some View {
        VStack {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(message)
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
                Task { await viewModel?.load() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
