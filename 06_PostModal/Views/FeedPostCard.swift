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
