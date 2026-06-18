import SwiftUI

struct MainTabView: View {
    // タブの選択状態を管理する
    @State private var selectedTab: Tab = .home
    @StateObject private var homeViewModel = HomeViewModel()

    enum Tab: String {
        case home, explore, notifications, profile
    }

    var body: some View {
        // TabView: 画面下部にタブバーを表示し、複数の画面を切り替える
        TabView(selection: $selectedTab) {
            // 各タブはNavigationStackを持つ（独立した画面遷移スタック）
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(Tab.home)

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

            NavigationStack {
                ProfileTabView(viewModel: homeViewModel)
            }
            .tabItem {
                Label("プロフィール", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
    }
}

#Preview {
    MainTabView()
}
