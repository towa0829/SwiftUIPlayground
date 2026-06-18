# 05 TabSNS ロードマップ

完成形: 4タブのSNSアプリ（ホーム・探索・通知・プロフィール）

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Post.swift` と `Models/SNSUser.swift` を新規作成

### 1-1: Post struct（最小形）
```swift
import Foundation

struct Post: Identifiable {
    let id: UUID
    let authorName: String
    let authorHandle: String
    let content: String
    let timestamp: Date
    var likesCount: Int
    var isLiked: Bool

    init(id: UUID = UUID(), authorName: String, authorHandle: String,
         content: String, timestamp: Date = Date(),
         likesCount: Int = 0, isLiked: Bool = false) {
        self.id = id; self.authorName = authorName; self.authorHandle = authorHandle
        self.content = content; self.timestamp = timestamp
        self.likesCount = likesCount; self.isLiked = isLiked
    }
}
```

### 1-2: サンプルデータ + SNSUser
```swift
extension Post {
    static let samples: [Post] = [
        Post(authorName: "Towa", authorHandle: "@towa_dev",
             content: "SwiftUIのTabViewを学習中！",
             timestamp: Date().addingTimeInterval(-3600), likesCount: 42),
        Post(authorName: "Hana", authorHandle: "@hana_design",
             content: "SwiftUIのPreviewが最高 ✨",
             timestamp: Date().addingTimeInterval(-7200), likesCount: 128),
    ]
}
```
`SNSUser.swift` も同様に struct + currentUser / suggestions を作成。

---

## Step 2 — HomeViewModel を作る
**ファイル:** `ViewModels/HomeViewModel.swift` を新規作成

```swift
import Foundation

class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = Post.samples

    func toggleLike(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(content: String) {
        let newPost = Post(authorName: "自分", authorHandle: "@me", content: content)
        posts.insert(newPost, at: 0)
    }

    func timeAgo(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "たった今" }
        if s < 3600 { return "\(s / 60)分前" }
        return "\(s / 3600)時間前"
    }
}
```
▶ ここで確認: ビルドエラーがないこと

---

## Step 3 — HomeView（フィード）を作る
**ファイル:** `Views/HomeView.swift` を新規作成

### 3-1: PostRowView（投稿行UI）
```swift
import SwiftUI

struct PostRowView: View {
    let post: Post
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title).foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.authorName).font(.subheadline.bold())
                    Text(post.authorHandle).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.timeAgo(post.timestamp)).font(.caption).foregroundStyle(.secondary)
                }
                Text(post.content).font(.body)

                // いいねボタン
                Button {
                    viewModel.toggleLike(post)
                } label: {
                    Label("\(post.likesCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(post.isLiked ? .red : .secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }
}
```

### 3-2: HomeView（List + タイトル）
```swift
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        List(viewModel.posts) { post in
            PostRowView(post: post, viewModel: viewModel)
        }
        .listStyle(.plain)
        .navigationTitle("ホーム")
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
```
▶ ここで確認: Preview でフィードが表示されること。いいねで数が増えること

---

## Step 4 — TabView で4タブを作る（メイン）
**ファイル:** `Views/MainTabView.swift` を新規作成

### 4-1: TabView の最小形（2タブから始める）
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("ホーム")
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            Text("プロフィール")
                .tabItem { Label("プロフィール", systemImage: "person.fill") }
        }
    }
}

#Preview { MainTabView() }
```
▶ ここで確認: 画面下にタブバーが表示されること

### 4-2: 各タブに独立した NavigationStack を持たせる
```swift
struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        TabView {
            // ✅ NavigationStack を各タブの中に置く（外に置かない！）
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            .tabItem { Label("ホーム", systemImage: "house.fill") }

            NavigationStack {
                Text("探索")
                    .navigationTitle("探索")
            }
            .tabItem { Label("探索", systemImage: "magnifyingglass") }
        }
    }
}
```
▶ 理解: NavigationStack を TabView の外に1つ置くと全タブ共通になる。各タブ独立にするにはタブの中に置く

### 4-3: 残り2タブ + バッジを追加
```swift
            NavigationStack {
                Text("通知")
                    .navigationTitle("通知")
            }
            .tabItem { Label("通知", systemImage: "bell.fill") }
            .badge(3)   // ← バッジ数

            NavigationStack {
                Text("プロフィール")
                    .navigationTitle("プロフィール")
            }
            .tabItem { Label("プロフィール", systemImage: "person.fill") }
```
▶ ここで確認: 通知タブに「3」のバッジが表示されること

### 4-4: selectedTab でプログラマティックに切り替えられるようにする
```swift
    @State private var selectedTab: Tab = .home

    enum Tab { case home, explore, notifications, profile }

    TabView(selection: $selectedTab) {
        NavigationStack { HomeView(...) }
            .tabItem { ... }
            .tag(Tab.home)   // ← selection と一致するタグ
        // ...
    }
```

---

## Step 5 — 各タブの中身を実装する
**ファイル:** `Views/ProfileTabView.swift` と `Views/ExploreView.swift` を新規作成

### 5-1: ProfileTabView（プロフィール統計）
```swift
import SwiftUI

struct ProfileTabView: View {
    let user = SNSUser.currentUser

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: user.avatarIcon)
                    .font(.system(size: 72)).foregroundStyle(.blue).padding(.top)
                Text(user.name).font(.title2.bold())
                Text(user.handle).foregroundStyle(.secondary)
                Text(user.bio)

                // 統計の横並び
                HStack(spacing: 40) {
                    VStack { Text("\(user.postsCount)").bold(); Text("投稿").font(.caption) }
                    VStack { Text("\(user.followersCount)").bold(); Text("フォロワー").font(.caption) }
                    VStack { Text("\(user.followingCount)").bold(); Text("フォロー").font(.caption) }
                }
            }
        }
        .navigationTitle("プロフィール")
    }
}
```

### 5-2: MainTabView に実際のViewを接続する
```swift
            NavigationStack { ProfileTabView() }
                .tabItem { Label("プロフィール", systemImage: "person.fill") }
                .tag(Tab.profile)
```
▶ ここで確認: 全4タブが動作すること

### 5-3: HomeView に新規投稿シートを追加
```swift
    @State private var showNewPost = false

    // navigationTitle の後に追加
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showNewPost = true } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }
    .sheet(isPresented: $showNewPost) {
        // 簡易的な投稿フォーム
        NewPostView(viewModel: viewModel)
    }
```
▶ ここで確認: ボタンでシートが開き、投稿するとフィードの先頭に追加されること

---

## 完成チェックリスト
- [ ] 4タブのタブバーが表示される
- [ ] 通知タブにバッジが表示される
- [ ] 各タブが独立した NavigationStack を持っている
- [ ] ホームでいいねができる
- [ ] 新規投稿でフィードの先頭に追加される
- [ ] selectedTab でプログラマティックな切り替えの仕組みを理解した

---

## 改良ノート（写経後の修正）
- **stale-snapshotバグ修正**: 投稿詳細画面が `let post` の値コピーを保持していたため、詳細内のいいねがVMの更新を反映しなかった。VMの配列からidで都度取得する `currentPost` 方式に修正（07_HabitTracker の `currentHabit` と同じパターン）。
- 通知バッジのハードコード `.badge(3)` をデータ駆動に変更。
- `HomeView.swift` に同居していた4つのstructを `PostRowView`/`NewPostView`/`PostDetailView` へ分割、`ExploreView.swift` から `NotificationsView` を分離、`Views/Components/` に `ProfileStatView`/`SuggestionRow` を抽出。
