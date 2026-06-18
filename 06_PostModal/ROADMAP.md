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
    var body: String
    var authorName: String
    var authorIcon: String
    var createdAt: Date
    var likesCount: Int
    var isLiked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        authorName: String,
        authorIcon: String = "person.circle.fill",
        createdAt: Date = Date(),
        likesCount: Int = 0,
        isLiked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.authorName = authorName
        self.authorIcon = authorIcon
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.isLiked = isLiked
    }
}
```
▶ 理解: `body` は SwiftUI の `View.body` と名前が衝突しそうに見えるが、`FeedPost` は別の型のプロパティなので問題なく使える。`authorIcon` はSF Symbols名を保持し、カードや詳細画面でアイコンとして表示する。

### 1-2: サンプルデータを追加
```swift
extension FeedPost {
    static let samples: [FeedPost] = [
        FeedPost(
            title: "SwiftUIのシート活用術",
            body: "`.sheet`と`.fullScreenCover`を使い分けることで、UXが大幅に向上します。シートはモーダルダイアログ的な用途に、フルスクリーンカバーは没入体験に最適です。",
            authorName: "Towa",
            authorIcon: "person.crop.circle.fill",
            createdAt: Date().addingTimeInterval(-3600),
            likesCount: 34
        ),
        FeedPost(
            title: "@Bindingで親子データを繋ぐ",
            body: "子Viewから親のデータを変更するには`@Binding`を使います。`$`プレフィックスでBindingを渡すのがポイント。",
            authorName: "Hana",
            authorIcon: "person.crop.circle.fill.badge.checkmark",
            createdAt: Date().addingTimeInterval(-7200),
            likesCount: 56
        ),
        FeedPost(
            title: "FullScreenCoverとSheet",
            body: "どちらも`isPresented: $bool`で表示を制御します。`@Environment(\\.dismiss)`でViewの中から閉じることができます。",
            authorName: "Kenji",
            authorIcon: "person.crop.circle.badge.fill",
            createdAt: Date().addingTimeInterval(-14400),
            likesCount: 89
        ),
    ]
}
```
▶ ここで確認: ビルドエラーがないこと。`createdAt`を`addingTimeInterval`でずらしておくと、後で投稿日時順の表示を確認しやすい。

### 1-3: FeedViewModel（いいね・追加・削除）
```swift
import Foundation
import Combine
import SwiftUI

class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = FeedPost.samples

    func toggleLike(_ post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedBody.isEmpty else { return }
        let post = FeedPost(
            title: trimmedTitle,
            body: trimmedBody,
            authorName: "自分",
            authorIcon: "person.crop.circle.fill"
        )
        posts.insert(post, at: 0)
    }

    func deletePost(_ post: FeedPost) {
        posts.removeAll { $0.id == post.id }
    }

    /// IndexSetをまとめて削除する。配列をforEachで個別削除すると
    /// 削除のたびにindexがずれて誤った要素を消す恐れがあるため remove(atOffsets:) を使う。
    func deletePosts(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
    }
}
```
▶ 理解: `addPost`は空白だけのタイトル・本文を弾く（trimして空ならno-op）。`deletePosts(at:)`は`List`の`.onDelete`からそのまま渡せる形（`(IndexSet) -> Void`）にしてあるので、Step 2で配線するだけで済む。
▶ ここで確認: ビルドエラーがないこと

---

## Step 2 — フィードカードを Component として作る
**ファイル:** `Views/FeedPostCard.swift` を新規作成

カードの見た目（著者・タイトル・本文・いいね・詳細ボタン）は`FeedView`に直接書かず、再利用可能なComponentに分離する。

### 2-1: FeedPostCard の骨格
```swift
import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    let onTapDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: post.authorIcon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName).font(.subheadline.bold())
                    Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Text(post.title).font(.headline)
            Text(post.body).font(.body).lineLimit(3).foregroundStyle(.secondary)

            HStack {
                Button {
                    viewModel.toggleLike(post)
                } label: {
                    Label("\(post.likesCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(post.isLiked ? .red : .secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)

                Spacer()

                // FullScreenCoverを開くボタン
                Button("全画面で見る") {
                    onTapDetail()
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    List {
        FeedPostCard(post: FeedPost.samples[0], viewModel: FeedViewModel()) {}
    }
    .listStyle(.plain)
}
```
▶ 理解: `onTapDetail: () -> Void`というクロージャをプロパティとして持たせることで、「全画面を開く」という親側の責務をComponent側に持たせずに済む。`FeedPostCard`自身は表示と`toggleLike`の呼び出しだけを担当する。
▶ ここで確認: Preview でカードが1件表示されること

---

## Step 3 — フィード一覧と Sheet の基本形
**ファイル:** `Views/FeedView.swift` を新規作成

### 3-1: FeedView の骨格（まずシートなし）
```swift
import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, viewModel: viewModel) {
                        // 詳細画面を開く処理は後のStepで追加
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: viewModel.deletePosts)
            }
            .listStyle(.plain)
            .navigationTitle("フィード")
        }
    }
}

