# 01 TodoApp ロードマップ

完成形: TODOリストの表示・追加・削除・詳細画面遷移

---

## Step 1 — データモデルを作る
**ファイル:** `Models/TodoItem.swift` を新規作成して、最初から書く

### 1-1: @Model の骨格
```swift
import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
}
```
▶ ここで確認: エラーなくビルドできること
▶ 理解: `@Model` を付けると、SwiftDataがこのクラスを自動的に永続化対象として扱う。`struct` ではなく `final class` にする必要がある（SwiftDataは参照型のみ管理できる）。

### 1-2: init を追加（デフォルト引数付き）
```swift
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
```

### 1-3: createdAt と extension でサンプルデータを追加
```swift
    // init に追加
    var createdAt: Date
    // init 引数に追加
    createdAt: Date = Date()
    self.createdAt = createdAt
```
```swift
extension TodoItem {
    static let samples: [TodoItem] = [
        TodoItem(title: "SwiftUIを学ぶ", isCompleted: true),
        TodoItem(title: "TODOアプリを作る"),
        TodoItem(title: "NavigationStackを理解する"),
        TodoItem(title: "SwipeActionsを実装する"),
        TodoItem(title: "Listのカスタマイズを試す"),
    ]
}
```
▶ ここで確認: `TodoItem.samples` を Playground や Preview でプリントできること

---

## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/TodoViewModel.swift` を新規作成

### 2-1: ObservableObject の骨格
```swift
import Foundation
import SwiftData
import SwiftUI

final class TodoViewModel: ObservableObject {
    @Published var newTitle: String = ""
}
```
▶ ここで確認: エラーなくビルドできること
▶ 理解: SwiftData化したことで、ViewModelはもう `items` 配列を持たない。一覧の表示は次のStepでViewが `@Query` から直接取得する。ViewModelは「追加・削除・トグル」という操作ロジックだけを担当する。

### 2-2: CRUD メソッドを追加（ModelContextを引数で受け取る）
```swift
    func addItem(context: ModelContext) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(TodoItem(title: trimmed))
        newTitle = ""
    }

    func toggleItem(_ item: TodoItem) {
        item.isCompleted.toggle()
        // TodoItemはクラス（参照型）なので、プロパティを書き換えるだけでSwiftDataが自動的に保存する
    }

    func deleteItems(_ items: [TodoItem], context: ModelContext) {
        for item in items {
            context.delete(item)
        }
    }
```
▶ 理解: `ModelContext` は「保存・削除を実行する窓口」。Viewが `@Environment(\.modelContext)` から取得し、メソッドを呼ぶたびに引数として渡す。

---

## Step 3 — 行の UI を作る
**ファイル:** `Views/TodoRowView.swift` を新規作成

### 3-1: 完了アイコン + タイトルの横並び
```swift
import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Text(item.title)
        }
    }
}

#Preview {
    List {
        TodoRowView(item: TodoItem.samples[0]) {}
        TodoRowView(item: TodoItem.samples[1]) {}
    }
}
```
▶ ここで確認: Preview でチェックマーク付きとなしの行が見えること

### 3-2: 取り消し線 + 作成日を追加
```swift
            // Text(item.title) を VStack に差し替え
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
```
▶ ここで確認: 完了アイテムに取り消し線が入ること

---

## Step 4 — 入力フォームを作る
**ファイル:** `Views/AddTodoView.swift` を新規作成

### 4-1: TextField + 追加ボタンの骨格
```swift
import SwiftUI

struct AddTodoView: View {
    @ObservedObject var viewModel: TodoViewModel

    var body: some View {
        HStack(spacing: 12) {
            TextField("新しいタスクを入力", text: $viewModel.newTitle)
                .textFieldStyle(.roundedBorder)

            Button(action: viewModel.addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}

#Preview {
    VStack {
        Spacer()
        AddTodoView(viewModel: TodoViewModel())
    }
}
```
▶ ここで確認: Preview でフォームが表示されること

### 4-2: 入力が空の時はボタンを無効化
```swift
            Button(action: viewModel.addItem) { ... }
                .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
```

### 4-3: Return キーで追加 + フォーカス状態を管理
```swift
    @FocusState private var isFocused: Bool

    // TextField に追加
    TextField(...)
        .focused($isFocused)
        .onSubmit {
            viewModel.addItem()
            isFocused = true  // 追加後もフォーカスを維持
        }
```
▶ ここで確認: Returnキーでタスクが追加されること

