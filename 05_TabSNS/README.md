# 05 TabSNS

## 学習テーマ
- `TabView` — 複数画面をタブで切り替え
- `NavigationStack` — 各タブ独立した画面遷移スタック

## 完成イメージ
- ホーム / 探索 / 通知 / プロフィール の4タブ
- ホームにSNSフィード（いいね機能付き）
- 新規投稿シート
- 通知タブにバッジ表示

## ファイル構成
```
05_TabSNS/
├── Models/
│   ├── Post.swift             # 投稿データモデル
│   └── SNSUser.swift          # ユーザーデータモデル
├── ViewModels/
│   └── HomeViewModel.swift    # フィードのロジック
└── Views/
    ├── MainTabView.swift      # TabView（エントリーポイント）
    ├── HomeView.swift         # ホームフィード一覧
    ├── PostRowView.swift      # フィードの投稿行
    ├── NewPostView.swift      # 新規投稿シート
    ├── PostDetailView.swift   # 投稿詳細（currentPostで都度参照）
    ├── ExploreView.swift      # 探索タブ
    ├── NotificationsView.swift # 通知タブ
    ├── ProfileTabView.swift   # プロフィールタブ
    └── Components/
        ├── ProfileStatView.swift # 統計表示
        └── SuggestionRow.swift   # おすすめユーザー行
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `MainTabView()` に変更

## 学習ポイント

### TabView
```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tabItem {
            Label("ホーム", systemImage: "house.fill")
        }
        .badge(3)   // バッジ数
        .tag(Tab.home)  // 選択を識別するタグ
}
```

### 各タブに独立した NavigationStack
```swift
TabView {
    // ✅ 各タブが独立したナビゲーションスタックを持つ
    NavigationStack {
        HomeView()
    }
    .tabItem { ... }

    NavigationStack {
        ProfileView()
    }
    .tabItem { ... }
}
```
TabViewの外に1つのNavigationStackを置くと、全タブで共有されてしまうので注意。

### タブ選択の管理
```swift
enum Tab { case home, explore, profile }

@State private var selectedTab: Tab = .home

TabView(selection: $selectedTab) {
    View1().tag(Tab.home)
    View2().tag(Tab.explore)
}
```
`selection` と `.tag()` でプログラマティックにタブを切り替えられる。

## 発展課題
- タブバーのカスタム外観（`.toolbar(.hidden, for: .tabBar)`）
- ディープリンクでタブ切り替え（`@SceneStorage`）
- 各タブのスクロール位置を保持
