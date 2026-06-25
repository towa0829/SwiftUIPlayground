# 11 SwipeCards ロードマップ

完成形: DragGesture + offset/rotationEffect + spring で「Tinder風カードスワイプ」を体感する

---

## Step 1 — データモデルと ViewModel を作る
**ファイル:** `Models/ProfileCard.swift`、`ViewModels/CardStackViewModel.swift` を新規作成

### 1-1: ProfileCard struct
```swift
import SwiftUI

struct ProfileCard: Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var emoji: String
    var bio: String
    var color: Color
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        emoji: String,
        bio: String,
        color: Color,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.emoji = emoji
        self.bio = bio
        self.color = color
        self.tags = tags
    }
}

extension ProfileCard {
    static let samples: [ProfileCard] = [
        ProfileCard(name: "もも", age: 24, emoji: "🐶", bio: "散歩とおやつが好きです", color: .orange, tags: ["散歩", "おやつ"]),
        ProfileCard(name: "りん", age: 27, emoji: "🐱", bio: "日向ぼっこが得意です", color: .pink, tags: ["日向ぼっこ", "マイペース"]),
        ProfileCard(name: "そら", age: 22, emoji: "🐰", bio: "にんじんに目がありません", color: .green, tags: ["にんじん", "ジャンプ"]),
        ProfileCard(name: "あお", age: 29, emoji: "🐧", bio: "寒いところが大好きです", color: .blue, tags: ["雪", "泳ぐ"]),
    ]
}
```
カードは最低4枚あれば、めくっていく感覚を確認できる（完成版ではさらに増やしてある）。

### 1-2: SwipeDirection と CardStackViewModel
```swift
import Foundation

enum SwipeDirection {
    case like
    case nope
}

class CardStackViewModel: ObservableObject {
    @Published var cards: [ProfileCard] = ProfileCard.samples
    @Published var likedCount: Int = 0
    @Published var nopedCount: Int = 0

    func swipe(_ card: ProfileCard, direction: SwipeDirection) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards.remove(at: index)
        switch direction {
        case .like:
            likedCount += 1
        case .nope:
            nopedCount += 1
        }
    }

    func reset() {
        cards = ProfileCard.samples
        likedCount = 0
        nopedCount = 0
    }
}
```
▶ 理解: 「どのカードが何枚目か」「Like/Nopeが何件か」というデッキ全体の状態はVMが
一元管理する。Viewは「ドラッグでどれだけ動いたか」という一時的な見た目だけを持てばよい。

---

## Step 2 — CardView の見た目だけを作る（ジェスチャーなし）
**ファイル:** `Views/Components/CardView.swift` を新規作成

```swift
import SwiftUI

struct CardView: View {
    let card: ProfileCard
    let viewModel: CardStackViewModel

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(card.color.opacity(0.2))
            .overlay {
                VStack(spacing: 12) {
                    Text(card.emoji)
                        .font(.system(size: 96))
                    Text("\(card.name)　\(card.age)歳")
                        .font(.title2.bold())
                    Text(card.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .frame(width: 300, height: 420)
            .shadow(radius: 6)
    }
}

#Preview {
    CardView(card: ProfileCard.samples[0], viewModel: CardStackViewModel())
}
```
▶ ここで確認: カード1枚が画面中央に表示されること(Preview上でOK)

---

## Step 3 — タグ表示と ChoiceStamp を追加する
**ファイル:** `Views/Components/ChoiceStamp.swift` を新規作成、`CardView.swift` を編集

### 3-1: ChoiceStamp
```swift
import SwiftUI

struct ChoiceStamp: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 4)
            }
            .rotationEffect(.degrees(text == "LIKE" ? -15 : 15))
    }
}

#Preview {
    HStack(spacing: 24) {
        ChoiceStamp(text: "LIKE", color: .green)
        ChoiceStamp(text: "NOPE", color: .red)
    }
}
```

### 3-2: CardView にタグとスタンプ用の土台を追加
```swift
// VStack の中、bio の下に追加
HStack {
    ForEach(card.tags, id: \.self) { tag in
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(0.6), in: Capsule())
    }
}
```
```swift
// CardView の body 全体を ZStack(alignment: .top) で包み、
// RoundedRectangle の隣に LIKE/NOPE スタンプを重ねる土台を用意する（不透明度はまだ固定で良い）
ZStack(alignment: .top) {
    // ↑ 既存の RoundedRectangle(...) ...
    HStack {
        ChoiceStamp(text: "LIKE", color: .green)
        Spacer()
        ChoiceStamp(text: "NOPE", color: .red)
    }
    .padding(20)
}
```
▶ ここで確認: カードにタグとLIKE/NOPEスタンプが両方常に表示されること(まだドラッグでは
変化しない)

---

## Step 4 — DragGesture でカードを動かす
**ファイル:** `Views/Components/CardView.swift` を編集

### 4-1: ドラッグ中の見た目用 @State を追加
```swift
@State private var dragOffset: CGSize = .zero
private let swipeThreshold: CGFloat = 120

private var rotation: Angle {
    .degrees(Double(dragOffset.width / 20))
}
```

### 4-2: offset・rotationEffect・gesture を body に追加
```swift
// 一番外側の修飾子として追加（.frame(...).shadow(...) の後）
.offset(dragOffset)
.rotationEffect(rotation)
.gesture(
    DragGesture()
        .onChanged { value in
            dragOffset = value.translation
        }
        .onEnded { value in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
)
```
▶ 理解: `offset`にそのまま`dragOffset`を渡すと指の動きにリアルタイムで追従する。
横方向の移動量(`dragOffset.width`)を20で割って回転角に変換すると、傾きながら動く
自然な見た目になる。

▶ ここで確認: カードをドラッグすると傾きながら動き、離すと中央にスナップバックすること

