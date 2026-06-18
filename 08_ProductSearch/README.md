# 08 ProductSearch

## 学習テーマ
- `.searchable` — 検索バーをナビゲーションに組み込む
- フィルタリング — 複数条件での絞り込みロジック

## 完成イメージ
- 商品一覧 + 検索バー
- カテゴリチップでフィルタリング
- ソートメニュー（名前・価格・評価順）
- お気に入りフィルター
- 結果0件時の `ContentUnavailableView`

## ファイル構成
```
08_ProductSearch/
├── Models/
│   └── Product.swift              # 商品モデル + カテゴリ列挙型（emoji/color含む）
├── ViewModels/
│   └── ProductViewModel.swift     # 検索・フィルタ・ソートロジック
└── Views/
    ├── ProductListView.swift      # 商品一覧（searchable + フィルターバー）
    ├── ProductRowView.swift       # 商品行カード
    ├── ProductDetailView.swift    # 商品詳細
    └── Components/
        └── FilterBar.swift        # カテゴリフィルターバー
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `ProductListView()` に変更

## 学習ポイント

### .searchable — 検索バー
```swift
NavigationStack {
    List(filteredItems) { item in ... }
        // NavigationStack の中のViewに付ける
        .searchable(text: $searchText, prompt: "検索...")
}
```
`searchText` が変わるたびに `filteredItems` が再計算されて一覧が更新される。

### フィルタリングのパターン
```swift
var filteredProducts: [Product] {
    var result = allProducts

    // 1. カテゴリフィルター
    if selectedCategory != .all {
        result = result.filter { $0.category == selectedCategory }
    }

    // 2. テキスト検索
    if !searchText.isEmpty {
        result = result.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // 3. ソート
    result.sort { $0.price < $1.price }

    return result
}
```
複数条件を段階的に適用するパターン。`@Published` を `@StateObject` 内に置き、ViewModelの計算プロパティとして定義する。

### ContentUnavailableView — 空状態のUI
```swift
.overlay {
    if filteredItems.isEmpty {
        ContentUnavailableView.search(text: searchText)
    }
}
```
iOS 17+ で使えるシステム提供の「結果なし」View。

### .searchSuggestions — 検索候補
```swift
.searchable(text: $searchText) {
    ForEach(suggestions, id: \.self) { suggestion in
        Text(suggestion).searchCompletion(suggestion)
    }
}
```

## 発展課題
- `searchScopes` でスコープ（対象フィールド）の切り替え
- Debounce（`Combine` で入力から0.3秒後に検索）
- ハイライト表示（マッチ部分を強調）
