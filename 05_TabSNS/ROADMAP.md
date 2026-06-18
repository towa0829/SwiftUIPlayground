# 05 TabSNS ロードマップ

完成形: 4タブのSNSアプリ（ホーム・探索・通知・プロフィール）

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Post.swift` と `Models/SNSUser.swift` を新規作成

### 1-1: Post struct
```swift
import Foundation

struct Post: Identifiable {
    let id: UUID
    let authorName: String
    let authorHandle: String
    let authorAvatarIcon: String
    let content: String
    let timestamp: Date
    var likesCount: Int
    var isLiked: Bool
    var commentsCount: Int
    let imageName: String?

    init(
        id: UUID = UUID(),
        authorName: String,
        authorHandle: String,
        authorAvatarIcon: String = "person.circle.fill",
        content: String,
        timestamp: Date = Date(),
        likesCount: Int = 0,
        isLiked: Bool = false,
        commentsCount: Int = 0,
        imageName: String? = nil
    ) {
        self.id = id
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorAvatarIcon = authorAvatarIcon
        self.content = content
        self.timestamp = timestamp
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.commentsCount = commentsCount
        self.imageName = imageName
    }
}
```
▶ 理解: `authorAvatarIcon`（ユーザーごとのアイコン）、`commentsCount`（コメント数）、`imageName`（将来の画像投稿用、今回は常に `nil`）を持たせておくことで、後続のViewが手を加えずに済む

### 1-2: サンプルデータ（4件）
```swift
extension Post {
    static let samples: [Post] = [
        Post(
            authorName: "Towa Yamamoto",
            authorHandle: "@towa_dev",
            authorAvatarIcon: "person.crop.circle.fill",
            content: "SwiftUIのTabViewを学習中！NavigationStackとの組み合わせが面白い 🍎",
            timestamp: Date().addingTimeInterval(-3600),
            likesCount: 42,
            commentsCount: 7
        ),
        Post(
            authorName: "Hana Tanaka",
            authorHandle: "@hana_design",
            authorAvatarIcon: "person.crop.circle.fill.badge.checkmark",
            content: "UIデザインとコードの橋渡しが楽しくなってきた。SwiftUIのPreviewが最高 ✨",
            timestamp: Date().addingTimeInterval(-7200),
            likesCount: 128,
            commentsCount: 23
        ),
        Post(
            authorName: "Kenji Suzuki",
            authorHandle: "@kenji_backend",
            authorAvatarIcon: "person.crop.circle.badge.fill",
            content: "Swift Concurrencyとasync/awaitで非同期処理がスッキリした。おすすめ！",
            timestamp: Date().addingTimeInterval(-14400),
            likesCount: 89,
            commentsCount: 12
        ),
        Post(
            authorName: "Yuki Kobayashi",
            authorHandle: "@yuki_ios",
            authorAvatarIcon: "person.circle.fill",
            content: "Core Dataより SwiftData の方が直感的だと感じる今日この頃。みんなはどう？",
            timestamp: Date().addingTimeInterval(-86400),
            likesCount: 201,
            commentsCount: 45
        ),
    ]
}
```

### 1-3: SNSUser struct + サンプルデータ
```swift
import Foundation

struct SNSUser: Identifiable {
    let id: UUID
    var name: String
    var handle: String
    var bio: String
    var avatarIcon: String
    var postsCount: Int
    var followersCount: Int
    var followingCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        handle: String,
        bio: String = "",
        avatarIcon: String = "person.circle.fill",
        postsCount: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.bio = bio
        self.avatarIcon = avatarIcon
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
    }
}

extension SNSUser {
    static let currentUser = SNSUser(
        name: "Towa Yamamoto",
        handle: "@towa_dev",
        bio: "iOSエンジニア / SwiftUI学習中 🍎",
        avatarIcon: "person.crop.circle.fill",
        postsCount: 42,
        followersCount: 312,
        followingCount: 87
    )

