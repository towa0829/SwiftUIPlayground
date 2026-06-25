import SwiftUI

/// 教材のエントリーポイント。カードスタック・Like/Nopeボタン・カウンタ・空状態をまとめる。
struct SwipeCardsMainView: View {
    @StateObject private var viewModel = CardStackViewModel()

    /// Like/Nopeボタンから先頭カードへ「この方向にスワイプして」と伝えるための値
    @State private var programmaticSwipe: SwipeDirection?

    /// スタックとして重ねて見せる枚数（多すぎると奥のカードが見えないので3枚に制限）
    private let visibleCount = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                counterRow

                Spacer()

                if viewModel.cards.isEmpty {
                    emptyState
                } else {
                    cardStack
                }

                Spacer()

                if !viewModel.cards.isEmpty {
                    actionButtons
                }
            }
            .padding()
            .navigationTitle("スワイプカード")
        }
    }

    // MARK: - カウンタ表示

    private var counterRow: some View {
        HStack(spacing: 24) {
            Label("\(viewModel.likedCount)", systemImage: "heart.fill")
                .foregroundStyle(.green)
            Spacer()
            Label("\(viewModel.nopedCount)", systemImage: "xmark")
                .foregroundStyle(.red)
        }
        .font(.headline)
    }

    // MARK: - カードスタック

    private var cardStack: some View {
        ZStack {
            // 後ろのカードから描画し、最後に先頭カードを描画する（先頭が一番手前）
            ForEach(stackedEntries.reversed()) { entry in
                CardView(
                    card: entry.card,
                    viewModel: viewModel,
                    // 先頭カード(depth == 0)だけがLike/Nopeボタンの指示を受け取る
                    programmaticSwipe: entry.depth == 0 ? $programmaticSwipe : .constant(nil)
                )
                // 奥のカードほど少し縮小・下にずらして「重なり」を表現する
                .scaleEffect(1 - CGFloat(entry.depth) * 0.05)
                .offset(y: CGFloat(entry.depth) * 10)
                .allowsHitTesting(entry.depth == 0)
            }
        }
    }

    /// カードとスタック内の深さ(0が先頭)を組にした、ForEach用の表示単位
    private struct StackEntry: Identifiable {
        let card: ProfileCard
        let depth: Int
        var id: UUID { card.id }
    }

    /// スタックの先頭から最大 visibleCount 枚を、深さ情報付きで取り出す
    private var stackedEntries: [StackEntry] {
        viewModel.cards.prefix(visibleCount).enumerated().map { depth, card in
            StackEntry(card: card, depth: depth)
        }
    }

    // MARK: - 操作ボタン

    private var actionButtons: some View {
        HStack(spacing: 48) {
            Button {
                programmaticSwipe = .nope
            } label: {
                Image(systemName: "xmark")
                    .font(.title.bold())
                    .foregroundStyle(.red)
                    .padding(20)
                    .background(.red.opacity(0.15), in: Circle())
            }

            Button {
                programmaticSwipe = .like
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title.bold())
                    .foregroundStyle(.green)
                    .padding(20)
                    .background(.green.opacity(0.15), in: Circle())
            }
        }
    }

    // MARK: - 空状態

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("全部めくり終わりました")
                .font(.headline)
            Button("もう一度") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SwipeCardsMainView()
}
