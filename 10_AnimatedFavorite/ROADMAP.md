# 10 AnimatedFavorite ロードマップ

完成形: withAnimation / matchedGeometryEffect / .transition でアニメーションを体感する

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

    init(id: UUID = UUID(), name: String, emoji: String,
         color: Color, isFavorited: Bool = false) {
        self.id = id; self.name = name; self.emoji = emoji
        self.color = color; self.isFavorited = isFavorited
    }
}

extension FavoriteItem {
    static let samples: [FavoriteItem] = [
        FavoriteItem(name: "SwiftUI", emoji: "🍎", color: .blue, isFavorited: true),
        FavoriteItem(name: "Combine", emoji: "🔗", color: .purple),
        FavoriteItem(name: "Swift",   emoji: "⚡️", color: .orange, isFavorited: true),
        FavoriteItem(name: "Xcode",   emoji: "🛠",  color: .cyan),
        FavoriteItem(name: "WidgetKit", emoji: "📱", color: .green, isFavorited: true),
        FavoriteItem(name: "ARKit",   emoji: "🥽",  color: .indigo),
    ]
}
```

### 1-2: ItemViewModel
```swift
import Foundation

class ItemViewModel: ObservableObject {
    @Published var items: [FavoriteItem] = FavoriteItem.samples

    var favoritedItems: [FavoriteItem] { items.filter(\.isFavorited) }

    func toggleFavorite(_ item: FavoriteItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isFavorited.toggle()
    }
}
```

---

## Step 2 — withAnimation の基本を学ぶ
**ファイル:** `Views/ItemGridView.swift` を新規作成（まずアニメーションなし）

### 2-1: グリッドの骨格（アニメーションなし）
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
            .navigationTitle("フレームワーク")
        }
    }
}

#Preview {
    ItemGridView(viewModel: ItemViewModel())
}
```
▶ ここで確認: 3列グリッドが表示されること

### 2-2: withAnimation でハートタップをアニメーション化する
```swift
// ItemCell struct を作り、グリッドセルを分離する
struct ItemCell: View {
    let item: FavoriteItem
    let onToggle: () -> Void

    @State private var isAnimating = false  // アニメーション状態

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.color.opacity(0.15))
                    .frame(height: 90)
                    .overlay {
                        Text(item.emoji)
                            .font(.system(size: 40))
                            // scaleEffect: isAnimating が true の時に1.2倍に拡大
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                    }

                // ハートボタン
                Button {
                    // withAnimation: このブロック内の状態変化がアニメーションされる
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                        isAnimating = true
                    }
                    // 0.3秒後に元に戻す
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3)) {
                            isAnimating = false
                        }
                    }
                    onToggle()
                } label: {
                    Image(systemName: item.isFavorited ? "heart.fill" : "heart")
                        .foregroundStyle(item.isFavorited ? .red : .secondary)
                        .padding(6)
                        .background(.regularMaterial, in: Circle())
                }
                .padding(6)
            }
            Text(item.name).font(.caption.bold()).lineLimit(1)
        }
    }
}
```
▶ ここで確認: ハートタップで絵文字がバウンドすること

### 2-3: LazyVGrid の ForEach で ItemCell を使う
```swift
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.items) { item in
                        ItemCell(item: item) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                viewModel.toggleFavorite(item)
                            }
                        }
                    }
                }
```
▶ ここで確認: ハートの塗りつぶしが切り替わる時にスプリングアニメーションがかかること

---

## Step 3 — matchedGeometryEffect を準備する
**ファイル:** `Views/ItemGridView.swift` を編集

### 3-1: @Namespace を宣言する
```swift
struct ItemGridView: View {
    @ObservedObject var viewModel: ItemViewModel
    // matchedGeometryEffect に必要: 画面間で共有するアニメーション空間
    @Namespace private var animation
```

### 3-2: ItemCell にnamespaceを渡す
```swift
// ItemCell の引数に追加
struct ItemCell: View {
    let item: FavoriteItem
    let namespace: Namespace.ID   // ← 追加
    let onToggle: () -> Void
```

```swift
// 呼び出し側で渡す
                        ItemCell(item: item, namespace: animation) { ... }
```

### 3-3: ItemCell のハートに .matchedGeometryEffect を付ける
```swift
                Image(systemName: item.isFavorited ? "heart.fill" : "heart")
                    .foregroundStyle(item.isFavorited ? .red : .secondary)
                    .padding(6)
                    .background(.regularMaterial, in: Circle())
                    // matchedGeometryEffect: 同じID+Namespaceを持つViewと連動
                    .matchedGeometryEffect(id: "heart-\(item.id)", in: namespace)
```
▶ 理解: `id: "heart-\(item.id)"` が同じViewが2か所にある時、表示が切り替わる時に「飛ぶ」アニメーションが起きる。まだ対応するViewがないので変化はない。

---

## Step 4 — FavoritesView を作り matchedGeometryEffect を繋ぐ
**ファイル:** `Views/FavoritesView.swift` を新規作成