    static let suggestions: [SNSUser] = [
        SNSUser(name: "Hana Tanaka", handle: "@hana_design", bio: "UIデザイナー", avatarIcon: "person.crop.circle.fill.badge.checkmark", followersCount: 1200),
        SNSUser(name: "Kenji Suzuki", handle: "@kenji_backend", bio: "Swift Server-Side", avatarIcon: "person.crop.circle.badge.fill", followersCount: 890),
        SNSUser(name: "Yuki Kobayashi", handle: "@yuki_ios", bio: "iOS Dev", avatarIcon: "person.circle.fill", followersCount: 2100),
    ]
}
```
▶ ここで確認: `Post.samples.count == 4`、`SNSUser.currentUser.name == "Towa Yamamoto"` をPreviewやコード上で確認

---

## Step 2 — HomeViewModel を作る
**ファイル:** `ViewModels/HomeViewModel.swift` を新規作成

### 2-1: 投稿のいいね・追加・時刻表示（最小形）
```swift
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = Post.samples

    func toggleLike(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPost = Post(authorName: "自分", authorHandle: "@me", content: trimmed)
        posts.insert(newPost, at: 0)
    }

    func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "たった今" }
        if seconds < 3600 { return "\(seconds / 60)分前" }
        if seconds < 86400 { return "\(seconds / 3600)時間前" }
        return "\(seconds / 86400)日前"
    }
}
```
▶ ここで確認: ビルドエラーがないこと

### 2-2: タブ間で共有する状態を追加する（currentUser・通知・フォロー状態）
4タブ構成にすると、プロフィールタブも探索タブも「同じユーザー情報」「同じフォロー状態」を参照したくなる。`HomeViewModel`を1つだけ作り、`MainTabView`から各タブへ配ることで状態を一元管理する。

```swift
/// ホームタブだけでなく、探索・通知・プロフィールタブが参照する状態も一元管理するViewModel。
/// タブ間で同じデータ（投稿・ユーザー・通知・フォロー状態）を共有するために、各タブへこのインスタンスを渡す。
class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = Post.samples
    @Published var currentUser: SNSUser = SNSUser.currentUser
    @Published var notifications: [String] = [
        "Hana Tanaka があなたの投稿にいいねしました",
        "Kenji Suzuki があなたをフォローしました",
        "Yuki Kobayashi があなたの投稿にコメントしました",
    ]
    @Published private var followingStatus: [UUID: Bool] = [:]

    func toggleLike(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPost = Post(
            authorName: currentUser.name,
            authorHandle: currentUser.handle,
            authorAvatarIcon: currentUser.avatarIcon,
            content: trimmed,
            likesCount: 0
        )
        posts.insert(newPost, at: 0)
        currentUser.postsCount += 1
    }

    func isFollowing(_ user: SNSUser) -> Bool {
        followingStatus[user.id, default: false]
    }

    func toggleFollow(_ user: SNSUser) {
        followingStatus[user.id, default: false].toggle()
    }

    func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "たった今" }
        if seconds < 3600 { return "\(seconds / 60)分前" }
        if seconds < 86400 { return "\(seconds / 3600)時間前" }
        return "\(seconds / 86400)日前"
    }
}
```
▶ 理解: `addPost`が自分のhandle/avatarIconを使い、`currentUser.postsCount`まで更新するようにしたことで、プロフィールタブの投稿数表示が自動的に連動する。`followingStatus`はView側に持たせず、ユーザーIDをキーにしたDictionaryでVMに集約 → MVVMを保ったままどのタブからでもフォロー操作ができる

▶ ここで確認: ビルドエラーがないこと

---

## Step 3 — HomeView（フィード）を作る
**ファイル:** `Views/HomeView.swift`、`Views/PostRowView.swift`、`Views/PostDetailView.swift` を新規作成

### 3-1: PostRowView（投稿行UI）
```swift
import SwiftUI

