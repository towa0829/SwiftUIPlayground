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
