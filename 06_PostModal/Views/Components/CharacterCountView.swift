import SwiftUI

// @Binding の学習用: 親からテキストのBindingを受け取って文字数カウント
struct CharacterCountView: View {
    @Binding var text: String  // 親Viewのstateへの参照
    let limit: Int

    var count: Int { text.count }
    var isOverLimit: Bool { count > limit }

    var body: some View {
        HStack {
            Text("文字数")
            Spacer()
            Text("\(count) / \(limit)")
                .foregroundStyle(isOverLimit ? .red : .secondary)
                .fontWeight(isOverLimit ? .bold : .regular)
        }
        .font(.subheadline)
    }
}

#Preview {
    CharacterCountView(text: .constant("サンプルテキスト"), limit: 200)
}
