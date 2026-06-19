# 01_TodoApp / 07_HabitTracker SwiftData Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert `01_TodoApp` and `07_HabitTracker` from in-memory `@Published` array storage to SwiftData persistence (`@Model`, `@Query`, `ModelContext`), while keeping the existing MVVM structure and teaching style intact.

**Architecture:** Models become `@Model final class`. ViewModels (`TodoViewModel`, `HabitStore`) keep their operation methods but stop owning the data array; mutation methods that create/delete records take a `ModelContext` parameter, supplied by the calling View via `@Environment(\.modelContext)`. Views read live data via `@Query` instead of `viewModel.items` / `store.habits`. On first launch (empty store), the existing `samples` are inserted once.

**Tech Stack:** SwiftUI, SwiftData (`@Model`, `@Query`, `ModelContext`, `.modelContainer`).

## Global Constraints

- Existing files are edited in place. No new project folders are created.
- `Habit.color: Color` becomes `colorName: String` + a `Habit.color(named:)` static helper / `color` computed property. No raw `Color` is stored in a `@Model`.
- ViewModel methods that insert or delete records take an explicit `context: ModelContext` parameter (no `ModelContext` stored in `init`).
- On empty store, seed with the existing `samples` (`TodoItem.samples` / `Habit.samples`).
- This environment has no Xcode/iOS SDK installed (`xcrun --sdk iphonesimulator` fails, and `swiftc -typecheck` cannot resolve `#Preview` or iOS-only APIs like `EditButton`). There is no way to build or run these files here. **Verification for every task is a manual read-through + `grep` consistency check**, not a compiled build. Final build verification happens later in Xcode (out of scope for this plan).
- Per CLAUDE.md: every View keeps a working `#Preview`, `private` is applied where appropriate, no TODO comments, files stay under ~200 lines.

---

### Task 1: TodoItem → `@Model`

**Files:**
- Modify: `01_TodoApp/Models/TodoItem.swift`

**Interfaces:**
- Produces: `TodoItem` (`@Model final class`) with `id: UUID`, `title: String`, `isCompleted: Bool`, `createdAt: Date`, and `static let samples: [TodoItem]`. Used by Task 2 and Task 3.

- [ ] **Step 1: Rewrite the model file**

Replace the full contents of `01_TodoApp/Models/TodoItem.swift` with:

```swift
import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

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

- [ ] **Step 2: Verify there is no leftover `struct TodoItem`**

Run: `grep -n "struct TodoItem" 01_TodoApp/Models/TodoItem.swift`
Expected: no output (empty result, meaning the struct definition is gone).

- [ ] **Step 3: Commit**

```bash
git add 01_TodoApp/Models/TodoItem.swift
git commit -m "01_TodoApp: TodoItemをSwiftDataの@Modelに変更"
```

---

### Task 2: TodoViewModel → context-based methods

**Files:**
- Modify: `01_TodoApp/ViewModels/TodoViewModel.swift`

**Interfaces:**
- Consumes: `TodoItem` (Task 1).
- Produces: `TodoViewModel.addItem(context: ModelContext)`, `TodoViewModel.toggleItem(_ item: TodoItem)`, `TodoViewModel.deleteItems(_ items: [TodoItem], context: ModelContext)`. Used by Task 3.

- [ ] **Step 1: Rewrite the view model file**

Replace the full contents of `01_TodoApp/ViewModels/TodoViewModel.swift` with:

```swift
import Foundation
import SwiftData
import SwiftUI

final class TodoViewModel: ObservableObject {
    @Published var newTitle: String = ""

    func addItem(context: ModelContext) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(TodoItem(title: trimmed))
        newTitle = ""
    }

    func toggleItem(_ item: TodoItem) {
        item.isCompleted.toggle()
    }

    func deleteItems(_ items: [TodoItem], context: ModelContext) {
        for item in items {
            context.delete(item)
        }
    }
}
```

- [ ] **Step 2: Verify the old array-based API is gone**

Run: `grep -n "items.append\|items.remove\|@Published var items" 01_TodoApp/ViewModels/TodoViewModel.swift`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add 01_TodoApp/ViewModels/TodoViewModel.swift
git commit -m "01_TodoApp: TodoViewModelをModelContext経由のCRUDに変更"
```

---

### Task 3: TodoApp views → `@Query` + `@Environment(\.modelContext)`

**Files:**
- Modify: `01_TodoApp/Views/TodoListView.swift`
- Modify: `01_TodoApp/Views/AddTodoView.swift`
- Verify only (no change expected): `01_TodoApp/Views/TodoRowView.swift`, `01_TodoApp/Views/TodoDetailView.swift`

**Interfaces:**
- Consumes: `TodoItem` (Task 1), `TodoViewModel.addItem/toggleItem/deleteItems` (Task 2).
- Produces: a working `TodoListView` with live SwiftData-backed list and seeding.

- [ ] **Step 1: Rewrite `TodoListView.swift`**

Replace the full contents of `01_TodoApp/Views/TodoListView.swift` with:

