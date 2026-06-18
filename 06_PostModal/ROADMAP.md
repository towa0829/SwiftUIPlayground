# 06 PostModal ロードマップ

完成形: Sheet・FullScreenCover・@Binding の使い分けを体感する

---

## Step 1 — データモデルと ViewModel を作る
**ファイル:** `Models/FeedPost.swift`、`ViewModels/FeedViewModel.swift` を新規作成

### 1-1: FeedPost struct
```swift
import Foundation

struct FeedPost: Identifiable {
    let id: UUID
    var title: String
    var bodyText: String   // 注意: body は SwiftUI の予約語なので bodyText に
    var authorName: String
    var createdAt: Date
    var likesCount: Int
    var isLiked: Bool

    init(id: UUID = UUID(), title: String, bodyText: String,
         authorName: String, createdAt: Date = Date(),
         likesCount: Int = 0, isLiked: Bool = false) {
        self.id = id; self.title = title; self.bodyText = bodyText
        self.authorName = authorName; self.createdAt = createdAt
        self.likesCount = likesCount; self.isLiked = isLiked
    }
}

extension FeedPost {
    static let samples: [FeedPost] = [
        FeedPost(title: "SheetとFullScreenCoverの違い",
                 bodyText: "sheetは後ろが少し見える。fullScreenCoverは完全に覆う。",
                 authorName: "Towa", likesCount: 34),
        FeedPost(title: "@Bindingで親子データを繋ぐ",
                 bodyText: "子Viewから親のstateを変更するには@Bindingを使う。",
                 authorName: "Hana", likesCount: 56),
    ]
}
```

### 1-2: FeedViewModel
```swift
class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = FeedPost.samples

    func toggleLike(_ post: FeedPost) {
        guard let i = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[i].isLiked.toggle()
        posts[i].likesCount += posts[i].isLiked ? 1 : -1
    }

    func addPost(title: String, bodyText: String) {
        posts.insert(FeedPost(title: title, bodyText: bodyText, authorName: "自分"), at: 0)
    }
}
```
▶ ここで確認: ビルドエラーがないこと

---

## Step 2 — フィード一覧と Sheet の基本形
**ファイル:** `Views/FeedView.swift` を新規作成

### 2-1: FeedView の骨格（まずシートなし）
```swift
import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.posts) { post in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title).font(.headline)
                    Text(post.bodyText).font(.body).foregroundStyle(.secondary).lineLimit(2)
                    Label("\(post.likesCount)", systemImage: "heart")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("フィード")
        }
    }
}

#Preview { FeedView() }
```
▶ ここで確認: Preview でリストが表示されること

### 2-2: Sheet のトリガーを追加する
```swift
    @State private var showNewPostSheet = false

    // .navigationTitle の後に追加
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showNewPostSheet = true } label: {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
        }
    }
    // sheet モディファイア
    .sheet(isPresented: $showNewPostSheet) {
        Text("新規投稿フォーム（仮）")
    }
```
▶ ここで確認: +ボタンで下からシートがスライドアップすること

---

## Step 3 — NewPostSheet（@Binding の練習）
**ファイル:** `Views/NewPostSheet.swift` を新規作成

### 3-1: 入力フォームの骨格
```swift
import SwiftUI

struct NewPostSheet: View {
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }
                Section("本文") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("投稿する") {
                        viewModel.addPost(title: title, bodyText: bodyText)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview { NewPostSheet(viewModel: FeedViewModel()) }
```
▶ ここで確認: 「キャンセル」と「投稿する」で dismiss() が呼ばれること

### 3-2: @Binding を使った文字数カウンターを追加
```swift
// NewPostSheet の Form の最後に追加
                Section {
                    CharacterCountView(text: $bodyText, limit: 200)
                }

// NewPostSheet の外側に定義
struct CharacterCountView: View {
    @Binding var text: String  // ← 親のstateへの参照
    let limit: Int

    var body: some View {
        HStack {
            Text("文字数")
            Spacer()
            Text("\(text.count) / \(limit)")
                .foregroundStyle(text.count > limit ? .red : .secondary)
        }
    }
}
```
▶ 理解: `@Binding var text` は `@State var text` の「コピー」ではなく「参照」。
`CharacterCountView` の中で `text` を変更すると `NewPostSheet` の `bodyText` も変わる。

