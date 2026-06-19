# 01_TodoApp / 07_HabitTracker SwiftData移行 設計

## 背景・目的

`01_TodoApp` と `07_HabitTracker` は現在、データをメモリ上の配列（`@Published var items/habits`）として保持しており、アプリを再起動するとサンプルデータにリセットされる。SwiftDataを学習するための実例として、この2プロジェクトを永続化対応に書き換える。

対象は既存プロジェクトの直接書き換え。新規フォルダは作らない。

## 共通方針

- モデルを `struct` から `@Model final class` に変更する
- ViewModel（`TodoViewModel` / `HabitStore`）は引き続き「操作ロジック」を担当するが、表示用のデータ配列は持たない。一覧表示はViewが `@Query` で直接取得する
- ViewModelの各メソッドは `ModelContext` を引数で受け取る（`addItem(title:, context:)` など）。Viewは `@Environment(\.modelContext)` から取得したcontextをその都度渡す
  - 理由: `@StateObject` の初期化はView初期化時に走るため、environment経由のcontextをinitで受け取ろうとするとタイミング問題が起きる。メソッド引数にすることで初心者にも仕組みが分かりやすく、初期化順序を気にしなくてよい
- 初回起動時（ストアが空の場合）は既存の `samples` を自動投入し、見た目の連続性を保つ
- 各Viewの `#Preview` は `.modelContainer(for: <Model>.self, inMemory: true)` を使い、インメモリのSwiftDataコンテナでプレビュー動作を保証する（CLAUDE.mdの「Previewが動作すること」要件）
- READMEとROADMAPを変更内容に合わせて更新する

## 01_TodoApp

### モデル: `TodoItem.swift`

```swift
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
```

`static let samples` はシード投入専用の `[TodoItem]` ファクトリとして残す（保存済みインスタンスではなく毎回新規生成）。

### ViewModel: `TodoViewModel.swift`

`ObservableObject` のままでよいが、`items`配列の保持をやめる。

```swift
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
        // @Model はクラス（参照型）なのでプロパティ変更がそのまま永続化される
    }

    func deleteItems(_ items: [TodoItem], context: ModelContext) {
        for item in items {
            context.delete(item)
        }
    }
}
```

`completedCount` / `pendingCount` はViewModelからは削除し、`TodoListView` 側で `@Query` の結果から計算する（ViewModelが配列を持たなくなるため）。

### View: `TodoListView.swift`

```swift
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]
    @StateObject private var viewModel = TodoViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    TodoRowView(item: item, onToggle: { viewModel.toggleItem(item) })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteItems([item], context: modelContext)
                            } label: { Label("削除", systemImage: "trash") }
                        }
                }
            }
            .task { seedIfNeeded() }
        }
    }

    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        for sample in TodoItem.samples {
            modelContext.insert(sample)
        }
    }
}
```

`AddTodoView` / `TodoDetailView` / `TodoRowView` は `TodoItem` が参照型になったことに伴うシグネチャの軽微な調整のみ（`var item: TodoItem` で参照を受け取り、`Binding` が不要になる箇所は通常プロパティに変更）。

### Appのエントリ更新

`01_TodoApp` にはApp構造体が無いため、README手順内の指示を更新する（下記README節を参照）。

## 07_HabitTracker

### モデル: `Habit.swift`

```swift
@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var targetCount: Int
    var completedCount: Int
    var streak: Int
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

    var color: Color {
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
}
```

色はあらかじめ用意した名前付きパレットから選ぶ方式に変更し、`AddHabitView` の色選択UIを `ColorPicker` ではなく `Picker`（パレットから選択）に変更する。

### ViewModel: `HabitStore.swift`

既存の `increment/decrement/complete/reset/addHabit/deleteHabit` はロジック（`syncStreak` を含む）をそのまま維持し、`context: ModelContext` を引数に追加する。`habits` 配列・`totalCompleted` / `overallProgress` の保持はやめ、View側の `@Query` 結果から計算する。

