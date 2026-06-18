import SwiftUI

struct NewPostSheet: View {
    // @Binding ではなく @ObservedObject でViewModelを受け取る
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var bodyText = ""

    private let bodyLimit = 200

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespaces).isEmpty &&
        bodyText.count <= bodyLimit
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("投稿のタイトル", text: $title)
                }

                Section("本文") {
                    // TextEditor: 複数行テキスト入力
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 120)
                }

                Section {
                    // @Binding の使い方サンプル
                    CharacterCountView(text: $bodyText, limit: bodyLimit)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        // @Environment(\.dismiss) でシートを閉じる
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("投稿する") {
                        viewModel.addPost(title: title, body: bodyText)
                        dismiss()
                    }
                    .bold()
                    .disabled(!isFormValid)
                }
            }
        }
        // presentationDetents: シートの高さを制御
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NewPostSheet(viewModel: FeedViewModel())
}
