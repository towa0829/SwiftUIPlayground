# 06 PostModal

## 学習テーマ
- `Sheet` — 下からスライドアップするモーダル
- `FullScreenCover` — 画面全体を覆うモーダル
- `@Binding` — 親Viewのstateへの参照を子に渡す

## 完成イメージ
- フィードの投稿一覧
- 「+」ボタンでシート（新規投稿フォーム）
- カードタップでフルスクリーンカバー（詳細表示）
- `presentationDetents` でシートの高さ制御

## ファイル構成
```
06_PostModal/
├── Models/
│   └── FeedPost.swift              # 投稿データモデル
├── ViewModels/
│   └── FeedViewModel.swift         # フィードのCRUDロジック
└── Views/
    ├── FeedView.swift              # フィード一覧（エントリーポイント）
    ├── FeedPostCard.swift          # フィードの投稿カード
    ├── NewPostSheet.swift          # 新規投稿シート（@Binding活用）
    ├── PostDetailFullScreen.swift  # 詳細フルスクリーン（currentPostで都度参照）
    └── Components/
        └── CharacterCountView.swift # 文字数カウンター（上限超で警告色）
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `FeedView()` に変更

## 学習ポイント

### Sheet — 下から表示
```swift
@State private var showSheet = false

Button("開く") { showSheet = true }
    .sheet(isPresented: $showSheet) {
        MySheetView()
    }
```

### FullScreenCover — 全画面
```swift
@State private var selectedItem: Item? = nil

// item: にBindingを渡すと、nilでない時に表示される
.fullScreenCover(item: $selectedItem) { item in
    DetailView(item: item)
}
```
`item` が `Identifiable` に準拠している必要がある。

### presentationDetents — シートの高さ
```swift
.sheet(isPresented: $show) {
    MyView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

### @Binding — 親子間のデータ共有
```swift
// 親View
@State private var text = ""
ChildView(text: $text)  // $ をつけてBindingを渡す

// 子View
struct ChildView: View {
    @Binding var text: String  // 親のstateへの参照
    // text を変更すると親のstateも変わる
}
```

### dismiss — モーダルを閉じる
```swift
@Environment(\.dismiss) private var dismiss

Button("閉じる") {
    dismiss()  // sheet / fullScreenCover どちらも同じ
}
```

## 発展課題
- `presentationBackground(.thinMaterial)` でシート背景をカスタマイズ
- `interactiveDismissDisabled(true)` でスワイプ閉じを無効化
- カスタムトランジション（`.transition(.move(edge: .bottom))`）
