import SwiftUI

struct ProfileCardView: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showDetail = false

    var body: some View {
        // ZStack: 複数のViewを重ねて配置する
        ZStack(alignment: .bottomLeading) {
            // 背景グラデーション
            LinearGradient(
                colors: [profile.accentColor.opacity(0.8), profile.accentColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // コンテンツ
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: profile.avatarSystemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)

                    Spacer()

                    // フォローボタン
                    Button {
                        viewModel.toggleFollow(profile)
                    } label: {
                        Text(viewModel.followStatus(for: profile) ? "フォロー中" : "フォロー")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.followStatus(for: profile) ? Color.white.opacity(0.3) : Color.white)
                            .foregroundStyle(viewModel.followStatus(for: profile) ? .white : profile.accentColor)
                            .clipShape(Capsule())
                    }
                }

                Text(profile.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(profile.handle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                // フォロワー統計
                HStack(spacing: 20) {
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.postsCount),
                        title: "投稿",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.followersCount),
                        title: "フォロワー",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.followingCount),
                        title: "フォロー中",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: profile.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        // overlay: 既存のViewの上に別のViewを重ねる
        .overlay(alignment: .topTrailing) {
            Button {
                showDetail = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(12)
            }
        }
        // sheet: モーダルな画面を下からスライドアップ表示する
        .sheet(isPresented: $showDetail) {
            ProfileDetailSheet(profile: profile, viewModel: viewModel)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(Profile.samples) { profile in
                ProfileCardView(profile: profile, viewModel: ProfileViewModel())
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
