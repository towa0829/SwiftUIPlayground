# 12 Game2048 ロードマップ

完成形: DragGesture + 安定IDの位置アニメーション + scaleEffect + .transition で
「スワイプして詰める・合体する・出現する」2048を体感する

---

## Step 1 — Tile モデルと GameViewModel の骨格
**ファイル:** `Models/Tile.swift`、`ViewModels/GameViewModel.swift` を新規作成

### 1-1: Tile struct
```swift
import Foundation

struct Tile: Identifiable, Equatable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
    var isMerged: Bool

    init(id: UUID = UUID(), value: Int, row: Int, col: Int, isMerged: Bool = false) {
        self.id = id
        self.value = value
        self.row = row
        self.col = col
        self.isMerged = isMerged
    }
}
```
`id`が移動の前後で変わらないことが重要。後のステップで「同じidのタイルのrow/colが
変わると滑って見える」というアニメーションの仕組みを作る。

### 1-2: GameViewModel の骨格（盤面の初期化だけ）
```swift
import Foundation

enum MoveDirection {
    case up, down, left, right
}

class GameViewModel: ObservableObject {
    let size = 4

    @Published var tiles: [Tile] = []
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false

    init() {
        startNewGame()
    }

    func startNewGame() {
        tiles = []
        score = 0
        isGameOver = false
        spawnTile()
        spawnTile()
    }

    private func spawnTile() {
        let occupied = Set(tiles.map { $0.row * size + $0.col })
        let emptyCells = (0..<(size * size)).filter { !occupied.contains($0) }
        guard let cellIndex = emptyCells.randomElement() else { return }

        let value = Int.random(in: 0..<10) == 0 ? 4 : 2
        let tile = Tile(value: value, row: cellIndex / size, col: cellIndex % size)
        tiles.append(tile)
    }
}
```
▶ 理解: `spawnTile`は「空いているセルのインデックス（0〜15）」をランダムに1つ選び、
そこから`row = index / size`、`col = index % size`を逆算している。

---

## Step 2 — 盤面の見た目（BoardBackground / TileView）
**ファイル:** `Views/Components/BoardBackground.swift`、`Views/Components/TileView.swift` を新規作成

### 2-1: 位置計算ヘルパー(BoardLayout) + 空セル背景
```swift
import SwiftUI

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
```
▶ ここで確認: 4x4の薄いグレーのセルが並んだ盤面が表示されること

### 2-2: TileView
```swift
import SwiftUI

struct TileView: View {
    let tile: Tile

    var body: some View {
        Text("\(tile.value)")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(tile.value <= 4 ? Color.primary : Color.white)
            .frame(width: BoardLayout.cellSize, height: BoardLayout.cellSize)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
            .position(BoardLayout.position(row: tile.row, col: tile.col))
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
```
▶ ここで確認: 数字ごとに違う色のタイルが表示されること

---

## Step 3 — タイルを盤面に並べて表示する
**ファイル:** `Views/Game2048MainView.swift` を新規作成

```swift
import SwiftUI

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

    private var boardArea: some View {
        ZStack {
            BoardBackground(size: viewModel.size)
            ForEach(viewModel.tiles) { tile in
                TileView(tile: tile)
            }
        }
        .frame(width: BoardLayout.boardSize, height: BoardLayout.boardSize)
    }
}

#Preview {
    Game2048MainView()
}
```
▶ ここで確認: 起動時に盤面上のランダムな2マスに2(または4)のタイルが表示されること。
「リセット」を押すと別の配置に変わること

---

## Step 4 — DragGesture でスワイプ方向を判定する
**ファイル:** `Views/Game2048MainView.swift` を編集