```swift
import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]
    @StateObject private var viewModel = TodoViewModel()

    private var completedCount: Int { items.filter(\.isCompleted).count }
    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Label("\(pendingCount) 件残り", systemImage: "circle")
                            .foregroundStyle(.orange)
                        Label("\(completedCount) 件完了", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }

                ForEach(items) { item in
                    NavigationLink(destination: TodoDetailView(item: item, viewModel: viewModel)) {
                        TodoRowView(item: item) {
                            viewModel.toggleItem(item)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteItems([item], context: modelContext)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
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
                .onDelete { offsets in
                    let toDelete = offsets.map { items[$0] }
                    viewModel.deleteItems(toDelete, context: modelContext)
                }
            }
            .navigationTitle("TODO")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                AddTodoView(viewModel: viewModel)
            }
            .task {
                seedIfNeeded()
            }
        }
    }

    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        for sample in TodoItem.samples {
            modelContext.insert(sample)
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
```

- [ ] **Step 2: Rewrite `AddTodoView.swift`**

Replace the full contents of `01_TodoApp/Views/AddTodoView.swift` with:

```swift
import SwiftUI
import SwiftData

struct AddTodoView: View {
    @ObservedObject var viewModel: TodoViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("新しいタスクを入力", text: $viewModel.newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    viewModel.addItem(context: modelContext)
                    isFocused = true
                }

            Button(action: {
                viewModel.addItem(context: modelContext)
                isFocused = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue
                    )
            }
            .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

#Preview {
    VStack {
        Spacer()
        AddTodoView(viewModel: TodoViewModel())
    }
    .modelContainer(for: TodoItem.self, inMemory: true)
}
```

- [ ] **Step 3: Confirm `TodoRowView.swift` and `TodoDetailView.swift` need no changes**

These two files only read `TodoItem` properties and call `viewModel.toggleItem(item)`, both of which keep the same signature whether `TodoItem` is a `struct` or `@Model final class`. No edit needed.

Run: `grep -n "viewModel.items\|viewModel.deleteItems(at" 01_TodoApp/Views/TodoRowView.swift 01_TodoApp/Views/TodoDetailView.swift`
Expected: no output (confirms neither file touches the old array API).

- [ ] **Step 4: Verify no stale references remain anywhere in the project**

Run: `grep -rn "viewModel.items\|\.completedCount }\s*$" 01_TodoApp/Views 2>/dev/null | grep -v "item.completedCount"`
Expected: no output. (This is a sanity grep for leftover `viewModel.items` usage; if anything prints, fix the reference before committing.)

- [ ] **Step 5: Commit**

```bash
git add 01_TodoApp/Views/TodoListView.swift 01_TodoApp/Views/AddTodoView.swift
git commit -m "01_TodoApp: ViewをSwiftDataの@Query/ModelContextに対応"
```

---

### Task 4: 01_TodoApp README / ROADMAP update

**Files:**
- Modify: `01_TodoApp/README.md`
- Modify: `01_TodoApp/ROADMAP.md`

**Interfaces:**
- None (documentation only).

- [ ] **Step 1: Rewrite `01_TodoApp/README.md`**

Replace the full contents of `01_TodoApp/README.md` with:

```markdown
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
```

- [ ] **Step 2: Update Step 1 of `01_TodoApp/ROADMAP.md` (data model)**

In `01_TodoApp/ROADMAP.md`, find this block:

```markdown
## Step 1 — データモデルを作る
**ファイル:** `Models/TodoItem.swift` を新規作成して、最初から書く

### 1-1: struct の骨格
```swift
import Foundation

struct TodoItem: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}
```
▶ ここで確認: エラーなくビルドできること
```

Replace it with:

```markdown
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
```

- [ ] **Step 3: Update Step 2 of `01_TodoApp/ROADMAP.md` (view model)**

In `01_TodoApp/ROADMAP.md`, find this block:

```markdown
## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/TodoViewModel.swift` を新規作成

### 2-1: ObservableObject の骨格
```swift
import Foundation
import Combine

class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = TodoItem.samples
    @Published var newTitle: String = ""
}
```
▶ ここで確認: エラーなくビルドできること

### 2-2: CRUD メソッドを追加
```swift
    func addItem() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        newTitle = ""
    }

    func toggleItem(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isCompleted.toggle()
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
```

### 2-3: 集計プロパティを追加
```swift
    var completedCount: Int { items.filter(\.isCompleted).count }
    var pendingCount:   Int { items.filter { !$0.isCompleted }.count }
```
```

Replace it with:

```markdown
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
```

- [ ] **Step 4: Update Step 5 of `01_TodoApp/ROADMAP.md` (list screen)**

In `01_TodoApp/ROADMAP.md`, find this block:

```markdown
## Step 5 — List + NavigationStack で一覧画面を作る
**ファイル:** `Views/TodoListView.swift` を新規作成

