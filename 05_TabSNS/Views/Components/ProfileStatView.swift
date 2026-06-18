import SwiftUI

/// プロフィール統計（投稿/フォロワー/フォロー中）の value/title 表示
struct ProfileStatView: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 32) {
        ProfileStatView(value: "42", title: "投稿")
        ProfileStatView(value: "312", title: "フォロワー")
    }
}