#Preview {
    FeedView()
}
```
▶ 理解: `List(viewModel.posts) { ... }`ではなく`List { ForEach(...) { ... }.onDelete(...) }`という形にしているのは、`.onDelete`を使うには`ForEach`が必要なため。`listRowInsets`/`listRowSeparator(.hidden)`/`listRowBackground(.clear)`はカードの周りの余白・区切り線・行背景をリセットして、カード自体の見た目（角丸・背景色）をそのまま活かすためのモディファイア。`listStyle(.plain)`もデフォルトの`InsetGroupedListStyle`の余白を消すために必要。
▶ ここで確認: Preview でカードがリスト表示され、左スワイプで削除できること

### 3-2: Sheet のトリガーを追加する
```swift
    // Sheet と FullScreenCover の表示状態をそれぞれ管理
    @State private var showNewPostSheet = false
    @State private var selectedPostForDetail: FeedPost? = nil

    // .navigationTitle の後に追加
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showNewPostSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
    }
    // sheet: 下からスライドアップするモーダル
    .sheet(isPresented: $showNewPostSheet) {
        Text("新規投稿フォーム（仮）")
    }
```
▶ ここで確認: +ボタンで下からシートがスライドアップすること

---

## Step 4 — NewPostSheet（@Binding の練習）
**ファイル:** `Views/Components/CharacterCountView.swift`、`Views/NewPostSheet.swift` を新規作成

### 4-1: CharacterCountView を Component として切り出す
文字数カウンターは`NewPostSheet`専用ではなく再利用可能なComponentとして`Views/Components/`に独立させる。

```swift
import SwiftUI

// @Binding の学習用: 親からテキストのBindingを受け取って文字数カウント
struct CharacterCountView: View {
    @Binding var text: String  // 親Viewのstateへの参照
    let limit: Int

    var count: Int { text.count }
    var isOverLimit: Bool { count > limit }

    var body: some View {
        HStack {
            Text("文字数")
            Spacer()
            Text("\(count) / \(limit)")
                .foregroundStyle(isOverLimit ? .red : .secondary)
                .fontWeight(isOverLimit ? .bold : .regular)
        }
        .font(.subheadline)
    }
}

#Preview {
    CharacterCountView(text: .constant("サンプルテキスト"), limit: 200)
}
```
▶ 理解: `@Binding var text`は`@State var text`の「コピー」ではなく「参照」。呼び出し側が`$bodyText`のように`$`を付けて渡すことで、`CharacterCountView`の中で`text`を読むだけで親の最新の状態がそのまま見える。

### 4-2: 入力フォームの骨格
```swift
import SwiftUI

struct NewPostSheet: View {
    // @Binding ではなく @ObservedObject でViewModelを受け取る
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var bodyText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("投稿のタイトル", text: $title)
                }

                Section("本文") {
                    // TextEditor: 複数行テキスト入力
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        // @Environment(\.dismiss) でシートを閉じる
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("投稿する") {
                        viewModel.addPost(title: title, body: bodyText)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewPostSheet(viewModel: FeedViewModel())
}
```
▶ ここで確認: 「キャンセル」と「投稿する」で dismiss() が呼ばれること

### 4-3: CharacterCountView を組み込み、文字数上限を投稿可否に反映する
```swift
    private let bodyLimit = 200

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespaces).isEmpty &&
        bodyText.count <= bodyLimit
    }

    // Form の本文Sectionの後に追加
                Section {
                    // @Binding の使い方サンプル
                    CharacterCountView(text: $bodyText, limit: bodyLimit)
                }

    // 「投稿する」ボタンの .disabled を差し替え
                    .disabled(!isFormValid)
```
▶ 理解: `CharacterCountView`は文字数を赤字で警告表示するだけで、投稿そのものをブロックする力はない。実際に上限を超えた投稿を防ぐには、`isFormValid`の条件に`bodyText.count <= bodyLimit`を含めて「投稿する」ボタンの`disabled`に反映させる必要がある。表示用のロジックと制約用のロジックは別物として扱う、という気づきがここのポイント。

### 4-4: presentationDetents でシートの高さを制御
```swift
    // NavigationStack の後に追加
        // presentationDetents: シートの高さを制御
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
```
▶ ここで確認: シートが途中の高さで止まり、上にドラッグで全画面になること

### 4-5: FeedView の sheet を実際の NewPostSheet に差し替える
```swift
    .sheet(isPresented: $showNewPostSheet) {
        NewPostSheet(viewModel: viewModel)   // Text("仮") → 本物に
    }
