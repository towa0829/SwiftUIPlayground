# 12 Game2048

## 学習テーマ
- `DragGesture` — スワイプ方向の判定（11からの発展）
- 安定IDを使った**位置アニメーション** — `ForEach(id:)` + `.position` + `withAnimation`
- `.scaleEffect` — 合体時のポップ
- `.transition(.scale)` — 新タイル出現のアニメーション
- ViewModelへのロジック集約 — 移動・合体・出現・ゲームオーバー判定

## 完成イメージ
- 4x4の盤面で2048パズルをプレイできる
- 上下左右にスワイプするとタイルがスーッと滑って詰まる
- 同じ数字が隣接していると合体して2倍になり、ポップして見える
- 盤面が変化した時だけ新しいタイルがふわっと出現する
- スコア表示、ゲームオーバー判定とオーバーレイ、「もう一度」でリセット

## ファイル構成
```
12_Game2048/
├── Models/
│   └── Tile.swift                 # タイル1枚分のモデル（id, value, row, col, isMerged）
├── ViewModels/
│   └── GameViewModel.swift        # 移動・合体・出現・ゲームオーバー判定のロジック全部
└── Views/
    ├── Game2048MainView.swift     # エントリーポイント（スコア + 盤面 + スワイプ + ゲームオーバー）
    └── Components/
        ├── BoardBackground.swift  # 4x4の空セル背景 + 位置計算ヘルパー(BoardLayout)
        └── TileView.swift         # タイル1枚の見た目
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `Game2048MainView()` に変更

## 学習ポイント

### 安定IDで「滑る」アニメーションを作る
```swift
ForEach(viewModel.tiles) { tile in   // tile.id は移動の前後で変わらない
    TileView(tile: tile)
}
```
```swift
// TileViewの中
.position(BoardLayout.position(row: tile.row, col: tile.col))
```
同じ`id`を持つタイルの`row`/`col`（→ `.position`の座標）が変わるとき、変更を
`withAnimation`で包んでいれば、SwiftUIはその座標変化を自動的に補間してくれる。
これが「タイルが滑って見える」しくみの本質。`matchedGeometryEffect`を使わなくても、
**同じ画面の中で同じIDのViewを動かすだけ**なら、`.position` + `withAnimation`で十分。

### スワイプ方向の判定
```swift
DragGesture(minimumDistance: 20)
    .onEnded { value in
        let translation = value.translation
        if abs(translation.width) > abs(translation.height) {
            // 横方向の移動が大きい → 左右
        } else {
            // 縦方向の移動が大きい → 上下
        }
    }
```

### 合体時のポップ
```swift
.scaleEffect(tile.isMerged ? 1.15 : 1.0)
```
`isMerged`はそのタイルが「直前の移動で合体して生まれたか」を表す一時的なフラグ。
`withAnimation`の中で`true`→（次の移動で）`false`に変わることで、合体した瞬間に
一回だけ拡大して見える。

### 新タイル出現のトランジション
```swift
.transition(.scale.combined(with: .opacity))
```
`tiles`配列に新しいタイルが追加された瞬間、`ForEach`がそのタイルのViewを新規に
挿入する。`.transition`はこの「挿入」アニメーションを指定する修飾子。

## 発展課題
- `.sensoryFeedback(.impact, trigger:)` で合体時に触覚フィードバック（iOS 17+）
- ベストスコアを `UserDefaults` に保存する
- 5x5など盤面サイズを可変にする
- 合体で消える側のタイルも、合体先まで滑ってから消えるように改良する
  （本教材では簡略化のため、合体で消えるタイルはその場で即座に消える。詳細は
  ROADMAP末尾の「設計メモ」を参照）