```swift
// boardArea の最後（.frame(...)の直後）に追加
.gesture(
    DragGesture(minimumDistance: 20)
        .onEnded { value in
            handleSwipe(value.translation)
        }
)
```
```swift
// Game2048MainView に追加するメソッド
private func handleSwipe(_ translation: CGSize) {
    let direction: MoveDirection
    if abs(translation.width) > abs(translation.height) {
        direction = translation.width > 0 ? .right : .left
    } else {
        direction = translation.height > 0 ? .down : .up
    }
    print(direction)  // 仮実装。Step 5でviewModel.moveに置き換える
}
```
▶ 理解: 横方向の移動量(`translation.width`)と縦方向の移動量(`translation.height`)を
絶対値で比較し、大きい方を「スワイプの軸」とみなす。

▶ ここで確認: 上下左右にスワイプすると、コンソールに正しい方向が表示されること

---

## Step 5 — 移動ロジック（合体なし）でタイルを滑らせる
**ファイル:** `ViewModels/GameViewModel.swift`、`Views/Game2048MainView.swift` を編集

### 5-1: 1ライン分のタイルを取り出す・詰める
```swift
// GameViewModel に追加
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
```
▶ 理解: `orderedTiles`は「移動方向に向かって近い順」にタイルを並べる。
`placeBack`はその並び順(`index`)から逆算して、詰めた後の実際の`row`/`col`を書き戻す。
例えば`.left`なら一番近い(`index == 0`)タイルが`col = 0`になる。

### 5-2: move(_:) で全ラインに適用する（合体はまだしない）
```swift
// GameViewModel に追加
func move(_ direction: MoveDirection) {
    guard !isGameOver else { return }

    var newTiles: [Tile] = []
    for lineIndex in 0..<size {
        let lineTiles = orderedTiles(direction: direction, lineIndex: lineIndex)
        newTiles.append(contentsOf: placeBack(lineTiles, direction: direction, lineIndex: lineIndex))
    }
    tiles = newTiles
}
```

### 5-3: View から呼び出す
```swift
// handleSwipe の最後の行を置き換える
withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
    viewModel.move(direction)
}
```
▶ ここで確認: スワイプするとタイルがその方向の端まで滑って詰まること（まだ合体せず、
同じ数字が並んだ状態になる）

---

## Step 6 — 合体ロジック・スコア・合体ポップ
**ファイル:** `ViewModels/GameViewModel.swift`、`Views/Components/TileView.swift` を編集

### 6-1: collapseLine で隣接する同値タイルを合体させる
```swift
// GameViewModel に追加
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
            i += 2  // 2枚分まとめて処理したので2つ進める
        } else {
            tile.isMerged = false
            i += 1
        }
        result.append(tile)
    }
    return (result, scoreGained)
}
```
▶ 理解: `orderedTiles`で「近い順」に並んでいるので、隣り合う2枚(`i`番目と`i+1`番目)が
同じ値なら合体できる。1回合体したペアは2つまとめて消費する(`i += 2`)ので、3枚連続で
同じ値があっても一度に2枚しか合体しない（2048のルールと同じ）。

### 6-2: move(_:) を collapseLine 経由に変更し、スコアと変化判定を追加
```swift
// move(_:) を置き換える
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
}
```
▶ 理解: 「動かす前のid→セル番号(row*size+col)」を`previousCellIndex`に保存しておき、
動かした後に1つでもセル番号が変わったタイルがあれば`positionsChanged = true`。
（`row`/`col`のタプルのままだと`Optional<(Int,Int)>`と`(Int,Int)`を`!=`で比較できず
コンパイルエラーになるため、比較しやすい1つの`Int`に変換している。）
合体でタイルが減っていれば`tilesDisappeared = true`。どちらも`false`（=何も起きない）
ならその場で処理を打ち切り、あとのステップで追加する「新タイル出現」も起こさない。

### 6-3: TileView に合体ポップを追加
```swift
// .background(...) の直後に追加
.scaleEffect(tile.isMerged ? 1.15 : 1.0)
```
▶ ここで確認: 同じ数字のタイルをぶつけると合体して数値が2倍になり、一瞬大きくなる
こと。スコアが合体した値の分だけ増えること

---

## Step 7 — 新タイル出現とゲームオーバー
**ファイル:** `ViewModels/GameViewModel.swift`、`Views/Components/TileView.swift`、
`Views/Game2048MainView.swift` を編集