```
▶ ここで確認: 投稿後にフィードの先頭に追加されること。空文字や200字超の本文では投稿できないこと

---

## Step 5 — FullScreenCover で詳細画面を作る
**ファイル:** `Views/PostDetailFullScreen.swift` を新規作成、その後 `FeedView.swift` を編集

### 5-1: PostDetailFullScreen の骨格（stale-snapshotを避ける currentPost パターン）
```swift
import SwiftUI

struct PostDetailFullScreen: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    /// VMの最新状態を都度取得する。`post`をそのまま使うと値コピーのため
    /// いいね操作後もこの画面に反映されない（stale-snapshot）問題が起きる。
    private var currentPost: FeedPost {
        viewModel.posts.first(where: { $0.id == post.id }) ?? post
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 著者
                    HStack(spacing: 12) {
                        Image(systemName: currentPost.authorIcon)
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentPost.authorName)
                                .font(.title3.bold())
                            Text(currentPost.createdAt.formatted(date: .long, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // タイトル
                    Text(currentPost.title)
                        .font(.title.bold())

                    // 本文（全文表示）
                    Text(currentPost.body)
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding()
            }
            .navigationTitle("投稿詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // fullScreenCoverでも @Environment(\.dismiss) で閉じられる
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

#Preview {
    PostDetailFullScreen(post: FeedPost.samples[0], viewModel: FeedViewModel())
}
```
▶ 理解: もし`let post: FeedPost`をそのまま画面内で使うと、これは渡された瞬間の値のコピー（struct）。一覧側で`toggleLike`していいねの状態が変わっても、すでに開いている詳細画面の`post`は古いまま（stale snapshot）になってしまう。`currentPost`という計算プロパティで毎回`viewModel.posts`から最新の値を引き直すことで、この画面でも一覧と同じ最新状態を表示できる。

### 5-2: いいねボタンを詳細画面にも追加する
```swift
                    Divider()

                    // いいね
                    HStack {
                        Button {
                            viewModel.toggleLike(currentPost)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: currentPost.isLiked ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundStyle(currentPost.isLiked ? .red : .secondary)
                                Text("\(currentPost.likesCount) いいね")
                                    .font(.headline)
                                    .foregroundStyle(currentPost.isLiked ? .red : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer()
                    }
```
▶ ここで確認: 詳細画面でいいねを押すと即座に反映され、一覧画面に戻った後もカードのいいね数が一致していること

### 5-3: FeedView に `item: Binding` 形式の fullScreenCover を追加
```swift
    // .sheet の後に追加
    .fullScreenCover(item: $selectedPostForDetail) { post in
        PostDetailFullScreen(post: post, viewModel: viewModel)
    }
```
▶ 理解: `isPresented: Bool` と `item: Optional` の2パターンがある。
`item` を使う場合は対象が `Identifiable` である必要がある。

### 5-4: FeedPostCard の onTapDetail で selectedPostForDetail に代入する
```swift
                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, viewModel: viewModel) {
                        selectedPostForDetail = post   // ← これで fullScreenCover が開く
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
```
▶ ここで確認: Sheet（新規投稿）と FullScreenCover（詳細）の違いを見比べること

---

## Step 6 — Sheet vs FullScreenCover の違いを確認する

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
- [ ] 200字を超える本文では「投稿する」がdisabledになる
- [ ] 左スワイプで投稿をリストから削除できる
- [ ] 「全画面で見る」で FullScreenCover が全画面表示される
- [ ] 詳細画面でいいねを押すと一覧側にも反映される（stale-snapshotが起きない）
- [ ] どちらも dismiss() で閉じられる
- [ ] Sheet と FullScreenCover の見た目の違いを確認した

---

## まとめ
このロードマップでは、フィード一覧（List + ForEach + onDelete）、Componentへの分離（FeedPostCard / CharacterCountView）、フォーム入力の検証（trimとisFormValid）、そして`@Binding`と`item: Binding`を使った2種類のモーダル提示を一通り体験した。中でも重要なのは、`PostDetailFullScreen`の`currentPost`パターン——値型のstructを画面間で受け渡すときは「渡された瞬間のコピー」になることを意識し、最新状態を見たい場合はViewModelから都度取得する、という設計判断である。
