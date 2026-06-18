import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // フィルターツールバー
                FilterBar(viewModel: viewModel)

                List(viewModel.filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                        ProductRowView(product: product, viewModel: viewModel)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .overlay {
                    if viewModel.filteredProducts.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    }
                }
            }
            .navigationTitle("商品検索")
            // .searchable: 検索バーをナビゲーションに追加するモディファイア
            .searchable(text: $viewModel.searchText, prompt: "商品名・ブランドで検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("並び順", selection: $viewModel.sortOrder) {
                            ForEach(SortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        Toggle("お気に入りのみ", isOn: $viewModel.showFavoritesOnly)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    ProductListView()
}