struct PostRowView: View {
    let post: Post
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: post.authorAvatarIcon)
                .font(.title)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.authorName).font(.subheadline.bold())
                    Text(post.authorHandle).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.timeAgo(post.timestamp)).font(.footnote).foregroundStyle(.secondary)
                }

                Text(post.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 24) {
                    Button {
                        viewModel.toggleLike(post)
                    } label: {
                        Label("\(post.likesCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLiked ? .red : .secondary)
                    }
                    .buttonStyle(.plain)

                    Label("\(post.commentsCount)", systemImage: "bubble.left")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    List {
        PostRowView(post: Post.samples[0], viewModel: HomeViewModel())
        PostRowView(post: Post.samples[1], viewModel: HomeViewModel())
    }
    .listStyle(.plain)
}
```
▶ 理解: アイコンは固定の`"person.circle.fill"`ではなく`post.authorAvatarIcon`を使うことで、投稿者ごとに異なるアバターを表示できる。コメント数も`Label`で並べておく

### 3-2: PostDetailView（投稿詳細・stale-snapshot対策）
投稿をタップしたら詳細画面に遷移させたい。ここで罠がある。`let post: Post`をそのまま保持すると**値型のコピー**になるため、一覧でいいねした後に詳細を開いても古い数値のまま表示されてしまう（stale-snapshot問題）。対策として、VMの配列からidで都度取得する`currentPost`という計算プロパティを使う。

```swift
import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: HomeViewModel

    /// VMの最新状態を都度取得する。`post`をそのまま使うと値コピーのため
    /// いいね操作後もこの画面に反映されない（stale-snapshot）問題が起きる。
    private var currentPost: Post {
        viewModel.posts.first(where: { $0.id == post.id }) ?? post
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: currentPost.authorAvatarIcon)
                        .font(.title)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentPost.authorName).font(.headline)
                        Text(currentPost.authorHandle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                Text(currentPost.content)
                    .font(.body)

                Text(currentPost.timestamp.formatted(date: .long, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 24) {
                    Button {
                        viewModel.toggleLike(currentPost)
                    } label: {
                        Label("\(currentPost.likesCount) いいね", systemImage: currentPost.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(currentPost.isLiked ? .red : .secondary)
                    }
                    Label("\(currentPost.commentsCount) コメント", systemImage: "bubble.left")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post.samples[0], viewModel: HomeViewModel())
    }
}
```
▶ 理解: `currentPost`方式は07_HabitTrackerの`currentHabit`と同じパターン。`let post`は初期値・Preview用に保持しつつ、表示は常に`currentPost`経由にすることでVMの更新が即座に反映される

### 3-3: HomeView（List + NavigationLink + 新規投稿シート）
```swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showNewPost = false

    var body: some View {
        List(viewModel.posts) { post in
            NavigationLink(destination: PostDetailView(post: post, viewModel: viewModel)) {
                PostRowView(post: post, viewModel: viewModel)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("ホーム")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewPost = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewPost) {
            NewPostView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
```
▶ ここで確認: Preview でフィードが表示されること。行をタップすると`PostDetailView`に遷移すること。いいねで数が増え、詳細画面にも即反映されること

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

### 4-3: 残り2タブ + バッジを追加（仮実装）
```swift
            NavigationStack {
                Text("通知")
                    .navigationTitle("通知")
            }
            .tabItem { Label("通知", systemImage: "bell.fill") }
            .badge(3)   // ← 仮のバッジ数（Step 6でデータ駆動に直す）

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

    enum Tab: String {
        case home, explore, notifications, profile
    }

    TabView(selection: $selectedTab) {
        NavigationStack { HomeView(viewModel: homeViewModel) }
            .tabItem { Label("ホーム", systemImage: "house.fill") }
            .tag(Tab.home)   // ← selection と一致するタグ
        // ...
    }
```
▶ 理解: `selectedTab`を`@State`で持つことで、コード側から`selectedTab = .profile`のようにタブを切り替えられるようになる

---

## Step 5 — ProfileTabView を作る
**ファイル:** `Views/ProfileTabView.swift`、`Views/Components/ProfileStatView.swift`、`Views/Components/SuggestionRow.swift` を新規作成

### 5-1: ProfileStatView（統計1項目分のコンポーネント）
数値とラベルを縦に並べる部分は「投稿」「フォロワー」「フォロー中」の3箇所で繰り返すので、先に小さなコンポーネントへ分離する。

```swift
import SwiftUI

/// プロフィール統計（投稿/フォロワー/フォロー中）の value/title 表示
struct ProfileStatView: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 32) {
        ProfileStatView(value: "42", title: "投稿")
        ProfileStatView(value: "312", title: "フォロワー")
    }
}
```

### 5-2: SuggestionRow（おすすめユーザー行・フォローボタン付き）
探索タブとプロフィールタブの両方で「おすすめユーザー」を表示するため、共通コンポーネントとして切り出す。フォロー状態はView内に持たず、`HomeViewModel`の`isFollowing`/`toggleFollow`に委ねることでMVVMを保つ。

```swift
import SwiftUI

/// おすすめユーザー行。探索タブとプロフィールタブの両方で使う共通コンポーネント。
/// フォロー状態はView内に持たず、HomeViewModelに集約してMVVMを保つ。
struct SuggestionRow: View {
    let user: SNSUser
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: user.avatarIcon)
                .font(.title2)
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name).font(.subheadline.bold())
                Text(user.handle).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button(viewModel.isFollowing(user) ? "フォロー中" : "フォロー") {
                viewModel.toggleFollow(user)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(viewModel.isFollowing(user) ? Color(.secondarySystemBackground) : .blue)
            .foregroundStyle(viewModel.isFollowing(user) ? .primary : .white)
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SuggestionRow(user: SNSUser.suggestions[0], viewModel: HomeViewModel())
        .padding(.horizontal)
}
```
▶ 理解: ボタンの見た目（背景色・文字色）を`viewModel.isFollowing(user)`の真偽だけで切り替えている。Viewにロジックを書かず、判定はすべてViewModelに問い合わせる

### 5-3: ProfileTabView（ViewModel経由でcurrentUserとおすすめユーザーを表示）
```swift
import SwiftUI

struct ProfileTabView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // アバター
                Image(systemName: viewModel.currentUser.avatarIcon)
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)
                    .padding(.top)

                VStack(spacing: 4) {
                    Text(viewModel.currentUser.name).font(.title2.bold())
                    Text(viewModel.currentUser.handle).font(.subheadline).foregroundStyle(.secondary)
                    Text(viewModel.currentUser.bio).font(.body).multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal)

                // 統計（投稿数は新規投稿のたびに更新される）
                HStack(spacing: 40) {
                    ProfileStatView(value: "\(viewModel.currentUser.postsCount)", title: "投稿")
                    ProfileStatView(value: "\(viewModel.currentUser.followersCount)", title: "フォロワー")
                    ProfileStatView(value: "\(viewModel.currentUser.followingCount)", title: "フォロー中")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // フォロワーサジェスチョン
                VStack(alignment: .leading, spacing: 12) {
                    Text("おすすめユーザー")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(SNSUser.suggestions) { suggestion in
                        SuggestionRow(user: suggestion, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("プロフィール")
    }
}

#Preview {
    NavigationStack {
        ProfileTabView(viewModel: HomeViewModel())
    }
}
```
▶ 理解: `let user = SNSUser.currentUser`のような固定値ではなく`@ObservedObject var viewModel: HomeViewModel`を受け取り、`viewModel.currentUser`を読むことで、ホームタブで新規投稿した直後に投稿数がここにも反映される

### 5-4: MainTabView に実際のViewを接続する
```swift
            NavigationStack { ProfileTabView(viewModel: homeViewModel) }
                .tabItem { Label("プロフィール", systemImage: "person.fill") }
                .tag(Tab.profile)
```
▶ ここで確認: プロフィールタブにアバター・統計・おすすめユーザーが表示され、フォローボタンを押すと「フォロー中」に切り替わること

---

## Step 6 — ExploreView・NotificationsView を実装する
**ファイル:** `Views/ExploreView.swift`、`Views/NotificationsView.swift` を新規作成し、Step 4で仮置きした `Text("探索")` / `Text("通知")` を置き換える

### 6-1: ExploreView（トレンドトピック + おすすめユーザー）
```swift
import SwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: HomeViewModel
    let trendingTopics = ["#SwiftUI", "#iOS開発", "#Swift", "#Xcode", "#WWDC", "#CoreData", "#SwiftData", "#UIKit"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("トレンドトピック")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(trendingTopics, id: \.self) { topic in
                        Text(topic)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)

                Text("おすすめユーザー")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(SNSUser.suggestions) { user in
                        HStack(spacing: 12) {
                            Image(systemName: user.avatarIcon)
                                .font(.title2)
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name).font(.subheadline.bold())
                                Text(user.bio).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(user.followersCount)人")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("探索")
    }
}

#Preview {
    NavigationStack {
        ExploreView(viewModel: HomeViewModel())
    }
}
```
▶ 理解: `LazyVGrid`で2列のトピックタグを並べる。この画面のおすすめユーザー行はフォローボタンを持たない簡易表示のため、`SuggestionRow`は使わずインラインで組んでいる（ボタン付きが欲しければプロフィールタブと同様に`SuggestionRow`へ差し替え可能）

### 6-2: NotificationsView（通知一覧・データ駆動）
```swift
import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        List(viewModel.notifications, id: \.self) { notification in
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(notification)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("通知")
    }
}