### 7-1: move(_:) の最後に新タイル出現とゲームオーバー判定を追加
```swift
// move(_:) の "tiles = newTiles" 〜 "score += gainedScore" の下に追加
DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
    self?.spawnTile()
    self?.checkGameOver()
}
```
スライド・合体のアニメーションが落ち着くのを0.15秒待ってから新タイルを出す。
（`spawnTile`はStep 1で作った関数をそのまま再利用する）

### 7-2: ゲームオーバー判定
```swift
// GameViewModel に追加
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
```
▶ 理解: 盤面が満杯(`tiles.count == size * size`)の時だけ判定する。4方向それぞれを
「試しに動かしてみて、どこかのラインで合体が起きるか」だけ確認し、実際には
`tiles`を書き換えない（`collapseLine`は受け取った配列を変更するだけで、VMの
`tiles`そのものには影響しない）。どの方向でも合体が起きないなら詰みと判断する。

### 7-3: TileView に出現トランジションを追加
```swift
// .scaleEffect(...) の直後に追加
.transition(.scale.combined(with: .opacity))
```

### 7-4: Game2048MainView にゲームオーバーオーバーレイを追加
```swift
// boardArea の ZStack の最後に追加
if viewModel.isGameOver {
    gameOverOverlay
}
```
```swift
// Game2048MainView に追加するプロパティ
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
```
▶ ここで確認: スワイプを繰り返して盤面を満杯にすると「ゲームオーバー」が表示され、
「もう一度」で最初からやり直せること。盤面が変化した直後だけ新タイルがふわっと
出現すること（無駄な手を出してもタイルは増えない）

---

## 完成チェックリスト
- [ ] スワイプ方向に応じてタイルが滑って詰まる（安定ID + `.position` + `withAnimation`）
- [ ] 同じ数字が隣接すると合体し、値が2倍になってスコアが増える
- [ ] 合体した瞬間にタイルがポップする（`scaleEffect` + `isMerged`）
- [ ] 盤面が変化した手のときだけ新タイルがふわっと出現する（`.transition`）
- [ ] 盤面が満杯でどの方向にも動かせなくなるとゲームオーバーになる
- [ ] 「何も変化しない手」では新タイルが出ない理由を説明できる

## アニメーションまとめ

| 手法 | 用途 |
|---|---|
| 安定ID + `.position` + `withAnimation` | タイルが滑るスライドアニメーション |
| `.scaleEffect` + `isMerged` フラグ | 合体時のポップ |
| `.transition(.scale.combined(with:.opacity))` | 新タイル出現のアニメーション |
| `withAnimation(.spring)` | スワイプ全体の弾力 |

---

## 設計メモ: なぜ matchedGeometryEffect を主軸にしなかったか
2048のスライドは「同じ画面・同じZStack内で、同じタイルの座標が変わる」だけなので、
`matchedGeometryEffect`（別々の場所にある2つのViewを繋ぐための仕組み）は本来不要。
`ForEach(viewModel.tiles)`が同じ`id`を見ている限り、`.position`の変化を
`withAnimation`で包むだけでSwiftUIが自動的に滑るアニメーションを補間してくれる。
これは Module 10 の設計メモで触れた「`matchedGeometryEffect`が効くのは同じView階層に
同時に存在する場合だけ」という制約の、ちょうど逆のケース（同じ階層に同時に存在する
からこそ、もっと簡単な手段で十分）にあたる。

## 設計メモ: 合体で消えるタイルを簡略化した理由
本教材の`collapseLine`は、合体する2枚のうち生き残る側だけを結果に残し、消える側は
その場で配列から取り除く。そのため「消える側のタイルが合体先まで滑ってから消える」
という本家2048のような演出はせず、即座に表示が消える。これは合体直前のタイルに
「最終的な合体先の座標を持たせたまま少し遅れて取り除く」処理が必要になり、本教材の
スコープでは複雑さが見合わないと判断したため。発展課題としてREADMEに残してある。
