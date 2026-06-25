import SwiftUI

/// カードの左上/右上に出る「LIKE」「NOPE」のスタンプ。
/// ドラッグ量に応じて呼び出し側が opacity を変えることで、
/// 「ドラッグするほどはっきり見える」演出になる。
struct ChoiceStamp: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 4)
            }
            .rotationEffect(.degrees(text == "LIKE" ? -15 : 15))
    }
}

#Preview {
    HStack(spacing: 24) {
        ChoiceStamp(text: "LIKE", color: .green)
        ChoiceStamp(text: "NOPE", color: .red)
    }
}
