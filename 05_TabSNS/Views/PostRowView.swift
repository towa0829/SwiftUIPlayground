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
