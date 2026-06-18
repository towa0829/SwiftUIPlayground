# 04 PhotoGallery

## 学習テーマ
- `ScrollView` — スクロール可能なコンテナ
- `LazyVGrid` — 遅延読み込みグリッドレイアウト
- `AsyncImage` — URLから非同期で画像を読み込む

## 完成イメージ
- 2カラムグリッドで写真一覧
- カテゴリフィルタータブ
- タップで詳細表示
- 読み込み中・失敗のフォールバックUI

## ファイル構成
```
04_PhotoGallery/
├── Models/
│   └── Photo.swift            # 写真モデル + カテゴリ列挙型 + サンプル
├── ViewModels/
│   └── PhotoViewModel.swift   # フィルタリングロジック
└── Views/
    ├── PhotoGalleryView.swift  # グリッド一覧（LazyVGrid + ScrollView）
    ├── PhotoGridCell.swift     # グリッドセル（AsyncImage）
    ├── PhotoDetailView.swift   # 詳細画面
    └── Components/
        └── CategoryChip.swift  # カテゴリフィルターチップ
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成（Info.plistにネットワーク許可不要）
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `PhotoGalleryView()` に変更

## 学習ポイント

### LazyVGrid — グリッドレイアウト
```swift
// 列の定義
let columns = [
    GridItem(.flexible()),  // 均等幅
    GridItem(.flexible()),
]

ScrollView {
    LazyVGrid(columns: columns, spacing: 8) {
        ForEach(items) { item in
            // セルView
        }
    }
}
```
`Lazy` = 画面に表示される直前にViewを生成。大量データでもメモリ効率が良い。

### GridItem のパターン
```swift
GridItem(.fixed(100))      // 固定幅
GridItem(.flexible())      // 残りスペースを均等分割
GridItem(.adaptive(minimum: 80)) // 最小幅に合わせて自動列数
```

### AsyncImage — 非同期画像読み込み
```swift
AsyncImage(url: URL(string: "https://...")) { phase in
    switch phase {
    case .empty:     ProgressView()          // 読み込み中
    case .success(let image): image.resizable()  // 成功
    case .failure:   Image(systemName: "photo")  // 失敗
    @unknown default: EmptyView()
    }
}
```

## 発展課題
- ピンチジェスチャーでグリッド列数の変更
- `LazyHGrid` で横スクロールギャラリー
- キャッシュ対応（`URLCache` or `Kingfisher`）
