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
        Habit(name: "朝の瞑想",     emoji: "🧘", targetCount: 1,     completedCount: 1,    streak: 7,  color: .purple),
        Habit(name: "読書",        emoji: "📚", targetCount: 30,    completedCount: 12,   streak: 3,  color: .orange),
        Habit(name: "ウォーキング", emoji: "🚶", targetCount: 10000, completedCount: 6540, streak: 14, color: .green),
        Habit(name: "水を飲む",     emoji: "💧", targetCount: 8,     completedCount: 5,    streak: 21, color: .blue),
        Habit(name: "英語学習",     emoji: "🌍", targetCount: 1,     completedCount: 0,    streak: 0,  color: .red),
    ]
}
```
▶ ここで確認: `Habit.samples[0].progress` が `1.0`、`samples[1].progress` が `0.4` になること（サンプルは5件、`ウォーキング`が読書と水を飲むの間に入る）

---

## Step 2 — ObservableObject を作る（ここが核心）
**ファイル:** `ViewModels/HabitStore.swift` を新規作成

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
        VStack(spacing: 10) {
            HStack {
                Text(habit.emoji).font(.title2)
                Text(habit.name).font(.subheadline.bold())
                Spacer()
                Text("\(habit.completedCount) / \(habit.targetCount)")
                    .font(.footnote).foregroundStyle(.secondary)
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

### 3-2: 完了ボタン + 連続日数バッジを追加
```swift
            HStack {
                Text(habit.emoji).font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(.subheadline.bold())
                    Text("\(habit.completedCount) / \(habit.targetCount)")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Spacer()

                // 連続日数バッジ（streakが0のときは表示しない）
                if habit.streak > 0 {
                    Label("\(habit.streak)日", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }

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
▶ 理解: バッジは `if habit.streak > 0` で条件表示。streakが0の習慣は単に表示されない。

### 3-3: 完了時に背景色と枠線を変える
```swift
        .background(
            habit.isCompleted
            ? habit.color.opacity(0.08)
            : Color(.secondarySystemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(habit.isCompleted ? habit.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
```
▶ ここで確認: ボタンタップで背景色・枠線・アイコンが変わること

---

## Step 4 — カスタム円形 ProgressViewStyle を作る
**ファイル:** `Views/Components/CircularProgressStyle.swift` を新規作成

### 4-1: ProgressViewStyle プロトコルに準拠する
```swift
import SwiftUI

// カスタムProgressViewStyle
struct CircularProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: configuration.fractionCompleted)
            Text("\(Int((configuration.fractionCompleted ?? 0) * 100))%")
                .font(.footnote.bold())
        }
        .frame(width: 56, height: 56)
    }
}

#Preview {
    ProgressView(value: 0.65)
        .progressViewStyle(CircularProgressStyle())
}
```
▶ 理解: `ProgressViewStyle` に準拠すると `configuration.fractionCompleted`（0.0〜1.0、不定の場合は `nil`）からカスタムの見た目を組み立てられる。`.progressViewStyle(CircularProgressStyle())` を付けるだけで、通常の `ProgressView(value:)` がこの円形デザインに置き換わる。

---

## Step 5 — @StateObject でリスト画面 + サマリーカードを作る
**ファイル:** `Views/HabitListView.swift`、`Views/Components/SummaryCard.swift` を新規作成

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

### 5-2: @StateObject vs @ObservedObject の違いを体感する
```swift
// ❌ 間違い: 子Viewで @StateObject を使うと毎回新しいインスタンスになる
struct HabitRowView: View {
    @StateObject private var store = HabitStore()  // ← 親のstoreと別物！

// ✅ 正解: 子Viewでは @ObservedObject で受け取る
struct HabitRowView: View {
    @ObservedObject var store: HabitStore  // ← 親から渡された同じインスタンスを参照
```
▶ 理解: HabitListView で `@StateObject` を使い、HabitRowView では `@ObservedObject` で受け取る。これが MVVM の基本パターン。

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

---

## Step 6 — 習慣追加シートを作る
**ファイル:** `Views/AddHabitView.swift` を新規作成、`HabitListView.swift` に繋ぐ

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
                            color: selectedColor
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
}
```

### 6-2: HabitListView に sheet を追加
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

## Step 7 — 詳細画面（円形 ProgressView）を作る
**ファイル:** `Views/HabitDetailView.swift` を新規作成

### 7-1: emoji・名前・連続日数ラベル
```swift
import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var store: HabitStore

    // storeからこのhabitの最新状態を取得
    var currentHabit: Habit {
        store.habits.first(where: { $0.id == habit.id }) ?? habit
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(currentHabit.emoji)
                        .font(.system(size: 72))
                    Text(currentHabit.name)
                        .font(.title.bold())
                    Label("\(currentHabit.streak)日連続", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
                .padding(.top)
```
▶ 理解: `currentHabit` は `habit`（NavigationLinkに渡した時点のスナップショット）ではなく、毎回 `store.habits` から最新を引き直す計算プロパティ。`store` が更新されるたびにこちらも再評価され、リストの操作と詳細画面の表示が常に一致する。

### 7-2: 大きな円形プログレスを ZStack で自作する
```swift
                // 大きな円形プログレス
                ZStack {
                    Circle()
                        .stroke(currentHabit.color.opacity(0.2), lineWidth: 16)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: currentHabit.progress)
                        .stroke(
                            currentHabit.color,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 180, height: 180)
                        .animation(.spring(duration: 0.5), value: currentHabit.progress)

                    VStack(spacing: 4) {
                        Text("\(currentHabit.completedCount)")
                            .font(.system(size: 48, weight: .bold))
                        Text("/ \(currentHabit.targetCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
```
▶ 理解: `Circle().trim(from:to:)` で円弧を描く。`rotationEffect` で12時スタートにする。`Views/Components/CircularProgressStyle.swift`（Step 4）はあくまで「ProgressViewの見た目を置き換える」汎用部品で、この画面のような大きな専用デザインを作りたい時は ZStack を自作する方が向いている。

### 7-3: +/- ボタンを追加
```swift
                // 操作ボタン
                HStack(spacing: 20) {
                    Button {
                        store.decrement(currentHabit)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(currentHabit.color.opacity(0.6))
                    }
                    .disabled(currentHabit.completedCount == 0)

                    Button {
                        store.increment(currentHabit)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(currentHabit.color)
                    }
                    .disabled(currentHabit.isCompleted)
                }
```
▶ ここで確認: +ボタンで円弧がアニメーションしながら伸びること。`decrement` は Step 2-4 で `HabitStore` にすでに用意済み。

### 7-4: 完了ボタン / 達成済みバナー
```swift
                // 一括完了ボタン
                if !currentHabit.isCompleted {
                    Button {
                        store.complete(currentHabit)
                    } label: {
                        Label("完了にする", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentHabit.color)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                } else {
                    Label("今日は達成済み！", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(currentHabit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit.samples[1], store: HabitStore())
    }
}
```
▶ ここで確認: 未達のときは「完了にする」ボタン、達成済みのときは「今日は達成済み！」バナーに表示が切り替わること。

### 7-5: HabitListView の各行に NavigationLink を追加
```swift
                    ForEach(store.habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit, store: store)) {
                            HabitRowView(habit: habit, store: store)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
```
▶ ここで確認: 行タップで詳細に遷移し、+/-ボタン・完了ボタンで進捗とstreakが変わり、リストに戻っても結果が反映されていること（同じ `HabitStore` インスタンスを共有しているため）。

---

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
