import Foundation

/// スワイプの方向（Like / Nope の判定結果）
enum SwipeDirection {
    case like
    case nope
}

/// カードデッキの状態（先頭 = 一番手前のカード）を一元管理するViewModel。
/// 「いつカードが減るか」「Like/Nopeの集計」はここに集約し、
/// Viewはドラッグ中の見た目（offset/rotation）だけを担当する。
class CardStackViewModel: ObservableObject {
    @Published var cards: [ProfileCard] = ProfileCard.samples
    @Published var likedCount: Int = 0
    @Published var nopedCount: Int = 0

    /// 先頭カードをデッキから取り除き、方向に応じて集計する
    func swipe(_ card: ProfileCard, direction: SwipeDirection) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards.remove(at: index)
        switch direction {
        case .like:
            likedCount += 1
        case .nope:
            nopedCount += 1
        }
    }

    /// デッキを最初の状態に戻す（空状態画面の「もう一度」ボタン用）
    func reset() {
        cards = ProfileCard.samples
        likedCount = 0
        nopedCount = 0
    }
}
