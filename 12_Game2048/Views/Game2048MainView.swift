import SwiftUI

/// 教材のエントリーポイント。スコアヘッダ・盤面・スワイプ操作・ゲームオーバー表示をまとめる。
struct Game2048MainView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                boardArea
                Spacer()
            }
            .padding()
            .navigationTitle("2048")
        }
    }

    // MARK: - スコアヘッダ

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("\(viewModel.score)")
                    .font(.title2.bold())
            }
            Spacer()
            Button("リセット") {
                withAnimation {
                    viewModel.startNewGame()
                }
            }
        }
    }

    // MARK: - 盤面

    private var boardArea: some View {
        ZStack {
            BoardBackground(size: viewModel.size)

            ForEach(viewModel.tiles) { tile in
                TileView(tile: tile)
            }

            if viewModel.isGameOver {
                gameOverOverlay
            }
        }
        .frame(width: BoardLayout.boardSize, height: BoardLayout.boardSize)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    handleSwipe(value.translation)
                }
        )
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 16) {
            Text("ゲームオーバー")
                .font(.title.bold())
                .foregroundStyle(.white)
            Button("もう一度") {
                withAnimation {
                    viewModel.startNewGame()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: BoardLayout.boardSize, height: BoardLayout.boardSize)
        .background(.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// ドラッグの最終的な向き(横/縦どちらが大きいか)から上下左右を判定してVMに伝える
    private func handleSwipe(_ translation: CGSize) {
        let direction: MoveDirection
        if abs(translation.width) > abs(translation.height) {
            direction = translation.width > 0 ? .right : .left
        } else {
            direction = translation.height > 0 ? .down : .up
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            viewModel.move(direction)
        }
    }
}

#Preview {
    Game2048MainView()
}
