# 08 ProductSearch ロードマップ

完成形: .searchable + 複数フィルター + ソートで商品を絞り込む

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Product.swift` を新規作成

### 1-1: カテゴリ enum（絵文字・色を一本化）
```swift
import SwiftUI

enum ProductCategory: String, CaseIterable, Identifiable {
    case all         = "すべて"
    case electronics = "電子機器"
    case books       = "本"
    case clothing    = "ファッション"
    case food        = "食品"
    case sports      = "スポーツ"

    var id: String { rawValue }

    // 絵文字/色をここに一本化する（行・詳細の両Viewから共通利用）。
    // 個別Viewでswitch/三項演算を重複させると non-exhaustive な抜け漏れが起きやすい。
    var emoji: String {
        switch self {
        case .all: return "🛍"
        case .electronics: return "📱"
        case .books: return "📚"
        case .clothing: return "👔"
        case .food: return "🍵"
        case .sports: return "🏃"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .electronics: return .blue
        case .books: return .orange
        case .clothing: return .purple
        case .food: return .green
        case .sports: return .red
        }
    }
}
```
▶ ここで確認: `ProductCategory.electronics.emoji` が `"📱"`、`.color` が `.blue` になること

### 1-2: Product struct（description + デフォルト値付きinit）
```swift
struct Product: Identifiable {
    let id: UUID
    var name: String
    var brand: String
    var category: ProductCategory
    var price: Double
    var rating: Double
    var reviewCount: Int
    var isFavorite: Bool
    var description: String

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: ProductCategory,
        price: Double,
        rating: Double = 0,
        reviewCount: Int = 0,
        isFavorite: Bool = false,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.rating = rating
        self.reviewCount = reviewCount
        self.isFavorite = isFavorite
        self.description = description
    }

    var formattedPrice: String {
        "¥\(Int(price).formatted())"
    }
}
```
カスタムinitでデフォルト値を持たせることで、サンプルデータ側で `rating` や `isFavorite` を省略できる（評価が未定の新着商品などを書きやすくする）。

▶ ここで確認: `Product(name: "Test", brand: "Test", category: .all, price: 100)` のように一部の引数を省略してもコンパイルできること

### 1-3: サンプルデータ
```swift
extension Product {
    static let samples: [Product] = [
        Product(name: "iPhone 16 Pro", brand: "Apple", category: .electronics, price: 159800, rating: 4.8, reviewCount: 2341, isFavorite: true, description: "最新のA18 Proチップを搭載したフラッグシップiPhone。"),
        Product(name: "MacBook Air M3", brand: "Apple", category: .electronics, price: 164800, rating: 4.9, reviewCount: 1892, description: "超薄型・軽量で高性能なノートPC。"),
        Product(name: "SwiftUI実践入門", brand: "技術評論社", category: .books, price: 3800, rating: 4.4, reviewCount: 345, isFavorite: true, description: "SwiftUIを実践的に学べる入門書。"),
        // ...他にも数件追加（カテゴリごとに最低1件あるとフィルターの動作確認がしやすい）
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
import Combine

class ProductViewModel: ObservableObject {
    @Published var allProducts: [Product] = Product.samples
    @Published var searchText: String = ""
    @Published var selectedCategory: ProductCategory = .all
}
```

### 2-2: filteredProducts の computed property を段階的に作る
```swift
    // searchText / selectedCategory / sortOrder が変わると自動的に再計算
    var filteredProducts: [Product] {
        var result = allProducts

        // カテゴリフィルター
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }

        return result
    }
```
▶ ここで確認: `selectedCategory = .books` にすると本だけが返ること

### 2-3: テキスト検索を追加
```swift
        // テキスト検索（名前・ブランドに部分一致）
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
```
▶ ここで確認: `searchText = "apple"` にすると Apple製品だけが返ること

### 2-4: お気に入りフィルターを追加
```swift
    // ViewModel に追加
    @Published var showFavoritesOnly: Bool = false

