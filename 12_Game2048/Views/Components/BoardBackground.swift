import SwiftUI

/// セルの位置計算を共有するためのレイアウト定数。
/// row/col からセル中央の座標(CGPoint)を出すヘルパーを BoardBackground と TileView で使う。
struct BoardLayout {
    static let cellSize: CGFloat = 70
    static let spacing: CGFloat = 10
    static let boardSize: CGFloat = CGFloat(4) * cellSize + CGFloat(5) * spacing

    static func position(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: spacing + CGFloat(col) * (cellSize + spacing) + cellSize / 2,
            y: spacing + CGFloat(row) * (cellSize + spacing) + cellSize / 2
        )
    }
}

/// 4x4の空セル背景（タイルはこの上に別レイヤーで重ねて表示する）
struct BoardBackground: View {
    let size: Int

    var body: some View {
        ZStack {
            ForEach(0..<size, id: \.self) { row in
                ForEach(0..<size, id: \.self) { col in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: BoardLayout.cellSize, height: BoardLayout.cellSize)
                        .position(BoardLayout.position(row: row, col: col))
                }
            }
        }
        .frame(width: BoardLayout.boardSize, height: BoardLayout.boardSize)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    BoardBackground(size: 4)
}
