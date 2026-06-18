# 08 ProductSearch ロードマップ

完成形: .searchable + 複数フィルター + ソートで商品を絞り込む

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Product.swift` を新規作成

### 1-1: カテゴリ enum + Product struct
```swift
import Foundation

enum ProductCategory: String, CaseIterable, Identifiable {
    case all         = "すべて"
    case electronics = "電子機器"
    case books       = "本"
    case clothing    = "ファッション"
    case food        = "食品"
    case sports      = "スポーツ"

    var id: String { rawValue }
}

struct Product: Identifiable {
    let id: UUID
    var name: String
    var brand: String
    var category: ProductCategory
    var price: Double
    var rating: Double
    var reviewCount: Int
    var isFavorite: Bool

    var formattedPrice: String { "¥\(Int(price).formatted())" }
}
```

### 1-2: サンプルデータ
```swift
extension Product {
    static let samples: [Product] = [
        Product(id: UUID(), name: "iPhone 16 Pro", brand: "Apple",
                category: .electronics, price: 159800, rating: 4.8,
                reviewCount: 2341, isFavorite: true),
        Product(id: UUID(), name: "MacBook Air M3", brand: "Apple",
                category: .electronics, price: 164800, rating: 4.9,
                reviewCount: 1892, isFavorite: false),
        Product(id: UUID(), name: "SwiftUI実践入門", brand: "技術評論社",
                category: .books, price: 3800, rating: 4.4,
                reviewCount: 345, isFavorite: true),
        // ...他にも数件追加
    ]
}
```
▶ ここで確認: `Product.samples` が複数件取得できること

---

## Step 2 — フィルタリングロジックを作る
**ファイル:** `ViewModels/ProductViewModel.swift` を新規作成

### 2-1: ViewModel の骨格（まずフィルターなし）
```swift
import Foundation

class ProductViewModel: ObservableObject {
    @Published var allProducts: [Product] = Product.samples
    @Published var searchText: String = ""
    @Published var selectedCategory: ProductCategory = .all
}
```

### 2-2: filteredProducts の computed property を段階的に作る
```swift
    var filteredProducts: [Product] {
        var result = allProducts

        // ① カテゴリで絞り込む
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }

        return result
    }
```
▶ ここで確認: `selectedCategory = .books` にすると本だけが返ること

### 2-3: テキスト検索を追加
```swift
        // ② テキスト検索（名前・ブランドに部分一致）
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
```
▶ ここで確認: `searchText = "apple"` にすると Apple製品だけが返ること

### 2-4: ソート enum + ソートを追加
```swift
enum SortOrder: String, CaseIterable, Identifiable {
    case nameAsc   = "名前順"
    case priceAsc  = "価格（安い順）"
    case priceDesc = "価格（高い順）"
    case ratingDesc = "評価順"
    var id: String { rawValue }
}

// ViewModel に追加
    @Published var sortOrder: SortOrder = .nameAsc

    // filteredProducts の return 直前に追加
        switch sortOrder {
        case .nameAsc:    result.sort { $0.name < $1.name }
        case .priceAsc:   result.sort { $0.price < $1.price }
        case .priceDesc:  result.sort { $0.price > $1.price }
        case .ratingDesc: result.sort { $0.rating > $1.rating }
        }
```

### 2-5: お気に入りトグル
```swift
    func toggleFavorite(_ product: Product) {
        guard let i = allProducts.firstIndex(where: { $0.id == product.id }) else { return }
        allProducts[i].isFavorite.toggle()
    }
```

---

## Step 3 — 商品行カードを作る
**ファイル:** `Views/ProductRowView.swift` を新規作成

### 3-1: 横並びカードの骨格
```swift
import SwiftUI