### 5-1: List の骨格
```swift
import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel = TodoViewModel()

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                TodoRowView(item: item) {
                    viewModel.toggleItem(item)
                }
            }
        }
    }
}

#Preview {
    TodoListView()
}
```
▶ ここで確認: Preview でリストが表示されること
```

Replace it with:

```markdown
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
```

- [ ] **Step 5: Update the completion checklist of `01_TodoApp/ROADMAP.md`**

In `01_TodoApp/ROADMAP.md`, find:

```markdown
## 完成チェックリスト
- [ ] Previewでリストが表示される
- [ ] タスクを追加できる（Returnキーも動く）
- [ ] 左スワイプで削除できる
- [ ] 右スワイプで完了トグルできる
- [ ] タップで詳細画面に遷移する
- [ ] 詳細画面から完了/未完了を切り替えられる
```

Replace it with:

```markdown
## 完成チェックリスト
- [ ] Previewでリストが表示される
- [ ] タスクを追加できる（Returnキーも動く）
- [ ] 左スワイプで削除できる
- [ ] 右スワイプで完了トグルできる
- [ ] タップで詳細画面に遷移する
- [ ] 詳細画面から完了/未完了を切り替えられる
- [ ] アプリを再起動してもタスクが残っている（SwiftDataの永続化を確認）
```

- [ ] **Step 6: Commit**

```bash
git add 01_TodoApp/README.md 01_TodoApp/ROADMAP.md
git commit -m "01_TodoApp: README/ROADMAPをSwiftData対応に更新"
```

---

### Task 5: Habit → `@Model` with `colorName: String`

**Files:**
- Modify: `07_HabitTracker/Models/Habit.swift`

**Interfaces:**
- Produces: `Habit` (`@Model final class`) with `id, name, emoji, targetCount, completedCount, streak, colorName: String`, computed `progress: Double`, `isCompleted: Bool`, `color: Color`, plus `static let colorOptions: [String]`, `static func color(named:) -> Color`, and `static let samples: [Habit]`. Used by Task 6 and Task 7.

- [ ] **Step 1: Rewrite the model file**

Replace the full contents of `07_HabitTracker/Models/Habit.swift` with:

```swift
import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var targetCount: Int        // 1日の目標回数
    var completedCount: Int     // 今日の完了回数
    var streak: Int             // 連続日数
    var colorName: String

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        targetCount: Int = 1,
        completedCount: Int = 0,
        streak: Int = 0,
        colorName: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.targetCount = targetCount
        self.completedCount = completedCount
        self.streak = streak
        self.colorName = colorName
    }

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1.0)
    }

    var isCompleted: Bool {
        completedCount >= targetCount
    }
}

extension Habit {
    static let colorOptions: [String] = ["blue", "red", "green", "orange", "purple", "pink", "yellow", "teal"]

    static func color(named colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }

    var color: Color {
        Habit.color(named: colorName)
    }
}

extension Habit {
    static let samples: [Habit] = [
        Habit(name: "朝の瞑想", emoji: "🧘", targetCount: 1, completedCount: 1, streak: 7, colorName: "purple"),
        Habit(name: "読書", emoji: "📚", targetCount: 30, completedCount: 12, streak: 3, colorName: "orange"),
        Habit(name: "ウォーキング", emoji: "🚶", targetCount: 10000, completedCount: 6540, streak: 14, colorName: "green"),
        Habit(name: "水を飲む", emoji: "💧", targetCount: 8, completedCount: 5, streak: 21, colorName: "blue"),
        Habit(name: "英語学習", emoji: "🌍", targetCount: 1, completedCount: 0, streak: 0, colorName: "red"),
    ]
}
```

- [ ] **Step 2: Verify there is no leftover `struct Habit` or stored `Color` property**

Run: `grep -n "struct Habit\|var color: Color$" 07_HabitTracker/Models/Habit.swift`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add 07_HabitTracker/Models/Habit.swift
git commit -m "07_HabitTracker: HabitをSwiftDataの@Modelに変更（colorはString保存）"
```

---

### Task 6: HabitStore → context-based add/delete

**Files:**
- Modify: `07_HabitTracker/ViewModels/HabitStore.swift`

**Interfaces:**
- Consumes: `Habit` (Task 5).
- Produces: `HabitStore.increment/decrement/complete/reset(_ habit: Habit)` (unchanged signatures), `HabitStore.addHabit(name:emoji:target:colorName:context:)`, `HabitStore.deleteHabit(_:context:)`. Used by Task 7.

- [ ] **Step 1: Rewrite the view model file**

Replace the full contents of `07_HabitTracker/ViewModels/HabitStore.swift` with:

```swift
import Foundation
import SwiftData
import SwiftUI

// ObservableObject: 変更を@StateObject/@ObservedObjectで購読できるクラス
final class HabitStore: ObservableObject {
    // streak更新の単一ルール:
    // 「未達 → 達成」に転じた瞬間に +1、「達成 → 未達」に戻った瞬間に -1。
    // increment/decrement/complete/reset すべてがこのルールに従うため、
    // 行のトグル操作と詳細画面のボタン操作で結果が一致する。
    private func syncStreak(_ habit: Habit, wasCompleted: Bool) {
        let isCompleted = habit.isCompleted
        if !wasCompleted && isCompleted {
            habit.streak += 1
        } else if wasCompleted && !isCompleted {
            habit.streak = max(0, habit.streak - 1)
        }
    }

    func increment(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount < habit.targetCount {
            habit.completedCount += 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func decrement(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount > 0 {
            habit.completedCount -= 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func complete(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = habit.targetCount
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func reset(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = 0
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func addHabit(name: String, emoji: String, target: Int, colorName: String, context: ModelContext) {
        context.insert(Habit(name: name, emoji: emoji, targetCount: target, colorName: colorName))
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
    }
}
```

- [ ] **Step 2: Verify the old array-based API is gone**

