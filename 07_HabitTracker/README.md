# 07 HabitTracker

## 学習テーマ
- `ObservableObject` — Viewに変更を通知できるクラスの仕組み
- `@StateObject` — ViewがObservableObjectを所有する時
- `@ObservedObject` — 外部から渡されたObservableObjectを購読する時
- `ProgressView` — 進捗バー・円形インジケーター

## 完成イメージ
- 習慣一覧（ProgressView付きカード）
- 全体進捗サマリー（円形ProgressView）
- 習慣の追加・削除
- カウンターで回数をインクリメント
- 詳細画面で大きなプログレスサークル

## ファイル構成
```
07_HabitTracker/
├── Models/
│   └── Habit.swift              # 習慣データモデル（progress計算含む）
├── ViewModels/
│   └── HabitStore.swift         # ObservableObject（習慣のCRUD・streak管理）
└── Views/
    ├── HabitListView.swift      # 一覧（@StateObject）
    ├── HabitRowView.swift       # 各行カード（ProgressView）
    ├── HabitDetailView.swift    # 詳細画面（円形ProgressView）
    ├── AddHabitView.swift       # 追加シート
    └── Components/
        ├── SummaryCard.swift           # 全体進捗サマリーカード
        └── CircularProgressStyle.swift # 円形ProgressViewStyle
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `HabitListView()` に変更

## 学習ポイント

### ObservableObject + @Published
```swift
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []  // 変更時にViewを再描画
}
```
`ObservableObject` プロトコルに準拠したクラスは、`@Published` プロパティが変化した時にViewへ通知する。

### @StateObject vs @ObservedObject
```swift
// @StateObject: このViewがインスタンスを生成・所有する
struct HabitListView: View {
    @StateObject private var store = HabitStore()
    // ViewのライフサイクルとStoreが一致する
}

// @ObservedObject: 外からインスタンスを受け取る
struct HabitRowView: View {
    @ObservedObject var store: HabitStore
    // 親Viewのstoreと同じインスタンスを参照
}
```
**重要**: 子ViewでHabitStoreが必要な場合は`@ObservedObject`で受け取る。
子Viewで`@StateObject`を使うと毎回新しいインスタンスが生成されてしまう。

### ProgressView
```swift
// 線形プログレスバー
ProgressView(value: 0.7)  // 0.0〜1.0
    .tint(.blue)

// 不定（くるくる）
ProgressView()

// カスタムスタイル
ProgressView(value: progress)
    .progressViewStyle(CircularProgressStyle())
```

## 発展課題
- 日付ごとの記録（履歴機能）
- `UserDefaults` や SwiftData で永続化
- ウィジェット拡張（WidgetKit）