struct ProductRowView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay { Text("📱").font(.title2) }

            // 名前・ブランド・評価
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.subheadline.bold()).lineLimit(1)
                Text(product.brand).font(.caption).foregroundStyle(.secondary)
                Text(String(repeating: "★", count: Int(product.rating)))
                    .font(.caption).foregroundStyle(.orange)
            }

            Spacer()

            // 価格 + お気に入り
            VStack(alignment: .trailing) {
                Text(product.formattedPrice).font(.subheadline.bold())
                Button {
                    viewModel.toggleFavorite(product)
                } label: {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(product.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```
▶ ここで確認: Preview でカードが表示されること

---

## Step 4 — .searchable で検索バーを追加する（メインポイント）
**ファイル:** `Views/ProductListView.swift` を新規作成

### 4-1: NavigationStack + List の骨格
```swift
import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.filteredProducts) { product in
                ProductRowView(product: product, viewModel: viewModel)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("商品検索")
        }
    }
}

#Preview { ProductListView() }
```
▶ ここで確認: 商品リストが表示されること

### 4-2: .searchable を追加する
```swift
            List(...) { ... }
            .listStyle(.plain)
            .navigationTitle("商品検索")
            // ここに追加するだけで検索バーが出る！
            .searchable(text: $viewModel.searchText, prompt: "商品名・ブランドで検索")
```
▶ ここで確認: 検索バーが現れ、文字を入力するとリストが絞り込まれること

### 4-3: 空状態の ContentUnavailableView を追加
```swift
            List(...) { ... }
            .overlay {
                if viewModel.filteredProducts.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
```
▶ ここで確認: 一致しない検索文字列を入力すると「結果なし」画面が出ること

---

## Step 5 — フィルターバーとソートメニューを追加する
**ファイル:** `Views/ProductListView.swift` を編集

### 5-1: カテゴリフィルターバー
```swift
// ProductListView の NavigationStack 内を VStack に変える
            VStack(spacing: 0) {
                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ProductCategory.allCases) { category in
                            Button {
                                viewModel.selectedCategory = category
                            } label: {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedCategory == category
                                        ? Color.blue
                                        : Color(.secondarySystemBackground)
                                    )
                                    .foregroundStyle(
                                        viewModel.selectedCategory == category ? .white : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                }

                // 既存の List
                List(...) { ... }
            }
```
▶ ここで確認: チップタップで絞り込まれること

### 5-2: ソートメニューを toolbar に追加
```swift
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("並び順", selection: $viewModel.sortOrder) {
                            ForEach(SortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
```
▶ ここで確認: メニューからソートを変えるとリスト順が変わること

---

## Step 6 — 詳細画面を追加する
**ファイル:** `Views/ProductDetailView.swift` を新規作成

### 6-1: 詳細 Form（最小限）
```swift
struct ProductDetailView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(product.name).font(.title2.bold())
                Text(product.formattedPrice).font(.title.bold()).foregroundStyle(.blue)
                Text(String(repeating: "★", count: Int(product.rating))).foregroundStyle(.orange)
            }
            .padding()
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

### 6-2: List の行を NavigationLink でラップ
```swift
            List(viewModel.filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                    ProductRowView(product: product, viewModel: viewModel)
                }
                // ...
            }
```
▶ ここで確認: 検索 → 絞り込み → タップで詳細の一連の流れが動くこと

---

## 完成チェックリスト
- [ ] .searchable で検索バーが表示される
- [ ] 文字入力でリストがリアルタイム絞り込みされる
- [ ] カテゴリチップで絞り込める
- [ ] ソートメニューでリスト順が変わる
- [ ] 0件時に ContentUnavailableView が表示される
- [ ] お気に入りのトグルが動く

---

## 改良ノート（写経後の修正）
- カテゴリの絵文字/色が非網羅な三項演算子で出し分けられ `.sports` が欠落していたバグを、`ProductCategory` の `emoji`/`color` プロパティに一本化して修正。
- `listRowInsets` と行内 `.padding()` の二重パディングを解消し、詳細画面の左右マージンを一覧と統一。
- `FilterBar` を `Views/Components/` へ分離。