Run: `grep -n "@Published var habits\|habits.firstIndex\|habits.append\|habits.removeAll" 07_HabitTracker/ViewModels/HabitStore.swift`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add 07_HabitTracker/ViewModels/HabitStore.swift
git commit -m "07_HabitTracker: HabitStoreの追加/削除をModelContext経由に変更"
```

---

### Task 7: HabitTracker views → `@Query` + colorName UI

**Files:**
- Modify: `07_HabitTracker/Views/HabitListView.swift`
- Modify: `07_HabitTracker/Views/AddHabitView.swift`
- Modify: `07_HabitTracker/Views/Components/SummaryCard.swift`
- Verify only (no change expected): `07_HabitTracker/Views/HabitRowView.swift`, `07_HabitTracker/Views/HabitDetailView.swift`, `07_HabitTracker/Views/Components/CircularProgressStyle.swift`

**Interfaces:**
- Consumes: `Habit` (Task 5), `HabitStore` methods (Task 6).
- Produces: a working `HabitListView` with live SwiftData-backed list, seeding, and a `SummaryCard` driven by a plain `[Habit]` array.

- [ ] **Step 1: Rewrite `HabitListView.swift`**

Replace the full contents of `07_HabitTracker/Views/HabitListView.swift` with:

```swift
import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    // @StateObject: このViewがHabitStoreを所有・管理する
    // Viewが破棄されるまでインスタンスが保持される
    @StateObject private var store = HabitStore()
    @State private var showAddHabit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 全体進捗サマリー
                    SummaryCard(habits: habits)
                        .padding(.horizontal)

                    // 習慣リスト
                    ForEach(habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit, store: store)) {
                            HabitRowView(habit: habit, store: store)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("習慣トラッカー")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView(store: store)
            }
            .task {
                seedIfNeeded()
            }
        }
    }

    private func seedIfNeeded() {
        guard habits.isEmpty else { return }
        for sample in Habit.samples {
            modelContext.insert(sample)
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true)
}
```

- [ ] **Step 2: Rewrite `AddHabitView.swift`**

Replace the full contents of `07_HabitTracker/Views/AddHabitView.swift` with:

```swift
import SwiftUI
import SwiftData

struct AddHabitView: View {
    @ObservedObject var store: HabitStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var targetCount = 1
    @State private var selectedColorName = "blue"

