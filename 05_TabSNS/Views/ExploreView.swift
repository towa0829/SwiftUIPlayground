import SwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: HomeViewModel
    let trendingTopics = ["#SwiftUI", "#iOS開発", "#Swift", "#Xcode", "#WWDC", "#CoreData", "#SwiftData", "#UIKit"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("トレンドトピック")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(trendingTopics, id: \.self) { topic in
                        Text(topic)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)

                Text("おすすめユーザー")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(SNSUser.suggestions) { user in
                        HStack(spacing: 12) {
                            Image(systemName: user.avatarIcon)
                                .font(.title2)
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name).font(.subheadline.bold())
                                Text(user.bio).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(user.followersCount)人")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("探索")
    }
}

#Preview {
    NavigationStack {
        ExploreView(viewModel: HomeViewModel())
    }
}