    // filteredProducts 内、テキスト検索より前に追加
        // お気に入りフィルター
        if showFavoritesOnly {
            result = result.filter(\.isFavorite)
        }
```
▶ ここで確認: `showFavoritesOnly = true` にすると `isFavorite == true` の商品だけが返ること

### 2-5: ソート enum + ソートを追加
```swift
enum SortOrder: String, CaseIterable, Identifiable {
    case nameAsc    = "名前順（昇順）"
    case priceAsc   = "価格順（安い順）"
    case priceDesc  = "価格順（高い順）"
    case ratingDesc = "評価順"

    var id: String { rawValue }
}

// ViewModel に追加
    @Published var sortOrder: SortOrder = .nameAsc

    // filteredProducts の return 直前に追加
        // ソート
        switch sortOrder {
        case .nameAsc:
            result.sort { $0.name < $1.name }
        case .priceAsc:
            result.sort { $0.price < $1.price }
        case .priceDesc:
            result.sort { $0.price > $1.price }
        case .ratingDesc:
            result.sort { $0.rating > $1.rating }
        }
```
▶ ここで確認: `sortOrder = .priceDesc` にすると価格が高い順に並ぶこと

### 2-6: お気に入りトグル
```swift
    func toggleFavorite(_ product: Product) {
        guard let index = allProducts.firstIndex(where: { $0.id == product.id }) else { return }
        allProducts[index].isFavorite.toggle()
    }
```

### 2-7: 星文字列の共通ヘルパー
```swift
    func starsString(for rating: Double) -> String {
        let filled = Int(rating)
        return String(repeating: "★", count: filled) + String(repeating: "☆", count: 5 - filled)
    }
```
`ProductRowView` と `ProductDetailView` の両方で星表示が必要になるので、`String(repeating:)` をその場で書かずViewModelに一本化しておく（塗り済み★だけでなく未塗り☆も出すことで星の数が揃って見える）。

▶ ここで確認: `viewModel.starsString(for: 3.0)` が `"★★★☆☆"` になること

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
            // 商品アイコン（カテゴリ別）
            RoundedRectangle(cornerRadius: 10)
                .fill(product.category.color.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay {
                    Text(product.category.emoji)
                        .font(.title2)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(product.brand)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(viewModel.starsString(for: product.rating))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text("(\(product.reviewCount))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(product.formattedPrice)
                    .font(.subheadline.bold())

                Button {
                    viewModel.toggleFavorite(product)
                } label: {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(product.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    List {
        ProductRowView(product: Product.samples[0], viewModel: ProductViewModel())
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
}
```
アイコンは固定の絵文字・色ではなく `product.category.emoji` / `.color` を使うことで、カテゴリごとに自動で見た目が変わる。レビュー件数も `(\(product.reviewCount))` の形で星の横に添えておくと一覧でも信頼度が分かりやすい。

▶ ここで確認: Preview でカードが表示され、カテゴリによってアイコンの絵文字と背景色が変わること

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
**ファイル:** `Views/Components/FilterBar.swift` を新規作成 / `Views/ProductListView.swift` を編集

### 5-1: カテゴリフィルターを Component に分離
カテゴリチップをそのまま `ProductListView` に書くと body が肥大化するので、再利用可能な `FilterBar` Component に切り出す。

```swift
import SwiftUI

struct FilterBar: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProductCategory.allCases) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedCategory == category ? Color.blue : Color(.secondarySystemBackground)
                            )
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    FilterBar(viewModel: ProductViewModel())
}
```
▶ ここで確認: Preview でチップが横スクロールし、タップで選択状態（青背景）に切り替わること

### 5-2: ProductListView に FilterBar を組み込む
```swift
// ProductListView の NavigationStack 内を VStack に変える
            VStack(spacing: 0) {
                // フィルターツールバー
                FilterBar(viewModel: viewModel)

                // 既存の List
                List(...) { ... }
            }
```
▶ ここで確認: チップタップで一覧が絞り込まれること

### 5-3: ソートメニュー + お気に入りトグルを toolbar に追加
```swift
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
```
ソートの `Picker` とお気に入りの `Toggle` を同じ `Menu` の中にまとめることで、ツールバーのボタンを増やさずに済む。

▶ ここで確認: メニューからソートを変えるとリスト順が変わり、「お気に入りのみ」をオンにするとお気に入り登録済みの商品だけが残ること

---

## Step 6 — 詳細画面を追加する
**ファイル:** `Views/ProductDetailView.swift` を新規作成

### 6-1: 最新状態を取得する current プロパティ
```swift
struct ProductDetailView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel

    // 最新の状態を取得
    var current: Product {
        viewModel.allProducts.first(where: { $0.id == product.id }) ?? product
    }
}
```
詳細画面は一覧から渡された `product`（値のスナップショット）をそのまま表示すると、詳細画面でお気に入りをトグルしても表示が更新されない。`viewModel.allProducts` から同じ `id` の最新値を都度取り直すことで、お気に入りボタンの見た目が即座に反映される。

### 6-2: 画像プレースホルダー + 名前・お気に入りボタン
```swift
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 商品画像プレースホルダー
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 240)
                    .overlay {
                        VStack(spacing: 8) {
                            Text(current.category.emoji)
                                .font(.system(size: 72))
                            Text(current.brand)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                VStack(alignment: .leading, spacing: 12) {
                    // 名前 + お気に入り
                    HStack {
                        Text(current.name)
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            viewModel.toggleFavorite(current)
                        } label: {
                            Image(systemName: current.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(current.isFavorite ? .red : .secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
    }
```
▶ ここで確認: Preview で画像プレースホルダーとカテゴリ絵文字、お気に入りボタンが表示されること

### 6-3: 価格・評価・説明・カテゴリ情報を追加
```swift
                    // 価格
                    Text(current.formattedPrice)
                        .font(.title.bold())
                        .foregroundStyle(.blue)

                    // 評価
                    HStack(spacing: 6) {
                        Text(viewModel.starsString(for: current.rating))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", current.rating))
                            .font(.headline)
                        Text("(\(current.reviewCount)件のレビュー)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // 商品説明
                    Text("商品説明")
                        .font(.headline)
                    Text(current.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // カテゴリ
                    HStack {
                        Label(current.category.rawValue, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label(current.brand, systemImage: "building.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
```
▶ ここで確認: 評価の星・数値・レビュー件数、商品説明、カテゴリ/ブランドの Label が表示されること

### 6-4: カートに追加ボタン
```swift
                // カートに追加ボタン
                Button {
                    // 実装例（実際の購入処理はここに追加）
                } label: {
                    Label("カートに追加", systemImage: "cart.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
```
画像・本文・ボタンの左右マージンは `VStack` 全体への `.padding(.horizontal)` だけで統一する（行・カードのように個別に `.padding()` を重ねると左右マージンが二重になる）。

▶ ここで確認: Preview でカートボタンが表示されること

### 6-5: List の行を NavigationLink でラップ
```swift
            List(viewModel.filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                    ProductRowView(product: product, viewModel: viewModel)
                }
                // ...
            }
```
▶ ここで確認: 検索 → 絞り込み → タップで詳細の一連の流れが動くこと。詳細画面でお気に入りをトグルし、戻った一覧にも反映されていること

---

## 完成チェックリスト
- [ ] .searchable で検索バーが表示される
- [ ] 文字入力でリストがリアルタイム絞り込みされる
- [ ] カテゴリチップ（FilterBar）で絞り込める
- [ ] ソートメニューでリスト順が変わる
- [ ] 「お気に入りのみ」トグルで絞り込める
- [ ] 0件時に ContentUnavailableView が表示される
- [ ] 一覧・詳細どちらでもお気に入りのトグルが動き、両画面で表示が一致する
- [ ] カテゴリの絵文字・色が `ProductCategory.emoji` / `.color` から一覧・詳細に反映される

---

## 補足メモ
- カテゴリの絵文字/色は `ProductCategory` の `emoji`/`color` プロパティに一本化している。Viewごとに switch や三項演算子で出し分けると非網羅なケース（`.sports` の欠落など）が起きやすいため避ける。
- `FilterBar` は `Views/Components/` に配置し、`ProductListView` から再利用できる形にしている。
- 星表示は `viewModel.starsString(for:)` に一本化し、`ProductRowView` と `ProductDetailView` で同じロジックを共有する。
