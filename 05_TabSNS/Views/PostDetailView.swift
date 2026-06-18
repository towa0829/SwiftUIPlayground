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
