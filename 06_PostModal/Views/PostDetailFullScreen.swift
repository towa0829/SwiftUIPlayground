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
