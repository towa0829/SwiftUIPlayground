# 01 TodoApp

## 学習テーマ
- `List` — データを一覧表示する基本コンポーネント
- `NavigationStack` — 画面遷移のスタック管理
- `SwipeActions` — スワイプで操作を表示する
- `SwiftData` — `@Model` / `@Query` / `ModelContext` によるローカル永続化

## 完成イメージ
- TODOリストの表示・追加・削除（再起動してもデータが残る）
- 左スワイプで削除、右スワイプで完了トグル
- タップで詳細画面へ遷移

## ファイル構成
```
01_TodoApp/
├── Models/
│   └── TodoItem.swift        # SwiftDataの @Model + サンプルデータ
├── ViewModels/
│   └── TodoViewModel.swift   # リスト操作ロジック（ModelContext経由のCRUD）
└── Views/
    ├── TodoListView.swift    # メイン画面（List + SwipeActions + @Query）
    ├── TodoRowView.swift     # 各行のUI
    ├── TodoDetailView.swift  # 詳細画面
    └── AddTodoView.swift     # 追加フォーム
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
struct TodoAppApp: App {
    var body: some Scene {
        WindowGroup {
            TodoListView()
        }
        .modelContainer(for: TodoItem.self)
    }
}
```

`.modelContainer(for:)` がSwiftDataの保存先（ローカルDB）を用意し、配下の全View（`TodoListView` など）が `@Environment(\.modelContext)` でそこにアクセスできるようになる。

## 学習ポイント

### List
```swift
List {
    ForEach(items) { item in
        Text(item.title)
    }
    .onDelete(perform: deleteItems)
}
```
`ForEach` + `onDelete` でスワイプ削除が自動的に有効になる。

### NavigationStack + NavigationLink
```swift
NavigationStack {
    List {
        NavigationLink(destination: DetailView()) {
            Text("タップで遷移")
        }
    }
    .navigationTitle("タイトル")
}
```

### SwipeActions
```swift
.swipeActions(edge: .trailing) {
    Button(role: .destructive) { /* 削除 */ } label: {
        Label("削除", systemImage: "trash")
    }
}
.swipeActions(edge: .leading) {
    Button { /* 完了 */ } label: {
        Label("完了", systemImage: "checkmark")
    }
    .tint(.green)
}
```
`edge:` で左右を指定。`allowsFullSwipe: true` でフルスワイプ対応。

### SwiftData — @Model
```swift
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
}
```
`@Model` を付けたクラスはSwiftDataが自動で永続化を管理する。`struct` ではなく `class`（参照型）にする必要がある。

### SwiftData — @Query と ModelContext
```swift
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]

    func addItem() {
        modelContext.insert(TodoItem(title: "新しいタスク"))
        // 保存処理は不要。contextへの変更は自動的にディスクへ書き込まれる
    }
}
```
`@Query` は常に最新のSwiftDataの内容を返す。`modelContext.insert` / `.delete` でレコードを追加・削除する。プロパティを直接書き換えるだけ（例: `item.isCompleted.toggle()`）でも変更は自動で保存される。

## 発展課題
- 完了済み / 未完了でセクション分け
- 優先度フィールドの追加
- CloudKit連携でiCloud同期に対応する
