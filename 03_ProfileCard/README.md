# 03 ProfileCard

## 学習テーマ
- `ZStack` — Viewを奥行き方向に重ねる
- `overlay` — 既存Viewの上にViewを重ねる修飾子
- `Sheet` — モーダル下からスライドアップ表示

## 完成イメージ
- グラデーション背景のプロフィールカード一覧
- カードのinfoボタンでシート表示
- フォローボタンのトグル
- シート内で詳細プロフィール表示

## ファイル構成
```
03_ProfileCard/
├── Models/
│   └── Profile.swift             # プロフィールデータモデル
├── ViewModels/
│   └── ProfileViewModel.swift    # フォロー状態・統計フォーマット
└── Views/
    ├── ProfileListView.swift     # カード一覧画面（エントリーポイント）
    ├── ProfileCardView.swift     # グラデーションカードUI（ZStack + overlay + sheet）
    ├── ProfileDetailSheet.swift  # モーダルシート詳細画面
    └── Components/
        └── ProfileStatView.swift # 統計表示（カード/詳細シートで共用）
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `ProfileListView()` に変更

## 学習ポイント

### ZStack — 奥行き方向に重ねる
```swift
ZStack(alignment: .bottomLeading) {
    // 一番下のView（背景）
    Color.blue
    // 上に重なるView
    Text("前面に表示")
}
```
`alignment` で重なりの基準点を指定する。

### overlay — 既存Viewに重ねる修飾子
```swift
Image(...)
    .overlay(alignment: .topTrailing) {
        Badge()  // 右上に重ねて表示
    }
```
`ZStack` との違い: `overlay` はベースViewのサイズに影響しない。

### sheet — モーダル表示
```swift
@State private var showDetail = false

Button("開く") { showDetail = true }
    .sheet(isPresented: $showDetail) {
        DetailView()  // ここに表示するView
    }
```
`@Environment(\.dismiss)` でシート内から閉じる。

### FullScreenCover との使い分け
- `sheet`: 下からスライドアップ、後ろが少し見える → 一時的な追加情報
- `fullScreenCover`: 完全に画面を覆う → 集中が必要な操作

## 発展課題
- `presentationDetents([.medium, .large])` でシートの高さを制御
- `matchedGeometryEffect` でカードから詳細への遷移アニメーション
- カード編集シート（`@Binding` でデータを渡す）
