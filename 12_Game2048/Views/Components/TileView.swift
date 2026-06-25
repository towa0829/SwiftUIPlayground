import SwiftUI

/// 1枚のタイルの見た目。数値ごとに背景色・文字サイズを変える。
/// row/colの変化は親(Game2048MainView)がwithAnimationで包むことで「滑る」アニメーションになる。
struct TileView: View {
    let tile: Tile

    var body: some View {
        Text("\(tile.value)")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(tile.value <= 4 ? Color.primary : Color.white)
            .frame(width: BoardLayout.cellSize, height: BoardLayout.cellSize)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
            // isMergedの間だけ少し拡大し、合体した瞬間にポップして見える
            .scaleEffect(tile.isMerged ? 1.15 : 1.0)
            .position(BoardLayout.position(row: tile.row, col: tile.col))
            .transition(.scale.combined(with: .opacity))
    }

    private var fontSize: CGFloat {
        switch tile.value {
        case ..<100: return 28
        case ..<1000: return 24
        default: return 20
        }
    }

    private var backgroundColor: Color {
        switch tile.value {
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4: return Color(red: 0.93, green: 0.87, blue: 0.78)
        case 8: return .orange.opacity(0.7)
        case 16: return .orange
        case 32: return .red.opacity(0.7)
        case 64: return .red
        case 128: return .yellow.opacity(0.8)
        case 256: return .yellow
        case 512: return .green.opacity(0.7)
        case 1024: return .green
        default: return .purple
        }
    }
}

#Preview {
    ZStack {
        TileView(tile: Tile(value: 2, row: 0, col: 0))
        TileView(tile: Tile(value: 2048, row: 0, col: 1))
    }
    .frame(width: BoardLayout.boardSize, height: BoardLayout.boardSize)
}
