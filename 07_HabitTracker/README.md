# 07 HabitTracker

## 学習テーマ
- `ObservableObject` — Viewに変更を通知できるクラスの仕組み
- `@StateObject` — ViewがObservableObjectを所有する時
- `@ObservedObject` — 外部から渡されたObservableObjectを購読する時
- `ProgressView` — 進捗バー・円形インジケーター
- `SwiftData` — `@Model` / `@Query` / `ModelContext` によるローカル永続化

## 完成イメージ
- 習慣一覧（ProgressView付きカード、再起動してもデータが残る）
- 全体進捗サマリー（円形ProgressView）
- 習慣の追加・削除
- カウンターで回数をインクリメント
- 詳細画面で大きなプログレスサークル

## ファイル構成
```
07_HabitTracker/
├── Models/
│   └── Habit.swift              # SwiftDataの @Model（progress計算・color変換含む）
├── ViewModels/
│   └── HabitStore.swift         # ObservableObject（streak管理・ModelContext経由のCRUD）
└── Views/
    ├── HabitListView.swift      # 一覧（@StateObject + @Query）
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
4. `@main` App struct を以下のように変更する

```swift
import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            HabitListView()
        }
        .modelContainer(for: Habit.self)
    }
}
```

## 学習ポイント

### ObservableObject + @Published
```swift
class HabitStore: ObservableObject {
    @Published var newTitle: String = ""  // 変更時にViewを再描画
}
```
`ObservableObject` プロトコルに準拠したクラスは、`@Published` プロパティが変化した時にViewへ通知する。SwiftData化後の `HabitStore` は習慣の配列を持たず、`increment` / `addHabit` などの操作ロジックだけを提供する。

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

### SwiftData — @Model とColorの保存
```swift
@Model
final class Habit {
    var id: UUID
    var name: String
    var colorName: String   // Colorは直接保存できないので名前(String)で持つ
}

extension Habit {
    var color: Color {
        switch colorName {
        case "blue": return .blue
        default: return .blue
        }
    }
}
```
SwiftDataの `@Model` はCodableに準拠しない `Color` を直接保存できない。色名を `String` で保存し、表示時に computed property で `Color` に変換する。

### SwiftData — @Query と ModelContext
```swift
struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    func addHabit() {
        modelContext.insert(Habit(name: "新しい習慣", emoji: "⭐️"))
    }
}
```
`@Query` は常に最新のSwiftDataの内容を返す。`increment` / `decrement` のようにプロパティを書き換えるだけの操作は `modelContext` を使わなくても自動的に保存される。レコードの追加・削除だけ `context.insert` / `context.delete` が必要。

## 発展課題
- 日付ごとの記録（履歴機能）
- ウィジェット拡張（WidgetKit）
- CloudKit連携でiCloud同期に対応する
