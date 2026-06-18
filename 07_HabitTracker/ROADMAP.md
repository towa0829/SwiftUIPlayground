# 07 HabitTracker ロードマップ

完成形: ObservableObject + ProgressView で習慣進捗を管理する

---

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

### 1-2: 計算プロパティを追加
```swift
    // 0.0 〜 1.0 に正規化した進捗
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1.0)
    }

    var isCompleted: Bool { completedCount >= targetCount }
```

### 1-3: init + サンプルデータ
```swift
    init(id: UUID = UUID(), name: String, emoji: String,
         targetCount: Int = 1, completedCount: Int = 0,
         streak: Int = 0, color: Color = .blue) {
        // ...
    }

extension Habit {
    static let samples: [Habit] = [
        Habit(name: "朝の瞑想", emoji: "🧘", targetCount: 1, completedCount: 1, streak: 7, color: .purple),
        Habit(name: "読書",     emoji: "📚", targetCount: 30, completedCount: 12, streak: 3, color: .orange),
        Habit(name: "水を飲む", emoji: "💧", targetCount: 8,  completedCount: 5,  streak: 21, color: .blue),
        Habit(name: "英語学習", emoji: "🌍", targetCount: 1,  completedCount: 0,  streak: 0, color: .red),
    ]
}
```
▶ ここで確認: `Habit.samples[0].progress` が `1.0`、`samples[1].progress` が `0.4` になること

---

## Step 2 — ObservableObject を作る（ここが核心）
**ファイル:** `ViewModels/HabitStore.swift` を新規作成

### 2-1: ObservableObject + @Published の骨格
```swift
import Foundation

// ObservableObject: このクラスの変化を@StateObject/@ObservedObjectで監視できる
class HabitStore: ObservableObject {
    // @Published: この値が変わると購読しているViewが再描画される
    @Published var habits: [Habit] = Habit.samples
}
```
▶ 理解: `class`（値型でなく参照型）が必要。`ObservableObject` に準拠するだけで通知の仕組みが使える。

### 2-2: 操作メソッドを追加
```swift
    func increment(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        if habits[i].completedCount < habits[i].targetCount {
            habits[i].completedCount += 1
        }
    }

    func complete(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].completedCount = habits[i].targetCount
        habits[i].streak += 1
    }

    func reset(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].completedCount = 0
    }

    func addHabit(name: String, emoji: String, target: Int, color: Color) {
        habits.append(Habit(name: name, emoji: emoji, targetCount: target, color: color))
    }
```

### 2-3: 集計プロパティ
```swift
    var totalCompleted: Int { habits.filter(\.isCompleted).count }

    var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }
```

---

## Step 3 — ProgressView で行カードを作る
**ファイル:** `Views/HabitRowView.swift` を新規作成

### 3-1: ProgressView の最小形（線形）
```swift
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var store: HabitStore   // ← @ObservedObject（外から受け取る）

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(habit.emoji).font(.title2)
                Text(habit.name).font(.subheadline.bold())
                Spacer()
                Text("\(habit.completedCount) / \(habit.targetCount)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            // ProgressView: value に 0.0〜1.0 を渡すと線形バーになる
            ProgressView(value: habit.progress)
                .tint(habit.color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    VStack(spacing: 12) {
        HabitRowView(habit: Habit.samples[0], store: HabitStore())
        HabitRowView(habit: Habit.samples[1], store: HabitStore())
    }
    .padding()
}
```
▶ ここで確認: 各習慣の進捗バーが表示されること

### 3-2: 完了ボタン + 完了時のスタイル変化を追加
```swift
            HStack {
                Text(habit.emoji).font(.title2)
                Text(habit.name)
                Spacer()
                // 完了/未完了でアイコンを切り替え
                Button {
                    if habit.isCompleted { store.reset(habit) }
                    else { store.increment(habit) }
                } label: {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(habit.isCompleted ? habit.color : .secondary)
                }
                .buttonStyle(.plain)
            }
```

### 3-3: 完了時に背景色を変える
```swift
        .background(
            habit.isCompleted
            ? habit.color.opacity(0.08)
            : Color(.secondarySystemBackground)
        )
```
▶ ここで確認: ボタンタップで背景色とアイコンが変わること

---

## Step 4 — @StateObject でリスト画面を作る
**ファイル:** `Views/HabitListView.swift` を新規作成

### 4-1: @StateObject の骨格（最重要ポイント）
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
                    }
                }
                .padding()
            }
            .navigationTitle("習慣トラッカー")
        }
    }
}