### 3-3: presentationDetents でシートの高さを制御
```swift
    // NewPostSheet の NavigationStack の後に追加
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
```
▶ ここで確認: シートが途中の高さで止まり、上にドラッグで全画面になること

### 3-4: FeedView の sheet を実際の NewPostSheet に差し替える
```swift
    .sheet(isPresented: $showNewPostSheet) {
        NewPostSheet(viewModel: viewModel)   // Text("仮") → 本物に
    }
```
▶ ここで確認: 投稿後にフィードの先頭に追加されること

---

## Step 4 — FullScreenCover で詳細画面を作る
**ファイル:** `Views/PostDetailFullScreen.swift` を新規作成、その後 `FeedView.swift` を編集

### 4-1: PostDetailFullScreen の骨格
```swift
import SwiftUI

struct PostDetailFullScreen: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(post.title).font(.title.bold())
                    Text(post.bodyText).font(.body).lineSpacing(6)
                }
                .padding(20)
            }
            .navigationTitle("詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
```

### 4-2: FeedView に `item: Binding` 形式の fullScreenCover を追加
```swift
    // item: にBindingを渡す形式 → selectedが非nilの時に自動表示
    @State private var selectedPostForDetail: FeedPost? = nil

    // .sheet の後に追加
    .fullScreenCover(item: $selectedPostForDetail) { post in
        PostDetailFullScreen(post: post, viewModel: viewModel)
    }
```
▶ 理解: `isPresented: Bool` と `item: Optional` の2パターンがある。
`item` を使う場合は対象が `Identifiable` である必要がある。

### 4-3: 投稿カードに「全画面で見る」ボタンを追加して selectedPostForDetail に代入
```swift
            List(viewModel.posts) { post in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title).font(.headline)
                    Text(post.bodyText).lineLimit(2).foregroundStyle(.secondary)
                    HStack {
                        // いいねボタン...
                        Spacer()
                        Button("全画面で見る") {
                            selectedPostForDetail = post   // ← これで fullScreenCover が開く
                        }
                        .font(.caption).foregroundStyle(.blue)
                    }
                }
            }
```
▶ ここで確認: Sheet（新規投稿）と FullScreenCover（詳細）の違いを見比べること

---

## Step 5 — Sheet vs FullScreenCover の違いを確認する

| | Sheet | FullScreenCover |
|---|---|---|
| 背景 | 後ろが少し見える（暗くなる） | 完全に覆う |
| dismiss ジェスチャー | 下にスワイプで閉じられる | デフォルトは閉じられない |
| 用途 | 追加情報・フォーム | 没入体験・カメラ・ビデオ |

どちらも `@Environment(\.dismiss)` で閉じる動作は同じ。

---

## 完成チェックリスト
- [ ] +ボタンで Sheet が下からスライドアップする
- [ ] presentationDetents で中間サイズで止まる
- [ ] @Binding で CharacterCountView が bodyText の文字数をリアルタイム表示する
- [ ] 「全画面で見る」で FullScreenCover が全画面表示される
- [ ] どちらも dismiss() で閉じられる
- [ ] Sheet と FullScreenCover の見た目の違いを確認した

---

## 改良ノート（写経後の修正）
- **stale-snapshotバグ修正**: `PostDetailFullScreen` が値コピーの `post` を保持していた問題を、VMから都度取得する `currentPost` 方式に修正（05_TabSNS と同方式）。
- 文字数上限（200字）が `CharacterCountView` の警告表示のみで投稿可否に反映されていなかったため、`isFormValid` に上限チェックを追加。
- 削除処理を配列インデックスベースからidベースに変更し、ズレに強くした。
- `FeedPostCard` を独立ファイルへ、`CharacterCountView` を `Views/Components/` へ分離。
