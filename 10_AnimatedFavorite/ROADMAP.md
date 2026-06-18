# 10 AnimatedFavorite ロードマップ

完成形: withAnimation / scaleEffect / .transition で「弾む→お気に入り」「縮小→削除」を体感する

---

## Step 1 — データモデルと ViewModel を作る
**ファイル:** `Models/FavoriteItem.swift`、`ViewModels/ItemViewModel.swift` を新規作成

### 1-1: FavoriteItem struct
```swift
import Foundation
import SwiftUI

struct FavoriteItem: Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var color: Color
    var isFavorited: Bool

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        color: Color,
        isFavorited: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.color = color
        self.isFavorited = isFavorited
    }
}

extension FavoriteItem {
    static let samples: [FavoriteItem] = [
        FavoriteItem(name: "SwiftUI", emoji: "🍎", color: .blue, isFavorited: true),
        FavoriteItem(name: "Combine", emoji: "🔗", color: .purple),
        FavoriteItem(name: "Swift", emoji: "⚡️", color: .orange, isFavorited: true),
        FavoriteItem(name: "Xcode", emoji: "🛠", color: .cyan),
        FavoriteItem(name: "Core Data", emoji: "🗄", color: .brown),
        FavoriteItem(name: "WidgetKit", emoji: "📱", color: .green, isFavorited: true),
        FavoriteItem(name: "ARKit", emoji: "🥽", color: .indigo),
        FavoriteItem(name: "Metal", emoji: "🎮", color: .red),
        FavoriteItem(name: "CloudKit", emoji: "☁️", color: .teal),
        FavoriteItem(name: "StoreKit", emoji: "💳", color: .mint),
        FavoriteItem(name: "AVFoundation", emoji: "🎵", color: .pink),
        FavoriteItem(name: "MapKit", emoji: "🗺", color: .yellow),
    ]
}
```
グリッドが3列なので、最低でも4行分（12件）のサンプルを用意しておくとスクロールも確認できる。

### 1-2: ItemViewModel（アニメーションの発火タイミングを一元管理する）
```swift
import Foundation
import Combine

class ItemViewModel: ObservableObject {
    @Published var items: [FavoriteItem] = FavoriteItem.samples

    // グリッド側でハートをタップした瞬間に弾むアイテムのID。
    // 弾むアニメーションのタイミング（いつ始まり、いつ終わるか）はVMが一元管理する。
    @Published var bouncingItemID: UUID? = nil

    var favoritedItems: [FavoriteItem] {
        items.filter(\.isFavorited)
    }

    func toggleFavorite(_ item: FavoriteItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavorited.toggle()
    }

    // グリッドでハートをタップした時: お気に入り状態を切り替えつつ弾むアニメーションを発火
    func toggleFavoriteWithBounce(_ item: FavoriteItem) {
        toggleFavorite(item)
        bouncingItemID = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if self?.bouncingItemID == item.id {
                self?.bouncingItemID = nil
            }
        }
    }

    // お気に入りリストでハートをタップした時: 縮小アニメーション分だけ遅らせて実際に削除する
    func removeFavoriteAfterShrink(_ item: FavoriteItem, delay: TimeInterval = 0.25) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.toggleFavorite(item)
        }
    }
}
```
「いつ弾むか／いつ縮小して消えるか」というタイミングの計算をViewではなくVMに置く。
こうすると `ItemCell`/`FavoriteRow` は「VMの状態を見て見た目を変えるだけ」のシンプルな
Viewになり、タップ→状態変化→Viewが反応、という一方向の流れを保てる。

---

## Step 2 — グリッドと弾むアニメーションを作る
**ファイル:** `Views/ItemGridView.swift`、`Views/Components/ItemCell.swift` を新規作成

### 2-1: グリッドの骨格（まずアニメーションなし）
```swift
import SwiftUI

struct ItemGridView: View {
    @ObservedObject var viewModel: ItemViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.items) { item in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(item.color.opacity(0.15))
                                .frame(height: 90)
                                .overlay { Text(item.emoji).font(.system(size: 40)) }
                            Text(item.name).font(.caption.bold()).lineLimit(1)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Appleフレームワーク")
        }
    }
}

#Preview {
    ItemGridView(viewModel: ItemViewModel())
}
```
▶ ここで確認: 3列グリッドが表示されること

