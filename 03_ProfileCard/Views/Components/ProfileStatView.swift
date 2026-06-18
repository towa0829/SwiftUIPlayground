import SwiftUI

/// 「投稿」「フォロワー」などの統計値を value/title の縦並びで表示する共通コンポーネント。
/// カード(白文字onグラデーション)と詳細画面(primary/secondary)の両方から見た目を調整して使う。
struct ProfileStatView: View {
    let value: String
    let title: String
    var valueFont: Font = .subheadline.bold()
    var titleFont: Font = .footnote
    var valueColor: Color = .primary
    var titleColor: Color = .secondary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ProfileStatView(value: "82", title: "投稿")
        ProfileStatView(value: "1.2K", title: "フォロワー", valueColor: .white, titleColor: .white.opacity(0.7))
            .padding()
            .background(Color.purple)
    }
}