#Preview {
    NavigationStack {
        NotificationsView(viewModel: HomeViewModel())
    }
}
```
▶ 理解: 文字列をハードコードした`Text("通知")`から、`viewModel.notifications`をそのまま`List`に流す形に変える。これで通知の追加・削除がVMの配列を変えるだけで画面に反映される

### 6-3: MainTabView に接続し、バッジをデータ駆動にする
```swift
            NavigationStack {
                ExploreView(viewModel: homeViewModel)
            }
            .tabItem {
                Label("探索", systemImage: "magnifyingglass")
            }
            .tag(Tab.explore)

            NavigationStack {
                NotificationsView(viewModel: homeViewModel)
            }
            .tabItem {
                Label("通知", systemImage: "bell.fill")
            }
            .badge(homeViewModel.notifications.count)  // 通知件数と連動したバッジ
            .tag(Tab.notifications)
```
▶ ここで確認: 探索タブにトピックグリッドとおすすめユーザーが表示されること。通知タブに3件の通知が表示され、バッジの数字が`notifications.count`と一致すること（ハードコードの`.badge(3)`を置き換える）

---

## Step 7 — 新規投稿シートを実装する
**ファイル:** `Views/NewPostView.swift` を新規作成

```swift
import SwiftUI

struct NewPostView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""

    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .padding()
                .navigationTitle("新規投稿")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("キャンセル") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("投稿") {
                            viewModel.addPost(content: content)
                            dismiss()
                        }
                        .bold()
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}