### 2-2: ItemCell を切り出し、VMの状態を見て弾むようにする
```swift
import SwiftUI

struct ItemCell: View {
    let item: FavoriteItem
    @ObservedObject var viewModel: ItemViewModel

    // 弾むアニメーションの発火タイミングはVMが管理する（toggleFavoriteWithBounce）。
    // Viewはその状態を見て見た目（scaleEffect）を反映するだけ。
    private var isBouncing: Bool {
        viewModel.bouncingItemID == item.id
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // アイテム背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.color.opacity(0.15))
                    .frame(height: 90)
                    .overlay {
                        Text(item.emoji)
                            .font(.system(size: 40))
                            // .scaleEffect でハートタップ時にアイテムが弾む
                            .scaleEffect(isBouncing ? 1.2 : 1.0)
                    }

                // ハートボタン（右上オーバーレイ）
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        viewModel.toggleFavoriteWithBounce(item)
                    }
                } label: {
                    Image(systemName: item.isFavorited ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(item.isFavorited ? .red : .secondary)
                        .padding(6)
                        .background(.regularMaterial, in: Circle())
                }
                .padding(6)
            }

            Text(item.name)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ItemCell(item: FavoriteItem.samples[0], viewModel: ItemViewModel())
        ItemCell(item: FavoriteItem.samples[1], viewModel: ItemViewModel())
    }
    .padding()
}
```
`ItemCell` は `onToggle: () -> Void` のようなクロージャを受け取らず、`viewModel` を直接
持つ。アニメーションの開始（`withAnimation`）はボタンのアクション内、つまりタップした
その場で `viewModel.toggleFavoriteWithBounce(item)` を呼ぶだけでよい。

▶ ここで確認: ハートタップで絵文字がバウンドし、ハートの塗りつぶしが切り替わること

### 2-3: ItemGridView から ItemCell を呼び出す
```swift
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.items) { item in
                        ItemCell(item: item, viewModel: viewModel)
                    }
                }
```
▶ ここで確認: グリッド全体で12個のアイテムが3列に並ぶこと

---

## Step 3 — FavoritesView でお気に入り一覧を表示する
**ファイル:** `Views/FavoritesView.swift` を新規作成

### 3-1: 空状態とリストの骨格
```swift
import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: ItemViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoritedItems.isEmpty {
                    ContentUnavailableView(
                        "お気に入りなし",
                        systemImage: "heart.slash",
                        description: Text("グリッドでハートをタップして追加しましょう")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favoritedItems) { item in
                                HStack(spacing: 16) {
                                    Text(item.emoji).font(.title2)
                                    Text(item.name).font(.headline)
                                    Spacer()
                                    Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .foregroundStyle(.red)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("お気に入り")
        }
    }
}

#Preview {
    FavoritesView(viewModel: ItemViewModel())
}
```
`List`ではなく`ScrollView` + `LazyVStack`を使う。理由はStep 5で各行にカスタムの
削除アニメーション（ハート縮小→消える）を付けるため、`List`の標準スワイプ削除UIに
頼らず、行ごとに完全にカスタムなレイアウト・挙動を持たせたいから。

▶ ここで確認: お気に入り済みアイテムがカード状に表示されること。0件だと空状態の
メッセージが出ること

---

## Step 4 — TabView でグリッドとリストを繋ぐ
**ファイル:** `Views/AnimatedMainView.swift` を新規作成

```swift
import SwiftUI

struct AnimatedMainView: View {
    @StateObject private var viewModel = ItemViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ItemGridView(viewModel: viewModel)
                .tabItem { Label("すべて", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            FavoritesView(viewModel: viewModel)
                .tabItem { Label("お気に入り", systemImage: "heart.fill") }
                .badge(viewModel.favoritedItems.count)
                .tag(1)
        }
    }
}

#Preview { AnimatedMainView() }
```
`selectedTab` は今のところ画面遷移には使っていないが、タブを明示的に`.tag`で
区別しておくことで、後からコードでタブを切り替える機能（例: 削除後に自動で
「すべて」タブに戻る）を追加しやすくなる。

▶ ここで確認: グリッドでハートをタップするとお気に入りタブのバッジ数が変わること

---

## Step 5 — .transition でリスト追加・削除アニメーションを追加する
**ファイル:** `Views/FavoritesView.swift`、`Views/Components/FavoriteRow.swift` を編集/新規作成

