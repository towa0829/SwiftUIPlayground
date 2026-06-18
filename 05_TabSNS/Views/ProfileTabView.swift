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