```swift
final class HabitStore: ObservableObject {
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

`increment/decrement/complete/reset` は `@Model` インスタンスのプロパティ変更のみで永続化されるため `context` 引数は不要（追加・削除のみ必要）。

### View: `HabitListView.swift`

```swift
struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @StateObject private var store = HabitStore()

    var body: some View {
        NavigationStack {
            List(habits) { habit in
                HabitRowView(habit: habit, store: store)
            }
            .task { seedIfNeeded() }
        }
    }

    private func seedIfNeeded() {
        guard habits.isEmpty else { return }
        for sample in Habit.samples {
            modelContext.insert(sample)
        }
    }
}
```

`totalCompleted` / `overallProgress`（`SummaryCard` 表示用）は `HabitListView` 内のcomputed propertyとして `habits`（`@Query` の結果）から算出する形に移す。

## README / ROADMAP 更新方針

両プロジェクトの `README.md`:
- 「学習テーマ」にSwiftData（`@Model`, `@Query`, `ModelContext`）を追加
- 「セットアップ」手順に `.modelContainer(for: TodoItem.self)` / `.modelContainer(for: Habit.self)` をApp構造体に追加する手順を追記
- 「学習ポイント」にSwiftDataの基本コード例（`@Model`定義、`@Query`、`context.insert/delete`）を追加
- 「発展課題」からSwiftData関連項目（あれば）を削除し、達成済みである旨を反映

両プロジェクトのROADMAPは「写経しながら学ぶ」形式（Step単位でファイルを新規作成し、コード片を順に書き足す）になっており、既存ステップの大部分（List, NavigationStack, SwipeActions, ProgressView, @StateObject/@ObservedObjectの使い分けなど）はSwiftData化後も成立する。変更が必要なのは以下のステップのみ：

`01_TodoApp/ROADMAP.md`:
- Step 1（データモデル）: `struct` → `@Model final class` に変更し、`@Model`の説明を追加
- Step 2（ViewModel）: `items`配列の保持をやめ、`context`引数を取るメソッドに変更する手順に差し替え
- Step 5（List + NavigationStack）: `@StateObject` に加えて `@Query` と `@Environment(\.modelContext)` を導入する手順を追加。`viewModel.items` → `items`（`@Query`の結果）に置き換え
- 完成チェックリストに「アプリを再起動してもデータが残ること」を追加

`07_HabitTracker/ROADMAP.md`:
- Step 1（データモデル）: `struct` → `@Model final class`、`color: Color` → `colorName: String` + `color`計算プロパティに変更
- Step 2（ObservableObject）: `habits`配列の保持をやめ、`addHabit`/`deleteHabit`に`context`引数を追加する手順に差し替え（`increment`等のロジックはそのまま）
- Step 5（@StateObject + リスト画面）: `@Query` と `@Environment(\.modelContext)` の導入、`totalCompleted`/`overallProgress`をView側の計算プロパティに移す手順を追加
- Step 6（追加シート）: カラー選択を`Color`配列から`colorName: String`配列（Picker）に変更
- 完成チェックリストに「アプリを再起動してもデータが残ること」を追加
- 補足セクションに「`@Model`はクラスなので、プロパティの変更がそのまま永続化される」という説明を追加

それ以外のStep（行UI、ProgressView、CircularProgressStyle等）は変更不要。

## テスト・検証方法

- 各 `#Preview` で `.modelContainer(for: ..., inMemory: true)` を付与し、Xcodeプレビューが正常に表示されることを確認
- ロジック面は既存の `syncStreak` 等のテストケース（手動確認）を流用し、`context` 引数追加によるシグネチャ変更がコンパイルエラーを起こさないことを確認
- 実際のビルド確認はXcode環境が必要なため、コードレベルでの整合性確認（インポート漏れ、型不一致がないか）を中心に行う

## スコープ外

- 日付ごとの完了履歴（`HabitRecord` 相当のモデル）は今回追加しない
- CloudKit同期、iCloud共有は対象外
- 既存の他プロジェクト（02〜06, 08〜10）への変更は行わない
