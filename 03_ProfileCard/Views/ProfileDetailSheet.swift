import SwiftUI

struct ProfileDetailSheet: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    /// アバターをバナーの下端に半分だけ重ねて表示するためのサイズ。
    /// offsetとpaddingはこの値から導出し、マジックナンバーを避ける。
    private let avatarDiameter: CGFloat = 100

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー (ZStack + overlay の組み合わせ)
                    ZStack(alignment: .bottom) {
                        // バナー背景
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [profile.accentColor, profile.accentColor.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 120)

                        // アバター (バナー下端から半分だけ突き出すように重ねる)
                        Image(systemName: profile.avatarSystemImage)
                            .font(.system(size: avatarDiameter * 0.8))
                            .foregroundStyle(.white)
                            .background(Circle().fill(profile.accentColor).frame(width: avatarDiameter, height: avatarDiameter))
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .offset(y: avatarDiameter / 2)
                    }
                    .padding(.bottom, avatarDiameter / 2)

                    // プロフィール情報
                    VStack(spacing: 8) {
                        Text(profile.name)
                            .font(.title2.bold())
                        Text(profile.handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(profile.bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // 統計
                    HStack(spacing: 32) {
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.postsCount),
                            title: "投稿",
                            valueFont: .title3.bold()
                        )
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.followersCount),
                            title: "フォロワー",
                            valueFont: .title3.bold()
                        )
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.followingCount),
                            title: "フォロー中",
                            valueFont: .title3.bold()
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // 詳細情報
                    VStack(alignment: .leading, spacing: 12) {
                        if !profile.location.isEmpty {
                            Label(profile.location, systemImage: "mappin.circle.fill")
                        }
                        if !profile.website.isEmpty {
                            Label(profile.website, systemImage: "link.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // フォローボタン
                    Button {
                        viewModel.toggleFollow(profile)
                    } label: {
                        Text(viewModel.followStatus(for: profile) ? "フォロー中" : "フォローする")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.followStatus(for: profile) ? Color.secondary.opacity(0.2) : profile.accentColor)
                            .foregroundStyle(viewModel.followStatus(for: profile) ? .primary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileDetailSheet(profile: Profile.sample, viewModel: ProfileViewModel())
}
