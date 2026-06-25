import SwiftUI

/// 1枚分のカード。ドラッグ中の見た目（offset/rotation/スタンプの濃さ）は
/// このViewだけが知っていればよい「一時的な状態」なので @State で持つ。
/// 「カードを実際に1枚減らす」というデッキの状態変化はVM(swipe)に委譲する。
struct CardView: View {
    let card: ProfileCard
    let viewModel: CardStackViewModel

    /// Like/Nopeボタンから「先頭カードをこの方向にスワイプして」と指示するための窓口。
    /// ボタン側がここに値を入れると、このカードが自分でアニメーションして消える。
    @Binding var programmaticSwipe: SwipeDirection?

    /// ドラッグ中の移動量（見た目だけの状態）
    @State private var dragOffset: CGSize = .zero

    /// 画面外まで投げ出すと判定するドラッグ量のしきい値
    private let swipeThreshold: CGFloat = 120

    /// ドラッグ量に応じた回転角（左右に傾く）
    private var rotation: Angle {
        .degrees(Double(dragOffset.width / 20))
    }

    /// ドラッグ量からLIKEスタンプの不透明度を計算（右にドラッグするほど濃くなる）
    private var likeOpacity: Double {
        guard dragOffset.width > 0 else { return 0 }
        return min(Double(dragOffset.width / swipeThreshold), 1)
    }

    /// ドラッグ量からNOPEスタンプの不透明度を計算（左にドラッグするほど濃くなる）
    private var nopeOpacity: Double {
        guard dragOffset.width < 0 else { return 0 }
        return min(Double(-dragOffset.width / swipeThreshold), 1)
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(card.color.opacity(0.2))
                .overlay {
                    VStack(spacing: 12) {
                        Text(card.emoji)
                            .font(.system(size: 96))
                        Text("\(card.name)　\(card.age)歳")
                            .font(.title2.bold())
                        Text(card.bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            ForEach(card.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.6), in: Capsule())
                            }
                        }
                    }
                    .padding()
                }
                .shadow(radius: 6)

            HStack {
                ChoiceStamp(text: "LIKE", color: .green)
                    .opacity(likeOpacity)
                Spacer()
                ChoiceStamp(text: "NOPE", color: .red)
                    .opacity(nopeOpacity)
            }
            .padding(20)
        }
        .frame(width: 300, height: 420)
        .offset(dragOffset)
        .rotationEffect(rotation)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleDragEnded(value.translation)
                }
        )
        .onChange(of: programmaticSwipe) { direction in
            guard let direction else { return }
            throwCard(direction: direction, towards: direction == .like ? 600 : -600)
            programmaticSwipe = nil
        }
    }

    /// ドラッグが終わった時点での移動量からスワイプ確定/スナップバックを決める
    private func handleDragEnded(_ translation: CGSize) {
        if translation.width > swipeThreshold {
            throwCard(direction: .like, towards: 600)
        } else if translation.width < -swipeThreshold {
            throwCard(direction: .nope, towards: -600)
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
    }

    /// 画面外まで投げ出すアニメーションを再生してからVMにスワイプを伝える
    private func throwCard(direction: SwipeDirection, towards endX: CGFloat) {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: endX, height: dragOffset.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.swipe(card, direction: direction)
        }
    }
}

#Preview {
    CardView(card: ProfileCard.samples[0], viewModel: CardStackViewModel(), programmaticSwipe: .constant(nil))
}