#Preview {
    NewPostView(viewModel: HomeViewModel())
}
```
▶ ここで確認: ホームタブの右上ボタンでシートが開き、空文字では投稿ボタンが無効化されること。投稿するとフィードの先頭に追加され、プロフィールタブの投稿数も増えること

---

## 完成チェックリスト
- [ ] 4タブ（ホーム・探索・通知・プロフィール）のタブバーが表示される
- [ ] 各タブが独立した NavigationStack を持っている
- [ ] selectedTab でプログラマティックな切り替えの仕組みを理解した
- [ ] ホームでいいねができ、投稿詳細画面にも即座に反映される（stale-snapshot対策済み）
- [ ] 投稿行をタップすると PostDetailView に遷移する
- [ ] 通知タブのバッジが notifications.count と連動している
- [ ] 探索タブにトレンドトピックとおすすめユーザーが表示される
- [ ] プロフィールタブで currentUser の情報とおすすめユーザーが表示され、フォロー/フォロー中の切り替えができる
- [ ] 新規投稿でフィードの先頭に追加され、プロフィールの投稿数も更新される
- [ ] HomeViewModel が posts・currentUser・notifications・フォロー状態をタブ間で一元管理していることを理解した

---

## 補足: ファイル構成
学習の過程で1つのファイルに複数structを書いていたものを、最終的に以下のように分割している。
- `HomeView.swift` に同居していた4つのstructを `PostRowView.swift` / `NewPostView.swift` / `PostDetailView.swift` へ分割
- `ExploreView.swift` から `NotificationsView` を分離
- `Views/Components/` に `ProfileStatView.swift` / `SuggestionRow.swift` を抽出（複数画面で再利用するため）