### 4-1: FavoritesView の骨格
```swift
import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: ItemViewModel
    @Namespace private var animation  // グリッドと同じ名前空間を共有する必要がある

    var body: some View {
        NavigationStack {
            List(viewModel.favoritedItems) { item in
                HStack(spacing: 16) {
                    Text(item.emoji).font(.title2)
                    Text(item.name).font(.headline)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
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
▶ ここで確認: お気に入り済みアイテムがリスト表示されること

### 4-2: matchedGeometryEffect の ID を合わせる（効果を体感する）
```swift
// ⚠️ 重要: グリッドとリストで同じ Namespace を共有するためには、
// どちらのViewも同じ @Namespace の ID を使う必要がある。
// 今の構造では TabView が分離しているため、namespace を AnimatedMainView で作り、
// 両方に渡す必要がある。

// 暫定確認: 同じFavoritesView内でハートをタップすると削除アニメーションが起きること
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            viewModel.toggleFavorite(item)
                        }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.title2).foregroundStyle(.red)
                            .matchedGeometryEffect(id: "fav-heart-\(item.id)", in: animation)
                    }
```
▶ ここで確認: ハートタップでアイテムがリストから消えること（matchedGeometryEffectがない場合と比べる）

---

## Step 5 — .transition でリスト追加・削除アニメーションを追加する
**ファイル:** `Views/FavoritesView.swift` を編集

### 5-1: .transition の基本形
```swift
            if viewModel.favoritedItems.isEmpty {
                ContentUnavailableView(
                    "お気に入りなし",
                    systemImage: "heart.slash",
                    description: Text("グリッドでハートをタップして追加しましょう")
                )
            } else {
                List {
                    ForEach(viewModel.favoritedItems) { item in
                        FavoriteRow(item: item, viewModel: viewModel)
                            // transition: このViewが追加・削除される時のアニメーション
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                // animation: favoritedItems の変化時にアニメーションを実行
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.favoritedItems.map(\.id))
            }
```
▶ ここで確認: グリッドでハートをタップするとFavoritesViewのリストがアニメーション付きで増減すること

### 5-2: FavoriteRow でハート縮小→削除のシーケンス
```swift
struct FavoriteRow: View {
    let item: FavoriteItem
    @ObservedObject var viewModel: ItemViewModel
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 16) {
            Text(item.emoji).font(.title2)
            Text(item.name).font(.headline)
            Spacer()
            Button {
                // ① 拡大
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { heartScale = 1.4 }
                // ② 縮小して消える
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3)) { heartScale = 0.0 }
                }
                // ③ 実際に削除
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.toggleFavorite(item)
                    heartScale = 1.0
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2).foregroundStyle(.red)
                    .scaleEffect(heartScale)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```
▶ ここで確認: ハートが拡大→縮小→消えるシーケンスアニメーションが動くこと

---

## Step 6 — TabView でグリッドとリストを繋ぐ
**ファイル:** `Views/AnimatedMainView.swift` を新規作成

```swift
import SwiftUI

struct AnimatedMainView: View {
    @StateObject private var viewModel = ItemViewModel()

    var body: some View {
        TabView {
            ItemGridView(viewModel: viewModel)
                .tabItem { Label("すべて", systemImage: "square.grid.2x2.fill") }

            FavoritesView(viewModel: viewModel)
                .tabItem { Label("お気に入り", systemImage: "heart.fill") }
                .badge(viewModel.favoritedItems.count)
        }
    }
}

#Preview { AnimatedMainView() }
```
▶ ここで確認: グリッドでハートをタップするとお気に入りタブのバッジ数が変わること

---

## 完成チェックリスト
- [ ] ハートタップで絵文字がバウンスする（withAnimation + scaleEffect）
- [ ] スプリングアニメーションのパラメータ（response/dampingFraction）を変えて違いを体感した
- [ ] .transition で追加・削除が左右スライドでアニメーションされる
- [ ] FavoriteRow のハートが拡大→縮小→削除の3段階シーケンスで動く
- [ ] グリッドとお気に入りタブでお気に入り状態が同期している
- [ ] matchedGeometryEffect の仕組み（Namespace + id）を理解した

## アニメーションまとめ

| 手法 | 用途 |
|---|---|
| `withAnimation { }` | 状態変化をアニメーション化 |
| `.scaleEffect(x)` | 拡大縮小 |
| `.transition(.move(...))` | View追加・削除のトランジション |
| `.animation(_:value:)` | 値の変化に自動追随 |
| `matchedGeometryEffect` | 2箇所のViewを繋ぐヒーローアニメーション |

---

## 改良ノート（写経後の修正）
- **`matchedGeometryEffect` が機能しないバグを修正**: グリッドとお気に入りタブが別々の `@Namespace` を持ち、かつ別タブ（同時にView階層に存在しない）のため、ヒーローアニメーションは原理的に発火しなかった。共有Namespaceでは解決できない構成だったため、各画面内で完結する「弾む/縮小」アニメーションに変更し、発火タイミングは `ItemViewModel`（`toggleFavoriteWithBounce`/`removeFavoriteAfterShrink`）で管理するようにした。
- `FavoritesView` 側にあった手動 `DispatchQueue` 駆動と親の `.transition`/`.animation` が二重に掛かってグリッチしていた処理を解消（ハートを縮小させた後にVM経由で削除、スケールのリセット処理は削除）。
- グリッド名・ハートアイコンの `.caption.bold()`/`.subheadline` を `.subheadline.bold()`/`.title3` に昇格。
- `ItemCell`/`FavoriteRow` を `Views/Components/` へ分離。