---

## Step 5 — しきい値を超えたら画面外に投げ出す
**ファイル:** `Views/Components/CardView.swift` を編集

```swift
// onEnded の中身を置き換える
.onEnded { value in
    handleDragEnded(value.translation)
}
```
```swift
// CardView に追加するメソッド
private func handleDragEnded(_ translation: CGSize) {
    if translation.width > swipeThreshold {
        throwCard(direction: .like, towards: 600)
    } else if translation.width < -swipeThreshold {
        throwCard(direction: .nope, towards: -600)
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = .zero
        }
    }
}

private func throwCard(direction: SwipeDirection, towards endX: CGFloat) {
    withAnimation(.easeOut(duration: 0.3)) {
        dragOffset = CGSize(width: endX, height: dragOffset.height)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        viewModel.swipe(card, direction: direction)
    }
}
```
`viewModel.swipe`を呼ぶのを0.3秒遅らせているのがポイント。投げ出しアニメーションが
画面外まで終わるのを待ってからデッキの中身を変えるので、「カードが消える」瞬間と
「次のカードが現れる」瞬間がアニメーションと噛み合う。

▶ ここで確認: 大きくドラッグして離すとカードが画面外まで飛んでいき、デッキから消えること

---

## Step 6 — ドラッグ量に応じてスタンプを濃くする
**ファイル:** `Views/Components/CardView.swift` を編集

```swift
// rotation の下に追加
private var likeOpacity: Double {
    guard dragOffset.width > 0 else { return 0 }
    return min(Double(dragOffset.width / swipeThreshold), 1)
}

private var nopeOpacity: Double {
    guard dragOffset.width < 0 else { return 0 }
    return min(Double(-dragOffset.width / swipeThreshold), 1)
}
```
```swift
// ChoiceStamp(text: "LIKE", ...) の直後に .opacity(likeOpacity) を追加
// ChoiceStamp(text: "NOPE", ...) の直後に .opacity(nopeOpacity) を追加
```
▶ ここで確認: 右にドラッグするほどLIKEスタンプがはっきり見え、左にドラッグするほど
NOPEスタンプがはっきり見えること。離すとどちらも消えること

---

## Step 7 — スタック表示・ボタン・カウンタをまとめる
**ファイル:** `Views/SwipeCardsMainView.swift` を新規作成、`CardView.swift` を編集

### 7-1: CardView にボタン用の @Binding を追加
```swift
// CardView のプロパティに追加
@Binding var programmaticSwipe: SwipeDirection?
```
```swift
// .gesture(...) の直後に追加
.onChange(of: programmaticSwipe) { direction in
    guard let direction else { return }
    throwCard(direction: direction, towards: direction == .like ? 600 : -600)
    programmaticSwipe = nil
}
```
▶ 理解: ドラッグで投げる時も、ボタンで指示する時も、最終的には同じ`throwCard`
メソッドを呼ぶ。入力経路が増えてもアニメーションの実体は1つだけで済む。

### 7-2: SwipeCardsMainView でカードを重ねて表示する
```swift
import SwiftUI

struct SwipeCardsMainView: View {
    @StateObject private var viewModel = CardStackViewModel()
    @State private var programmaticSwipe: SwipeDirection?
    private let visibleCount = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                counterRow
                Spacer()
                if viewModel.cards.isEmpty {
                    emptyState
                } else {
                    cardStack
                }
                Spacer()
                if !viewModel.cards.isEmpty {
                    actionButtons
                }
            }
            .padding()
            .navigationTitle("スワイプカード")
        }
    }
}
```
（`counterRow`/`cardStack`/`actionButtons`/`emptyState`/`StackEntry`/`stackedEntries`は
完成版コードを参照して1つずつ追加する。`cardStack`では`ForEach`で深さごとに
`scaleEffect`と`offset(y:)`を変えてスタックの重なりを表現する）

▶ ここで確認: カードが少し重なって表示され、ドラッグでもボタンでも操作できること。
全部めくると空状態になり「もう一度」で復活すること

---

## 完成チェックリスト
- [ ] ドラッグでカードが傾きながら追従する（offset + rotationEffect）
- [ ] しきい値未満で離すとspringでスナップバックする
- [ ] しきい値を超えると画面外まで投げ出され、デッキから消える
- [ ] ドラッグ量に応じてLIKE/NOPEスタンプの濃さが変わる
- [ ] Like/Nopeボタンでもドラッグと同じ投げ出しアニメーションが再生される
- [ ] カウンタが正しく増え、空状態から「もう一度」で復活する

## アニメーションまとめ

| 手法 | 用途 |
|---|---|
| `DragGesture` | ドラッグ量(`translation`)の取得 |
| `.offset(_:)` | ドラッグ量に追従して移動 |
| `.rotationEffect(_:)` | 移動量から傾きを作る |
| `withAnimation(.spring)` | スナップバックの弾力 |
| `withAnimation(.easeOut)` | 画面外への投げ出し |
| `@Binding` + `.onChange` | ボタンからのプログラム的トリガー |

---

## 設計メモ: なぜ dragOffset を View に置くのか
「カードが今どれだけドラッグされているか」はそのカードの見た目だけに関わる一時的な
情報で、デッキ全体には影響しない。これをVMの`@Published`にしてしまうと、1pxドラッグ
するたびにデッキ全体（他のカードを含むView階層）に再描画が伝播し、無駄が増える。
一方「このカードを消すかどうか」「Like/Nopeが何件か」はデッキ全体に影響する状態
なので、こちらはVM(`CardStackViewModel.swipe`)に集約する。「Viewだけのアニメーション
状態」と「アプリ全体の状態」を分けるのが、Module 10から続くこの教材群の設計方針。
