import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    // Sheet と FullScreenCover の表示状態をそれぞれ管理
    @State private var showNewPostSheet = false
    @State private var selectedPostForDetail: FeedPost? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, viewModel: viewModel) {
                        selectedPostForDetail = post
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: viewModel.deletePosts)
            }
            .listStyle(.plain)
            .navigationTitle("フィード")
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
                NewPostSheet(viewModel: viewModel)
            }
            // fullScreenCover: 画面全体を覆うモーダル（Bindingでアイテムを渡す）
            .fullScreenCover(item: $selectedPostForDetail) { post in
                PostDetailFullScreen(post: post, viewModel: viewModel)
            }
        }
    }
}

#Preview {
    FeedView()
}