---

## Step 5 — List + NavigationStack で一覧画面を作る
**ファイル:** `Views/TodoListView.swift` を新規作成

### 5-1: List + @Query の骨格
```swift
import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]
    @StateObject private var viewModel = TodoViewModel()

    var body: some View {
        List {
            ForEach(items) { item in
                TodoRowView(item: item) {
                    viewModel.toggleItem(item)
                }
            }
        }
        .task {
            // ストアが空（初回起動）ならサンプルデータを投入する
            guard items.isEmpty else { return }
            for sample in TodoItem.samples {
                modelContext.insert(sample)
            }
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
```
▶ ここで確認: Preview でリストが表示されること
▶ 理解: `@Query` は常に最新のSwiftDataの内容を自動取得するプロパティ。`viewModel.items` のように手動で配列を保持する必要がなくなる。Previewでは `.modelContainer(for:, inMemory: true)` を付けて、実機のデータに影響しないメモリ上だけのストアを使う。

### 5-2: NavigationStack + タイトル + EditButton を追加
```swift
    var body: some View {
        NavigationStack {
            List { ... }
            .navigationTitle("TODO")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
```
▶ ここで確認: ナビゲーションバーに「TODO」と「編集」ボタンが見えること

### 5-3: .onDelete でスワイプ削除を追加
```swift
            ForEach(viewModel.items) { ... }
                .onDelete(perform: viewModel.deleteItems)
```
▶ ここで確認: 左スワイプで「削除」ボタンが出ること

### 5-4: safeAreaInset で入力フォームを下部に固定
```swift
            List { ... }
            .safeAreaInset(edge: .bottom) {
                AddTodoView(viewModel: viewModel)
            }
```
▶ ここで確認: リストの下にフォームが固定表示されること

---

## Step 6 — SwipeActions で左右スワイプを追加
**ファイル:** `Views/TodoListView.swift` を編集

### 6-1: 右スワイプで完了トグル
```swift
            ForEach(viewModel.items) { item in
                // NavigationLink(...) の直後に追加
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.toggleItem(item)
                    } label: {
                        Label(
                            item.isCompleted ? "未完了" : "完了",
                            systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(item.isCompleted ? .orange : .green)
                }
            }
```
▶ ここで確認: 右スワイプで緑の「完了」ボタンが出ること

### 6-2: 左スワイプで削除（allowsFullSwipe: true）
```swift
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                            viewModel.deleteItems(at: IndexSet([index]))
                        }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
```
▶ ここで確認: 左にフルスワイプで即削除されること

---

## Step 7 — 詳細画面と NavigationLink を繋ぐ
**ファイル:** `Views/TodoDetailView.swift` を新規作成、その後 `TodoListView.swift` を編集

### 7-1: TodoDetailView を作る
```swift
import SwiftUI

struct TodoDetailView: View {
    let item: TodoItem
    @ObservedObject var viewModel: TodoViewModel

    var body: some View {
        Form {
            Section("タイトル") { Text(item.title) }
            Section("ステータス") {
                HStack {
                    Text(item.isCompleted ? "完了" : "未完了")
                    Spacer()
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
            }
            Section {
                Button(item.isCompleted ? "未完了に戻す" : "完了にする") {
                    viewModel.toggleItem(item)
                }
                .foregroundStyle(item.isCompleted ? .orange : .green)
            }
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TodoDetailView(item: TodoItem.samples[1], viewModel: TodoViewModel())
    }
}
```
▶ ここで確認: Preview で詳細画面が表示されること

### 7-2: TodoListView の ForEach を NavigationLink でラップ
```swift
            ForEach(viewModel.items) { item in
                NavigationLink(destination: TodoDetailView(item: item, viewModel: viewModel)) {
                    TodoRowView(item: item) {
                        viewModel.toggleItem(item)
                    }
                }
                .swipeActions(...) // 既存のswipeActionsはそのまま
            }
```
▶ ここで確認: 行タップで詳細画面に遷移し、Back ボタンで戻れること

---

## 完成チェックリスト
- [ ] Previewでリストが表示される
- [ ] タスクを追加できる（Returnキーも動く）
- [ ] 左スワイプで削除できる
- [ ] 右スワイプで完了トグルできる
- [ ] タップで詳細画面に遷移する
- [ ] 詳細画面から完了/未完了を切り替えられる
- [ ] アプリを再起動してもタスクが残っている（SwiftDataの永続化を確認）
