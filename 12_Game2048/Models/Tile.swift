import Foundation

/// 2048盤面上の1枚のタイル
struct Tile: Identifiable, Equatable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
    /// 直前の移動で合体して生まれたタイルかどうか（合体ポップ演出用の一時的な状態）
    var isMerged: Bool

    init(id: UUID = UUID(), value: Int, row: Int, col: Int, isMerged: Bool = false) {
        self.id = id
        self.value = value
        self.row = row
        self.col = col
        self.isMerged = isMerged
    }
}
