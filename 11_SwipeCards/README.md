# 11 SwipeCards

## 学習テーマ
- `DragGesture` — ドラッグでViewを動かす
- `offset` / `rotationEffect` — ドラッグ量に応じて見た目を変える
- `withAnimation` + spring — スナップバック・投げ出しのアニメーション
- `ZStack` の重なり表現 — カードスタックの奥行き

## 完成イメージ
- 動物プロフィールカードを左右にドラッグして好み判定（Tinder風）
- 右へ大きくドラッグ→LIKE、左へ大きくドラッグ→NOPE。ドラッグ量に応じてスタンプが濃くなる
- 離した位置がしきい値未満ならspringで元の位置にスナップバック
- 下のLike/Nopeボタンでもプログラム的にスワイプできる
- 上部にLike/Nopeの件数カウンタ。全部めくったら「もう一度」で最初からやり直せる

## ファイル構成
```
11_SwipeCards/
├── Models/
│   └── ProfileCard.swift          # カードモデル + サンプル8件
├── ViewModels/
│   └── CardStackViewModel.swift   # デッキ管理 + Like/Nope集計
└── Views/
    ├── SwipeCardsMainView.swift   # エントリーポイント（カードスタック + ボタン + カウンタ）
    └── Components/
        ├── CardView.swift         # 1枚のカード（DragGesture本体）
        └── ChoiceStamp.swift      # LIKE / NOPE スタンプ
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `SwipeCardsMainView()` に変更

## 学習ポイント

### DragGesture — ドラッグ量を取得する
```swift
.gesture(
    DragGesture()
        .onChanged { value in
            dragOffset = value.translation   // ドラッグ中の移動量
        }
        .onEnded { value in
            // 指を離した瞬間の最終的な移動量で判定する
        }
)
```

### offset + rotationEffect — ドラッグに追従させる
```swift
.offset(dragOffset)
.rotationEffect(.degrees(Double(dragOffset.width / 20)))
// 横方向の移動量を回転角に変換すると、カードが「傾きながら動く」自然な見た目になる
```

### しきい値判定 → スナップバック or 投げ出し
```swift
if translation.width > threshold {
    // 投げ出す: easeOutで画面外まで一気に移動
} else {
    // 戻す: springで弾力のある動きで .zero に戻す
    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        dragOffset = .zero
    }
}
```

### @Binding を使ったプログラム的トリガー
```swift
@Binding var programmaticSwipe: SwipeDirection?

.onChange(of: programmaticSwipe) { direction in
    guard let direction else { return }
    // ボタンから来た指示でも、ドラッグで投げた時と同じアニメーションを再生する
}
```
ボタンとドラッグ、2つの入力経路を同じ「投げ出しアニメーション」に集約できる。

## 発展課題
- `.sensoryFeedback(.impact, trigger:)` でスワイプ確定時に触覚フィードバック（iOS 17+）
- 上方向スワイプで「スーパーライク」を追加する
- カードが画面外に出た後、`opacity` も0にフェードさせてより自然にする
- `.bouncy` アニメーション（iOS 17+）に置き換えて挙動を比較する
