import Foundation

/// スワイプの方向
enum MoveDirection {
    case up, down, left, right
}

/// 4x4の2048ボードを管理するViewModel。
/// 「タイルがどこにあるか」「合体したか」「ゲームオーバーかどうか」を一元管理し、
/// Viewはtilesの内容をそのまま描画するだけにする。
class GameViewModel: ObservableObject {
    let size = 4

    @Published var tiles: [Tile] = []
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false

    init() {
        startNewGame()
    }

    /// 新しいゲームを開始する（初期タイル2枚を配置）
    func startNewGame() {
        tiles = []
        score = 0
        isGameOver = false
        spawnTile()
        spawnTile()
    }

    /// 指定方向にタイルを動かす。何も変化しない場合は何もしない（新タイルも出さない）
    func move(_ direction: MoveDirection) {
        guard !isGameOver else { return }

        // row/colのタプルはOptional同士の比較ができないため、1つのIntのセル番号に変換して保持する
        let previousCellIndex = Dictionary(uniqueKeysWithValues: tiles.map { ($0.id, $0.row * size + $0.col) })

        var newTiles: [Tile] = []
        var gainedScore = 0

        for lineIndex in 0..<size {
            let lineTiles = orderedTiles(direction: direction, lineIndex: lineIndex)
            let (collapsed, lineScore) = collapseLine(lineTiles)
            gainedScore += lineScore
            newTiles.append(contentsOf: placeBack(collapsed, direction: direction, lineIndex: lineIndex))
        }

        let positionsChanged = newTiles.contains { previousCellIndex[$0.id] != $0.row * size + $0.col }
        let tilesDisappeared = newTiles.count != tiles.count
        guard positionsChanged || tilesDisappeared else { return }

        tiles = newTiles
        score += gainedScore

        // スライド・合体アニメーションが落ち着いてから新タイルを出す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.spawnTile()
            self?.checkGameOver()
        }
    }

    // MARK: - 移動・合体ロジック

    /// 移動方向に沿って並べた、指定ライン(行 or 列)上のタイル一覧
    private func orderedTiles(direction: MoveDirection, lineIndex: Int) -> [Tile] {
        switch direction {
        case .left:
            return tiles.filter { $0.row == lineIndex }.sorted { $0.col < $1.col }
        case .right:
            return tiles.filter { $0.row == lineIndex }.sorted { $0.col > $1.col }
        case .up:
            return tiles.filter { $0.col == lineIndex }.sorted { $0.row < $1.row }
        case .down:
            return tiles.filter { $0.col == lineIndex }.sorted { $0.row > $1.row }
        }
    }

    /// 1ライン分のタイルを詰めて、隣接する同値タイルを1回だけ合体させる
    private func collapseLine(_ lineTiles: [Tile]) -> (result: [Tile], scoreGained: Int) {
        var result: [Tile] = []
        var scoreGained = 0
        var i = 0
        while i < lineTiles.count {
            var tile = lineTiles[i]
            if i + 1 < lineTiles.count, lineTiles[i + 1].value == tile.value {
                tile.value *= 2
                tile.isMerged = true
                scoreGained += tile.value
                i += 2
            } else {
                tile.isMerged = false
                i += 1
            }
            result.append(tile)
        }
        return (result, scoreGained)
    }

    /// 詰め終わったラインのタイルに、実際の row/col を書き戻す
    private func placeBack(_ lineTiles: [Tile], direction: MoveDirection, lineIndex: Int) -> [Tile] {
        lineTiles.enumerated().map { index, lineTile in
            var tile = lineTile
            switch direction {
            case .left:
                tile.row = lineIndex
                tile.col = index
            case .right:
                tile.row = lineIndex
                tile.col = size - 1 - index
            case .up:
                tile.col = lineIndex
                tile.row = index
            case .down:
                tile.col = lineIndex
                tile.row = size - 1 - index
            }
            return tile
        }
    }

    // MARK: - 出現・ゲームオーバー

    /// 空いているセルにランダムで新タイル(2、たまに4)を1枚追加する
    private func spawnTile() {
        let occupied = Set(tiles.map { $0.row * size + $0.col })
        let emptyCells = (0..<(size * size)).filter { !occupied.contains($0) }
        guard let cellIndex = emptyCells.randomElement() else { return }

        let value = Int.random(in: 0..<10) == 0 ? 4 : 2
        let tile = Tile(value: value, row: cellIndex / size, col: cellIndex % size)
        tiles.append(tile)
    }

    /// どの方向にも動かせない（空きマスも合体可能なペアもない）状態かを判定する
    private func checkGameOver() {
        guard tiles.count == size * size else { return }
        let directions: [MoveDirection] = [.up, .down, .left, .right]
        let canMove = directions.contains { direction in
            (0..<size).contains { lineIndex in
                let line = orderedTiles(direction: direction, lineIndex: lineIndex)
                let (collapsed, _) = collapseLine(line)
                return collapsed.count != line.count
            }
        }
        isGameOver = !canMove
    }
}