    let emojiOptions = ["⭐️", "🏃", "📚", "💧", "🧘", "🌍", "🍎", "💪", "🎯", "🎵"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("習慣の名前", text: $name)

                    // 絵文字セレクター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.title2)
                                    .padding(8)
                                    .background(emoji == e ? Color.blue.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                }

                Section("目標") {
                    Stepper("目標回数: \(targetCount)", value: $targetCount, in: 1...100)
                }

                Section("カラー") {
                    HStack(spacing: 12) {
                        ForEach(Habit.colorOptions, id: \.self) { colorName in
                            Circle()
                                .fill(Habit.color(named: colorName))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColorName == colorName ? 3 : 0)
                                )
                                .shadow(
                                    color: Habit.color(named: colorName).opacity(0.5),
                                    radius: selectedColorName == colorName ? 4 : 0
                                )
                                .onTapGesture { selectedColorName = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("習慣を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        store.addHabit(
                            name: name,
                            emoji: emoji,
                            target: targetCount,
                            colorName: selectedColorName,
                            context: modelContext
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddHabitView(store: HabitStore())
        .modelContainer(for: Habit.self, inMemory: true)
}
```

- [ ] **Step 3: Rewrite `SummaryCard.swift`**

Replace the full contents of `07_HabitTracker/Views/Components/SummaryCard.swift` with:

```swift
import SwiftUI

struct SummaryCard: View {
    let habits: [Habit]

    private var totalCompleted: Int {
        habits.filter(\.isCompleted).count
    }

    private var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の進捗")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(totalCompleted) / \(habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView: 進捗を視覚的に表示（円形、CircularProgressStyleを適用）
                ProgressView(value: overallProgress)
                    .progressViewStyle(CircularProgressStyle())
            }

            // ProgressView: 線形（デフォルト）
            ProgressView(value: overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCard(habits: Habit.samples)
        .padding()
        .background(Color(.systemGroupedBackground))
}
```

- [ ] **Step 4: Confirm `HabitRowView.swift`, `HabitDetailView.swift`, `CircularProgressStyle.swift` need no changes**

`HabitRowView` and `HabitDetailView` only read `Habit` properties (`habit.color` still resolves via the new computed property) and call `store.increment/decrement/complete/reset/reset`, all of which kept the same signature. `CircularProgressStyle` doesn't reference `Habit` at all.

Run: `grep -n "store.habits\|store.totalCompleted\|store.overallProgress" 07_HabitTracker/Views/HabitRowView.swift 07_HabitTracker/Views/HabitDetailView.swift 07_HabitTracker/Views/Components/CircularProgressStyle.swift`
Expected: no output.

- [ ] **Step 5: Verify no stale `store.habits` / `Color` selection references remain**

Run: `grep -rn "store\.habits\|colorOptions: \[Color\]\|selectedColor: Color" 07_HabitTracker/Views`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add 07_HabitTracker/Views/HabitListView.swift 07_HabitTracker/Views/AddHabitView.swift 07_HabitTracker/Views/Components/SummaryCard.swift
git commit -m "07_HabitTracker: ViewをSwiftDataの@Query/ModelContextとcolorName UIに対応"
```

---

### Task 8: 07_HabitTracker README / ROADMAP update

**Files:**
- Modify: `07_HabitTracker/README.md`
- Modify: `07_HabitTracker/ROADMAP.md`

**Interfaces:**
- None (documentation only).

- [ ] **Step 1: Rewrite `07_HabitTracker/README.md`**

Replace the full contents of `07_HabitTracker/README.md` with:

```markdown
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
```

- [ ] **Step 2: Update Step 1 of `07_HabitTracker/ROADMAP.md` (data model)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
## Step 1 — データモデルを作る
**ファイル:** `Models/Habit.swift` を新規作成

### 1-1: struct の骨格
```swift
import Foundation
import SwiftUI

struct Habit: Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var targetCount: Int    // 1日の目標
    var completedCount: Int // 今日の達成数
    var streak: Int         // 連続日数
    var color: Color
}
```
```

Replace it with:

```markdown
## Step 1 — データモデルを作る
**ファイル:** `Models/Habit.swift` を新規作成

### 1-1: @Model の骨格
```swift
import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var targetCount: Int    // 1日の目標
    var completedCount: Int // 今日の達成数
    var streak: Int         // 連続日数
    var colorName: String   // Colorは直接保存できないので名前(String)で持つ
}
```
▶ 理解: `@Model` を付けると `struct` ではなく `final class` にする必要がある。また `Color` 型はそのままでは保存できないため、`"blue"` のような文字列(`colorName`)として持ち、表示時にだけ `Color` へ変換する（Step 1-3で追加する）。
```

- [ ] **Step 3: Update Step 1-3 of `07_HabitTracker/ROADMAP.md` (init + samples)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 1-3: init + サンプルデータ
```swift
    init(id: UUID = UUID(), name: String, emoji: String,
         targetCount: Int = 1, completedCount: Int = 0,
         streak: Int = 0, color: Color = .blue) {
        // ...
    }

extension Habit {
    static let samples: [Habit] = [
        Habit(name: "朝の瞑想",     emoji: "🧘", targetCount: 1,     completedCount: 1,    streak: 7,  color: .purple),
        Habit(name: "読書",        emoji: "📚", targetCount: 30,    completedCount: 12,   streak: 3,  color: .orange),
        Habit(name: "ウォーキング", emoji: "🚶", targetCount: 10000, completedCount: 6540, streak: 14, color: .green),
        Habit(name: "水を飲む",     emoji: "💧", targetCount: 8,     completedCount: 5,    streak: 21, color: .blue),
        Habit(name: "英語学習",     emoji: "🌍", targetCount: 1,     completedCount: 0,    streak: 0,  color: .red),
    ]
}
```
▶ ここで確認: `Habit.samples[0].progress` が `1.0`、`samples[1].progress` が `0.4` になること（サンプルは5件、`ウォーキング`が読書と水を飲むの間に入る）
```

Replace it with:

```markdown
### 1-3: init + サンプルデータ + colorの変換ヘルパー
```swift
    init(id: UUID = UUID(), name: String, emoji: String,
         targetCount: Int = 1, completedCount: Int = 0,
         streak: Int = 0, colorName: String = "blue") {
        // ...
    }

extension Habit {
    static let colorOptions: [String] = ["blue", "red", "green", "orange", "purple", "pink", "yellow", "teal"]

    static func color(named colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }

    var color: Color {
        Habit.color(named: colorName)
    }
}

extension Habit {
    static let samples: [Habit] = [
        Habit(name: "朝の瞑想",     emoji: "🧘", targetCount: 1,     completedCount: 1,    streak: 7,  colorName: "purple"),
        Habit(name: "読書",        emoji: "📚", targetCount: 30,    completedCount: 12,   streak: 3,  colorName: "orange"),
        Habit(name: "ウォーキング", emoji: "🚶", targetCount: 10000, completedCount: 6540, streak: 14, colorName: "green"),
        Habit(name: "水を飲む",     emoji: "💧", targetCount: 8,     completedCount: 5,    streak: 21, colorName: "blue"),
        Habit(name: "英語学習",     emoji: "🌍", targetCount: 1,     completedCount: 0,    streak: 0,  colorName: "red"),
    ]
}
```
▶ ここで確認: `Habit.samples[0].progress` が `1.0`、`samples[1].progress` が `0.4` になること（サンプルは5件、`ウォーキング`が読書と水を飲むの間に入る）
▶ 理解: `color` はSwiftDataに保存されない計算プロパティ。`colorName` から毎回その場で `Color` を組み立てる。
```

- [ ] **Step 4: Update Step 2 of `07_HabitTracker/ROADMAP.md` (ObservableObject)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 2-1: ObservableObject + @Published の骨格
```swift
import Foundation
import Combine
import SwiftUI

// ObservableObject: このクラスの変化を@StateObject/@ObservedObjectで監視できる
class HabitStore: ObservableObject {
    // @Published: この値が変わると購読しているViewが再描画される
    @Published var habits: [Habit] = Habit.samples
}
```
▶ 理解: `class`（値型でなく参照型）が必要。`ObservableObject` に準拠するだけで通知の仕組みが使える。`Color` を扱うため `import SwiftUI` も必要（`Foundation`だけでは解決できない）。

### 2-2: 集計プロパティ
```swift
    var totalCompleted: Int {
        habits.filter(\.isCompleted).count
    }

    var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }
```
```

Replace it with:

```markdown
### 2-1: ObservableObject の骨格
```swift
import Foundation
import SwiftData
import SwiftUI

// ObservableObject: このクラスの変化を@StateObject/@ObservedObjectで監視できる
final class HabitStore: ObservableObject {
}
```
▶ 理解: SwiftData化したことで `HabitStore` はもう `habits` 配列を持たない。一覧の表示は次のStepでViewが `@Query` から直接取得する。`HabitStore` は「streak管理・追加・削除」という操作ロジックだけを担当する。

### 2-2: 集計プロパティはViewに移動する
`totalCompleted` / `overallProgress` は `habits` 配列を前提にした計算なので、`HabitStore` ではなく、`@Query` で `habits` を持っているView側（Step 5の `HabitListView`、および `SummaryCard`）の計算プロパティとして実装する。このStepでは何も追加しない。
```

- [ ] **Step 5: Update Step 2-3/2-4 of `07_HabitTracker/ROADMAP.md` (syncStreak / 操作メソッド)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 2-3: streak更新を1か所に集約する（syncStreak）
```swift
    // streak更新の単一ルール:
    // 「未達 → 達成」に転じた瞬間に +1、「達成 → 未達」に戻った瞬間に -1。
    // increment/decrement/complete/reset すべてがこのルールに従うため、
    // 行のトグル操作と詳細画面のボタン操作で結果が一致する。
    private func syncStreak(at index: Int, wasCompleted: Bool) {
        let isCompleted = habits[index].isCompleted
        if !wasCompleted && isCompleted {
            habits[index].streak += 1
        } else if wasCompleted && !isCompleted {
            habits[index].streak = max(0, habits[index].streak - 1)
        }
    }
```
▶ 理解: 達成/未達の「切り替わった瞬間」だけを見て streak を増減させることで、何度ボタンを押しても streak がズレない。各操作メソッドは `wasCompleted` を先に控えてから値を変更し、最後に `syncStreak` を呼ぶだけでよい。

### 2-4: 操作メソッドを追加（increment/decrement/complete/reset）
```swift
    func increment(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        if habits[index].completedCount < habits[index].targetCount {
            habits[index].completedCount += 1
        }
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func decrement(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        if habits[index].completedCount > 0 {
            habits[index].completedCount -= 1
        }
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func complete(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        habits[index].completedCount = habits[index].targetCount
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func reset(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        habits[index].completedCount = 0
        syncStreak(at: index, wasCompleted: wasCompleted)
    }
```
▶ ここで確認: `decrement` は Step 6 の詳細画面で使うが、定義はここ（Step 2）で済ませておく。

### 2-5: 追加・削除メソッド
```swift
    func addHabit(name: String, emoji: String, target: Int, color: Color) {
        let habit = Habit(name: name, emoji: emoji, targetCount: target, color: color)
        habits.append(habit)
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }
```
```

Replace it with:

```markdown
### 2-3: streak更新を1か所に集約する（syncStreak）
```swift
    // streak更新の単一ルール:
    // 「未達 → 達成」に転じた瞬間に +1、「達成 → 未達」に戻った瞬間に -1。
    // increment/decrement/complete/reset すべてがこのルールに従うため、
    // 行のトグル操作と詳細画面のボタン操作で結果が一致する。
    private func syncStreak(_ habit: Habit, wasCompleted: Bool) {
        let isCompleted = habit.isCompleted
        if !wasCompleted && isCompleted {
            habit.streak += 1
        } else if wasCompleted && !isCompleted {
            habit.streak = max(0, habit.streak - 1)
        }
    }
```
▶ 理解: `Habit` はSwiftDataの `@Model`（クラス・参照型）になったので、配列からインデックスを探して書き換える必要がなくなった。`habit` を直接渡してプロパティを書き換えるだけで、SwiftDataが自動的に保存する。

### 2-4: 操作メソッドを追加（increment/decrement/complete/reset）
```swift
    func increment(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount < habit.targetCount {
            habit.completedCount += 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func decrement(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount > 0 {
            habit.completedCount -= 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func complete(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = habit.targetCount
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func reset(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = 0
        syncStreak(habit, wasCompleted: wasCompleted)
    }
```
▶ ここで確認: `decrement` は Step 6 の詳細画面で使うが、定義はここ（Step 2）で済ませておく。

### 2-5: 追加・削除メソッド（ModelContextを引数で受け取る）
```swift
    func addHabit(name: String, emoji: String, target: Int, colorName: String, context: ModelContext) {
        context.insert(Habit(name: name, emoji: emoji, targetCount: target, colorName: colorName))
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
    }
```
▶ 理解: 一覧から取り除く／新しく作るときだけ `ModelContext` が必要。`context.insert` でレコードを新規作成し、`context.delete` で削除する。
```

- [ ] **Step 6: Update Step 5 of `07_HabitTracker/ROADMAP.md` (@StateObject + list screen)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 5-1: @StateObject の骨格（最重要ポイント）
```swift
import SwiftUI

struct HabitListView: View {
    // @StateObject: このViewがHabitStoreを「所有」する
    // Viewが初回描画された時に1回だけインスタンス化される
    @StateObject private var store = HabitStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(store.habits) { habit in
                        HabitRowView(habit: habit, store: store)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("習慣トラッカー")
        }
    }
}

#Preview { HabitListView() }
```
▶ ここで確認: Preview で習慣リストが表示されること
```

Replace it with:

```markdown
### 5-1: @StateObject + @Query の骨格（最重要ポイント）
```swift
import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    // @Query: SwiftDataに保存されている最新のHabitを常に取得する
    @Query private var habits: [Habit]
    // @StateObject: このViewがHabitStoreを「所有」する
    // Viewが初回描画された時に1回だけインスタンス化される
    @StateObject private var store = HabitStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(habits) { habit in
                        HabitRowView(habit: habit, store: store)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("習慣トラッカー")
            .task {
                // ストアが空（初回起動）ならサンプルデータを投入する
                guard habits.isEmpty else { return }
                for sample in Habit.samples {
                    modelContext.insert(sample)
                }
            }
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true)
}
```
▶ ここで確認: Preview で習慣リストが表示されること
▶ 理解: `habits` 配列は `store` ではなく `@Query` から取得する。`store`（`HabitStore`）はもう配列を持たず、`increment` などの操作ロジックだけを提供する。
```

- [ ] **Step 7: Update Step 5-3 of `07_HabitTracker/ROADMAP.md` (SummaryCard)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 5-3: SummaryCard（全体進捗）を専用Componentファイルに作る
**ファイル:** `Views/Components/SummaryCard.swift`
```swift
import SwiftUI

struct SummaryCard: View {
    // @ObservedObject: 外部から受け取ったObservableObjectを購読
    @ObservedObject var store: HabitStore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の進捗")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(store.totalCompleted) / \(store.habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView: 進捗を視覚的に表示（円形、Step 4のスタイルを適用）
                ProgressView(value: store.overallProgress)
                    .progressViewStyle(CircularProgressStyle())
            }

            // ProgressView: 線形（デフォルト）
            ProgressView(value: store.overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCard(store: HabitStore())
        .padding()
        .background(Color(.systemGroupedBackground))
}
```
▶ 理解: `SummaryCard` と `CircularProgressStyle` はどちらも複数のViewから再利用される部品なので、`HabitListView.swift` に書かずに `Views/Components/` 配下の別ファイルへ分離する。フォルダ構成のルール（再利用可能なViewはComponentへ）に従う。
```

Replace it with:

```markdown
### 5-3: SummaryCard（全体進捗）を専用Componentファイルに作る
**ファイル:** `Views/Components/SummaryCard.swift`
```swift
import SwiftUI

struct SummaryCard: View {
    // habits配列を直接受け取り、集計はこのView自身が計算する
    // （HabitStoreはSwiftData化後、配列を持たないため）
    let habits: [Habit]

    private var totalCompleted: Int {
        habits.filter(\.isCompleted).count
    }

    private var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の進捗")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(totalCompleted) / \(habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView: 進捗を視覚的に表示（円形、Step 4のスタイルを適用）
                ProgressView(value: overallProgress)
                    .progressViewStyle(CircularProgressStyle())
            }

            // ProgressView: 線形（デフォルト）
            ProgressView(value: overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCard(habits: Habit.samples)
        .padding()
        .background(Color(.systemGroupedBackground))
}
```
▶ 理解: `SummaryCard` と `CircularProgressStyle` はどちらも複数のViewから再利用される部品なので、`HabitListView.swift` に書かずに `Views/Components/` 配下の別ファイルへ分離する。フォルダ構成のルール（再利用可能なViewはComponentへ）に従う。
```

- [ ] **Step 8: Update Step 5-4 of `07_HabitTracker/ROADMAP.md` (組み込み)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 5-4: HabitListView に SummaryCard を組み込む
```swift
                VStack(spacing: 16) {
                    // 全体進捗サマリー
                    SummaryCard(store: store)
                        .padding(.horizontal)

                    // 習慣リスト
                    ForEach(store.habits) { habit in
                        HabitRowView(habit: habit, store: store)
                            .padding(.horizontal)
                    }
                }
```
▶ ここで確認: 全体の達成率が数値・円形・線形バーで表示されること
```

Replace it with:

```markdown
### 5-4: HabitListView に SummaryCard を組み込む
```swift
                VStack(spacing: 16) {
                    // 全体進捗サマリー
                    SummaryCard(habits: habits)
                        .padding(.horizontal)

                    // 習慣リスト
                    ForEach(habits) { habit in
                        HabitRowView(habit: habit, store: store)
                            .padding(.horizontal)
                    }
                }
```
▶ ここで確認: 全体の達成率が数値・円形・線形バーで表示されること
```

- [ ] **Step 9: Update Step 6 of `07_HabitTracker/ROADMAP.md` (AddHabitView)**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
### 6-1: AddHabitView の Form（絵文字・カラー選択つき）
```swift
import SwiftUI

struct AddHabitView: View {
    @ObservedObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var targetCount = 1
    @State private var selectedColor: Color = .blue

    let colorOptions: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .teal]
    let emojiOptions = ["⭐️", "🏃", "📚", "💧", "🧘", "🌍", "🍎", "💪", "🎯", "🎵"]
```

Replace it with:

```markdown
### 6-1: AddHabitView の Form（絵文字・カラー選択つき）
```swift
import SwiftUI
import SwiftData

struct AddHabitView: View {
    @ObservedObject var store: HabitStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var targetCount = 1
    @State private var selectedColorName = "blue"

    let emojiOptions = ["⭐️", "🏃", "📚", "💧", "🧘", "🌍", "🍎", "💪", "🎯", "🎵"]
```
▶ 理解: カラー選択は `Color` の配列ではなく `Habit.colorOptions`（`[String]`、Step 1-3で定義済み）から選ぶ。選んだ色は `Habit.color(named:)` でその場で `Color` に変換して表示する。
```

- [ ] **Step 10: Update the color picker section + add button of `07_HabitTracker/ROADMAP.md` Step 6**

In `07_HabitTracker/ROADMAP.md`, find this block:

```markdown
                Section("カラー") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .shadow(color: color.opacity(0.5), radius: selectedColor == color ? 4 : 0)
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                }
```

Replace it with:

```markdown
                Section("カラー") {
                    HStack(spacing: 12) {
                        ForEach(Habit.colorOptions, id: \.self) { colorName in
                            Circle()
                                .fill(Habit.color(named: colorName))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColorName == colorName ? 3 : 0)
                                )
                                .shadow(
                                    color: Habit.color(named: colorName).opacity(0.5),
                                    radius: selectedColorName == colorName ? 4 : 0
                                )
                                .onTapGesture { selectedColorName = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }
```
```

Then find this block (the toolbar's add button) in the same Step 6:

```markdown
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        store.addHabit(
                            name: name,
                            emoji: emoji,
                            target: targetCount,
                            color: selectedColor
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
```

Replace it with:

```markdown
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        store.addHabit(
                            name: name,
                            emoji: emoji,
                            target: targetCount,
                            colorName: selectedColorName,
                            context: modelContext
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
```
```

- [ ] **Step 11: Update Step 2 of the `07_HabitTracker/README.md`-style preview block + completion checklist of `07_HabitTracker/ROADMAP.md`**

In `07_HabitTracker/ROADMAP.md`, find:

```markdown
## 完成チェックリスト
- [ ] @Published な `habits` の変更がすぐにViewに反映される
- [ ] @StateObject（所有）と @ObservedObject（参照）の使い分けを理解した
- [ ] `syncStreak` が increment/decrement/complete/reset すべてで共通利用され、streakが矛盾なく増減する
- [ ] ProgressView の線形バーが表示される
- [ ] `CircularProgressStyle`（Component）を `SummaryCard` に適用できている
- [ ] 詳細画面の円形プログレスがアニメーションする
- [ ] 習慣の追加がシートから行える
- [ ] リストと詳細画面で進捗・streak・完了状態が同期している（同じ HabitStore インスタンス）
- [ ] 再利用可能な `SummaryCard` / `CircularProgressStyle` が `Views/Components/` に分離されている

---

## 補足: 設計上のポイント
- streakの更新は「達成/未達が切り替わった瞬間だけ+1/-1する」という単一ルール（`syncStreak`）に統一している。複数の操作（ボタンのトグル、詳細画面の+/-、一括完了）がすべて同じルールを通るので、操作の組み合わせに関わらずstreakの値が壊れない。
- `HabitStore` は `Color` 型のプロパティ（`addHabit` の引数など）を扱うため `import SwiftUI` が必須。`import Foundation` だけでは `Color` が解決できない点に注意。
- `SummaryCard` と `CircularProgressStyle` は複数のViewから参照される部品なので、`Views/Components/` 配下にそれぞれ独立したファイルとして置く。
```

Replace it with:

```markdown
## 完成チェックリスト
- [ ] `@Query` で取得した `habits` の変更がすぐにViewに反映される
- [ ] @StateObject（所有）と @ObservedObject（参照）の使い分けを理解した
- [ ] `syncStreak` が increment/decrement/complete/reset すべてで共通利用され、streakが矛盾なく増減する
- [ ] ProgressView の線形バーが表示される
- [ ] `CircularProgressStyle`（Component）を `SummaryCard` に適用できている
- [ ] 詳細画面の円形プログレスがアニメーションする
- [ ] 習慣の追加がシートから行える
- [ ] リストと詳細画面で進捗・streak・完了状態が同期している（同じ `Habit` インスタンスをSwiftDataが管理）
- [ ] 再利用可能な `SummaryCard` / `CircularProgressStyle` が `Views/Components/` に分離されている
- [ ] アプリを再起動しても習慣データが残っている（SwiftDataの永続化を確認）

---

## 補足: 設計上のポイント
- streakの更新は「達成/未達が切り替わった瞬間だけ+1/-1する」という単一ルール（`syncStreak`）に統一している。複数の操作（ボタンのトグル、詳細画面の+/-、一括完了）がすべて同じルールを通るので、操作の組み合わせに関わらずstreakの値が壊れない。
- `Habit` は `@Model`（クラス・参照型）なので、`increment` などはプロパティを直接書き換えるだけで永続化される。新規作成・削除のときだけ `ModelContext`（`context.insert` / `context.delete`）が必要。
- `Color` は `@Model` に直接保存できないため、`colorName: String` を保存し、`Habit.color(named:)` で表示用の `Color` に変換する。
- `SummaryCard` と `CircularProgressStyle` は複数のViewから参照される部品なので、`Views/Components/` 配下にそれぞれ独立したファイルとして置く。
```

- [ ] **Step 12: Commit**

```bash
git add 07_HabitTracker/README.md 07_HabitTracker/ROADMAP.md
git commit -m "07_HabitTracker: README/ROADMAPをSwiftData対応に更新"
```

---

## Final Verification (run after all tasks)

- [ ] **Step 1: Confirm no project file still references the old struct-based APIs**

Run:
```bash
grep -rn "viewModel.items\|store.habits\b" 01_TodoApp 07_HabitTracker --include="*.swift"
```
Expected: no output.

- [ ] **Step 2: Confirm every modified View still has a `#Preview`**

Run:
```bash
for f in 01_TodoApp/Views/TodoListView.swift 01_TodoApp/Views/AddTodoView.swift 07_HabitTracker/Views/HabitListView.swift 07_HabitTracker/Views/AddHabitView.swift 07_HabitTracker/Views/Components/SummaryCard.swift; do echo "== $f =="; grep -c "#Preview" "$f"; done
```
Expected: every file prints `== <path> ==` followed by `1`.

- [ ] **Step 3: Final commit check**

Run: `git log --oneline -10`
Expected: 8 commits from this plan listed (one per task), tree clean (`git status`).