### 5-1: バナーと .transition / .animation を追加する
```swift
                    ScrollView {
                        VStack(spacing: 0) {
                            // お気に入りカウントバナー
                            HStack {
                                Text("\(viewModel.favoritedItems.count) 件のお気に入り")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                            // お気に入りリスト
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.favoritedItems) { item in
                                    FavoriteRow(item: item, viewModel: viewModel)
                                        // .transition: Viewが追加/削除される際のアニメーション
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                }
                            }
                            .padding()
                        }
                        // .animation: @Publishedの変化を自動的にアニメーション
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.favoritedItems.map(\.id))
                    }
```
`.animation(_:value:)` の `value` に `favoritedItems.map(\.id)` のような「ID配列」を
渡すのがポイント。配列の中身（順序・要素数）が変わったときだけアニメーションが
発火し、各アイテムの中身（`isFavorited`以外のプロパティ）の変化では再発火しない。

▶ ここで確認: グリッドでハートをタップするとFavoritesViewのリストがアニメーション付きで増減すること

### 5-2: FavoriteRow でハート縮小→削除のシーケンス
```swift
import SwiftUI

struct FavoriteRow: View {
    let item: FavoriteItem
    @ObservedObject var viewModel: ItemViewModel

    // ハート縮小アニメーション用（このViewだけの見た目の状態）
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(item.emoji)
                    .font(.title2)
            }

            Text(item.name)
                .font(.headline)

            Spacer()

            // 削除ボタン（ハートをタップで解除）
            Button {
                // ハートを縮小 → 縮小が終わったタイミングでVMに削除を依頼する。
                // 削除後にこのView自体は破棄されるため、scaleを元に戻す処理は不要
                // （以前はここで heartScale = 1.0 にリセットしていたが、リストの
                // 退場アニメーションと競合して一瞬ハートが戻る見た目のバグになっていた）。
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    heartScale = 1.4
                }
                withAnimation(.spring(response: 0.3).delay(0.15)) {
                    heartScale = 0.0
                }
                viewModel.removeFavoriteAfterShrink(item)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .scaleEffect(heartScale)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    FavoriteRow(item: FavoriteItem.samples[0], viewModel: ItemViewModel())
        .padding()
}
```
`DispatchQueue.main.asyncAfter`で遅延を作る代わりに`withAnimation(...).delay(0.15)`を
使う。`viewModel.removeFavoriteAfterShrink(item)`はVM側で`asyncAfter`によって実際の
削除（`toggleFavorite`）を遅らせるので、ハートが縮小し終わるタイミングと行が
リストから消えるタイミングがちょうど合う。行が削除された後はViewごと破棄されるため
`heartScale`を`1.0`に戻す必要はない。

▶ ここで確認: ハートが拡大→縮小→消えるシーケンスアニメーションが動くこと。連続で
何度かタップしても元のハートが一瞬戻って見えるような不自然な挙動がないこと

---

## 完成チェックリスト
- [ ] ハートタップで絵文字がバウンスする（withAnimation + scaleEffect、`ItemViewModel.bouncingItemID`経由）
- [ ] スプリングアニメーションのパラメータ（response/dampingFraction）を変えて違いを体感した
- [ ] .transition で追加・削除が左右スライドでアニメーションされる
- [ ] FavoriteRow のハートが拡大→縮小→削除の3段階シーケンスで動き、削除後に見た目が戻らない
- [ ] グリッドとお気に入りタブでお気に入り状態が同期している
- [ ] アニメーションの発火タイミングをVM（ItemViewModel）に集約する設計の理由を説明できる

## アニメーションまとめ

| 手法 | 用途 |
|---|---|
| `withAnimation { }` | 状態変化をアニメーション化 |
| `.scaleEffect(x)` | 拡大縮小 |
| `.transition(.move(...))` | View追加・削除のトランジション |
| `.animation(_:value:)` | 値の変化に自動追随 |
| `.delay(_:)` | アニメーションの開始を遅らせ、シーケンスを作る |

---

## 設計メモ: なぜ matchedGeometryEffect を使わなかったか
最初は「グリッドのハート」と「お気に入りリストのハート」を `matchedGeometryEffect` で
繋ぐヒーローアニメーションを試みたが、グリッドと一覧は別タブ（`TabView`）に属し
同時にView階層へ存在しないため、`matchedGeometryEffect` は原理的に発火しない
（共有Namespaceにしても解決できない構成だった）。
そのため、画面間を跨ぐアニメーションではなく「各画面内で完結する弾む/縮小」に
方針を変更し、発火タイミングは `ItemViewModel`（`toggleFavoriteWithBounce`/
`removeFavoriteAfterShrink`）に集約した。これがStep 1〜5の設計になっている。
