# 10 AnimatedFavorite

## 学習テーマ
- `Animation` — スプリング・イージングアニメーション
- `matchedGeometryEffect` — 2つのViewを連携したヒーローアニメーション（概念として学ぶ。下記「完成イメージ」参照）
- `.transition` — View追加・削除時のアニメーション

## 完成イメージ
- フレームワークグリッド（3列）
- ハートタップでお気に入り登録（弾むアニメーション、ViewModelが発火タイミングを管理）
- お気に入りタブでリスト表示
- アイテム削除時のスライドアウトアニメーション（ハートの縮小→ViewModel経由で削除）

> **学習ノート**: 当初は「グリッド↔お気に入りリスト間でハートが飛ぶ `matchedGeometryEffect`」を狙ったが、両者は別タブ（`TabView`）にあり同時にView階層へ存在しないため、`matchedGeometryEffect` は原理的に発火しない。これは実際にハマりやすい典型的な誤用パターンなので、`matchedGeometryEffect` 自体は学習テーマとして残しつつ、実装は**各画面内で完結するバウンス/縮小アニメーション**（ViewModelがタイミングを管理）に変更している。

## ファイル構成
```
10_AnimatedFavorite/
├── Models/
│   └── FavoriteItem.swift        # アイテムモデル
├── ViewModels/
│   └── ItemViewModel.swift       # お気に入り管理 + アニメーションタイミング管理
└── Views/
    ├── AnimatedMainView.swift    # TabView（エントリーポイント）
    ├── ItemGridView.swift        # グリッド一覧
    ├── FavoritesView.swift       # お気に入りリスト + トランジション
    └── Components/
        ├── ItemCell.swift        # グリッドセル（弾むアニメーション）
        └── FavoriteRow.swift     # お気に入り行（縮小アニメーション）
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `AnimatedMainView()` に変更

## 学習ポイント

### withAnimation — 変更をアニメーション化
```swift
Button("タップ") {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
        isExpanded.toggle()  // この変更がアニメーションされる
    }
}
```
`withAnimation` ブロック内の状態変更が全てアニメーション対象になる。

### Animation の種類
```swift
.easeIn / .easeOut / .easeInOut  // 標準イージング
.linear                           // 等速
.spring(response:dampingFraction:) // バネアニメーション
    // response: アニメーション時間の目安（秒）
    // dampingFraction: バネの硬さ（0=ずっと揺れる、1=揺れない）
.bouncy                           // バウンスアニメーション（iOS 17+）
```

### matchedGeometryEffect — ヒーローアニメーション
```swift
// 2つの場所で同じIDを指定すると、Viewが「飛んでいく」ように見える
@Namespace private var animation

// 場所A（グリッド）
Image(systemName: "heart.fill")
    .matchedGeometryEffect(id: "heart-\(item.id)", in: animation)

// 場所B（リスト）
Image(systemName: "heart.fill")
    .matchedGeometryEffect(id: "heart-\(item.id)", in: animation)
```
同じ `Namespace.ID` と同じ `id` を共有したViewが、表示が切り替わる時にアニメーションする。

### .transition — View追加・削除のアニメーション
```swift
if isVisible {
    MyView()
        .transition(.move(edge: .trailing))  // 右からスライドイン
}

// 複合トランジション
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### .animation(_:value:) — 値の変化で自動アニメーション
```swift
LazyVStack { ... }
    .animation(.spring(), value: items.map(\.id))
    // items が変わるたびにアニメーションが走る
```

## 発展課題
- `PhaseAnimator` で複数フェーズのアニメーション（iOS 17+）
- `KeyframeAnimator` でキーフレームアニメーション（iOS 17+）
- `TimelineView` で時間ベースのアニメーション