#Preview { HabitListView() }
```
▶ ここで確認: Preview で習慣リストが表示されること

### 4-2: @StateObject vs @ObservedObject の違いを体感する
```swift
// ❌ 間違い: 子Viewで @StateObject を使うと毎回新しいインスタンスになる
struct HabitRowView: View {
    @StateObject private var store = HabitStore()  // ← 親のstoreと別物！

// ✅ 正解: 子Viewでは @ObservedObject で受け取る
struct HabitRowView: View {
    @ObservedObject var store: HabitStore  // ← 親から渡された同じインスタンスを参照
```
▶ 理解: HabitListView で `@StateObject` を使い、HabitRowView では `@ObservedObject` で受け取る。これが MVVM の基本パターン。

### 4-3: SummaryCard（全体進捗）を追加
```swift
// HabitListView の VStack の先頭に追加
                    SummaryCard(store: store)

// 別structとして定義
struct SummaryCard: View {
    @ObservedObject var store: HabitStore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("今日の進捗").font(.caption).foregroundStyle(.secondary)
                    Text("\(store.totalCompleted) / \(store.habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView の不定スタイル（くるくる）ではなく、値ありの円形を自作
                ProgressView(value: store.overallProgress)
                    .frame(width: 56, height: 56)
            }
            ProgressView(value: store.overallProgress).tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```
▶ ここで確認: 全体の達成率が数値とバーで表示されること

---

## Step 5 — 習慣追加シートを作る
**ファイル:** `Views/AddHabitView.swift` を新規作成、`HabitListView.swift` に繋ぐ

### 5-1: AddHabitView の Form
```swift
import SwiftUI

struct AddHabitView: View {
    @ObservedObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var targetCount = 1
    @State private var selectedColor: Color = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("習慣の名前", text: $name)
                }
                Section("目標") {
                    Stepper("目標回数: \(targetCount)", value: $targetCount, in: 1...100)
                }
            }
            .navigationTitle("習慣を追加")
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        store.addHabit(name: name, emoji: emoji, target: targetCount, color: selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
```

### 5-2: HabitListView に sheet を追加
```swift
    @State private var showAddHabit = false

    // .navigationTitle の後に
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAddHabit = true } label: { Image(systemName: "plus") }
        }
    }
    .sheet(isPresented: $showAddHabit) {
        AddHabitView(store: store)
    }
```
▶ ここで確認: 習慣を追加するとリストに反映されること

---

## Step 6 — 詳細画面（円形 ProgressView）を作る
**ファイル:** `Views/HabitDetailView.swift` を新規作成

### 6-1: 大きな円形プログレスを ZStack で自作する
```swift
import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var store: HabitStore

    var current: Habit { store.habits.first(where: { $0.id == habit.id }) ?? habit }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(current.emoji).font(.system(size: 72))
                Text(current.name).font(.title.bold())

                // 円形プログレスを ZStack で手作り
                ZStack {
                    Circle()
                        .stroke(current.color.opacity(0.2), lineWidth: 16)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: current.progress)
                        .stroke(current.color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))  // 12時から始める
                        .frame(width: 180, height: 180)
                        .animation(.spring(duration: 0.5), value: current.progress)
                    Text("\(Int(current.progress * 100))%")
                        .font(.system(size: 40, weight: .bold))
                }
```
▶ 理解: `Circle().trim(from:to:)` で円弧を描く。`rotationEffect` で12時スタートにする。

### 6-2: +/- ボタンを追加
```swift
                HStack(spacing: 20) {
                    Button {
                        store.decrement(current)  // decrementも HabitStore に追加
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(current.color.opacity(0.6))
                    }
                    .disabled(current.completedCount == 0)

                    Button { store.increment(current) } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(current.color)
                    }
                    .disabled(current.isCompleted)
                }
```
▶ ここで確認: +ボタンで円弧がアニメーションしながら伸びること

### 6-3: HabitListView の各行に NavigationLink を追加
```swift
                    ForEach(store.habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit, store: store)) {
                            HabitRowView(habit: habit, store: store)
                        }
                        .buttonStyle(.plain)
                    }
```
▶ ここで確認: 行タップで詳細に遷移し、+/-ボタンで進捗が変わること

---

## 完成チェックリスト
- [ ] @Published な `habits` の変更がすぐにViewに反映される
- [ ] @StateObject（所有）と @ObservedObject（参照）の使い分けを理解した
- [ ] ProgressView の線形バーが表示される
- [ ] 詳細画面の円形プログレスがアニメーションする
- [ ] 習慣の追加がシートから行える
- [ ] リストと詳細画面で進捗が同期している（同じ HabitStore インスタンス）
