# 04 PhotoGallery ロードマップ

完成形: カテゴリフィルター付き2列グリッド + 非同期画像読み込み

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Photo.swift` を新規作成

### 1-1: 写真自体のカテゴリ enum（PhotoTag）
```swift
import Foundation

/// 写真自体が持つカテゴリ。「すべて」は概念上存在しないため、フィルター専用の PhotoCategory とは型を分ける。
enum PhotoTag: String, CaseIterable, Identifiable {
    case nature = "自然"
    case city = "都市"
    case food = "食べ物"
    case travel = "旅行"

    var id: String { rawValue }
}
```
▶ ここで確認: `PhotoTag` には `.all` がないこと（写真は必ずどれかのカテゴリに属する）

### 1-2: フィルター用カテゴリ enum（PhotoCategory）
```swift
/// ギャラリーのフィルター選択用カテゴリ。「すべて」を含むのはこちらのみ。
enum PhotoCategory: String, CaseIterable, Identifiable {
    case all = "すべて"
    case nature = "自然"
    case city = "都市"
    case food = "食べ物"
    case travel = "旅行"

    var id: String { rawValue }

    func matches(_ tag: PhotoTag) -> Bool {
        self == .all || rawValue == tag.rawValue
    }
}
```
▶ 理解: `PhotoTag`（データ側）と `PhotoCategory`（UI/フィルター側）を分けることで、「すべて」というUI都合の概念がモデルに混ざらない。`matches(_:)` がこの2つの型をつなぐ役割を持つ

### 1-3: Photo struct
```swift
struct Photo: Identifiable {
    let id: UUID
    let title: String
    let category: PhotoTag
    let imageURL: URL?
    let likes: Int
    let author: String

    init(
        id: UUID = UUID(),
        title: String,
        category: PhotoTag,
        imageURLString: String,
        likes: Int = 0,
        author: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        // 不正なURL文字列でも強制アンラップでクラッシュさせず、nilのままAsyncImageに委ねる
        self.imageURL = URL(string: imageURLString)
        self.likes = likes
        self.author = author
    }
}
```
▶ 理解: `imageURL` は `URL?`（Optional）。`URL(string:)!` のように強制アンラップすると不正なURL文字列でアプリ全体がクラッシュするため、nilを許容して `AsyncImage` 側の `.failure` 表示に委ねる

### 1-4: サンプルデータ
```swift
extension Photo {
    // Picsum Photos API を使ったサンプルデータ（実際のURLから画像取得）
    static let samples: [Photo] = [
        Photo(title: "山の夕暮れ", category: .nature, imageURLString: "https://picsum.photos/seed/mtn1/400/400", likes: 234, author: "Towa"),
        Photo(title: "森の朝霧", category: .nature, imageURLString: "https://picsum.photos/seed/forest/400/400", likes: 189, author: "Hana"),
        Photo(title: "夜の渋谷", category: .city, imageURLString: "https://picsum.photos/seed/city1/400/400", likes: 512, author: "Kenji"),
        Photo(title: "東京タワー", category: .city, imageURLString: "https://picsum.photos/seed/tower/400/400", likes: 801, author: "Yuki"),
        Photo(title: "ラーメン", category: .food, imageURLString: "https://picsum.photos/seed/ramen/400/400", likes: 671, author: "Sato"),
        Photo(title: "抹茶パフェ", category: .food, imageURLString: "https://picsum.photos/seed/matcha/400/400", likes: 445, author: "Aoi"),
        Photo(title: "京都の神社", category: .travel, imageURLString: "https://picsum.photos/seed/kyoto/400/400", likes: 923, author: "Ryo"),
        Photo(title: "沖縄の海", category: .travel, imageURLString: "https://picsum.photos/seed/okinawa/400/400", likes: 1102, author: "Miku"),
        Photo(title: "富士山", category: .nature, imageURLString: "https://picsum.photos/seed/fuji/400/400", likes: 2041, author: "Towa"),
        Photo(title: "大阪の夜景", category: .city, imageURLString: "https://picsum.photos/seed/osaka/400/400", likes: 387, author: "Hana"),
        Photo(title: "寿司", category: .food, imageURLString: "https://picsum.photos/seed/sushi/400/400", likes: 560, author: "Kenji"),
        Photo(title: "北海道の雪景色", category: .travel, imageURLString: "https://picsum.photos/seed/hokkaido/400/400", likes: 778, author: "Yuki"),
    ]
}
```
▶ ここで確認: `Photo.samples.count` が `12` であること

---

## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/PhotoViewModel.swift` を新規作成

### 2-1: フィルタリングロジック
```swift
import Foundation
import Combine

class PhotoViewModel: ObservableObject {
    @Published var allPhotos: [Photo] = Photo.samples
    @Published var selectedCategory: PhotoCategory = .all

    var filteredPhotos: [Photo] {
        allPhotos.filter { selectedCategory.matches($0.category) }
    }
}
```
▶ ここで確認: `selectedCategory = .nature` にすると自然写真だけが返ること
▶ 理解: `if selectedCategory == .all { ... } else { ... }` のような分岐を自前で書く代わりに、Step 1で定義した `PhotoCategory.matches(_:)` に委譲している。フィルター条件の判定ロジックをモデル側に閉じ込めることで、ViewModelはシンプルなまま保たれる

### 2-2: いいね数のフォーマット関数を追加
```swift
    func formattedLikes(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
```
▶ ここで確認: `formattedLikes(2041)` が `"2.0K"`、`formattedLikes(512)` が `"512"` になること
▶ 理解: 表示用の整形ロジックはViewではなくViewModelに置く。Viewはこの結果をそのまま表示するだけにする

---

## Step 3 — AsyncImage でセルを作る
**ファイル:** `Views/PhotoGridCell.swift` を新規作成

### 3-1: AsyncImage の最小形
```swift
import SwiftUI

struct PhotoGridCell: View {
    let photo: Photo
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        // AsyncImage: URL から非同期で画像を読み込む
        AsyncImage(url: photo.imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            // 読み込み中のプレースホルダー
            Color.gray.opacity(0.3)
        }
        .frame(height: 150)
        .clipped()
    }
}

#Preview {
    PhotoGridCell(photo: Photo.samples[0], viewModel: PhotoViewModel())
}
```
▶ ここで確認: Preview で画像が表示されること（初回は時間がかかる）
▶ 理解: `viewModel` を `@ObservedObject` で受け取っているのは、次のステップで `formattedLikes(_:)` を使うため。セル自身はStateを持たないので `@StateObject` ではなく `@ObservedObject` を使う

### 3-2: phase ベースの分岐に書き換える
```swift
    AsyncImage(url: photo.imageURL) { phase in
        switch phase {
        case .empty:
            // 読み込み中
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay { ProgressView() }
        case .success(let image):
            // 成功
            image.resizable().scaledToFill()
        case .failure:
            // 失敗
            Rectangle()
                .fill(Color(.systemGray4))
                .overlay { Image(systemName: "photo").foregroundStyle(.secondary) }
        @unknown default:
            EmptyView()
        }
    }
```
▶ ここで確認: 存在しないURLを渡すと `case .failure` のフォールバックが表示されること

### 3-3: いいね数のオーバーレイを追加し、全体を組み立てる
```swift
struct PhotoGridCell: View {
    let photo: Photo
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // AsyncImageからURLから非同期で画像を読み込む
            AsyncImage(url: photo.imageURL) { phase in
                switch phase {
                case .empty:
                    // 読み込み中
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    // 読み込み成功
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    // 読み込み失敗
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // いいね数オーバーレイ
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.footnote)
                Text(viewModel.formattedLikes(photo.likes))
                    .font(.footnote.bold())
            }
            .foregroundStyle(.white)
            .padding(6)
            .background(.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        PhotoGridCell(photo: Photo.samples[0], viewModel: PhotoViewModel())
        PhotoGridCell(photo: Photo.samples[1], viewModel: PhotoViewModel())
    }
}
```
▶ 理解: いいね数は `Text("\(photo.likes)")` ではなく `viewModel.formattedLikes(photo.likes)` を使う。これでセルは数値の整形方法を知らなくてよくなる
▶ 理解: 固定の `frame(height: 150)` と `aspectRatio(1, contentMode: .fit)` を両方指定すると競合してレイアウトが不安定になる。`frame(maxWidth: .infinity, maxHeight: .infinity)` + 親の `aspectRatio` の組み合わせにすることで正方形セルが安定する

---

## Step 4 — LazyVGrid でグリッドを作る
**ファイル:** `Views/PhotoGalleryView.swift` を新規作成

### 4-1: LazyVGrid の最小形
```swift
import SwiftUI

struct PhotoGalleryView: View {
    @StateObject private var viewModel = PhotoViewModel()

    // 列定義: 2列、それぞれ均等幅
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        NavigationStack {
            // ScrollView が必要（LazyVGrid 自体はスクロールしない）
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.filteredPhotos) { photo in
                        PhotoGridCell(photo: photo, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("フォトギャラリー")
        }
    }
}

#Preview { PhotoGalleryView() }
```
▶ ここで確認: 2列グリッドで写真が並ぶこと
▶ 理解: `PhotoGridCell` は `viewModel` を必須パラメータとして受け取るようになったので、呼び出し側でも `viewModel:` を渡す

### 4-2: 列数を3列に変えて Lazy の意味を体感する
```swift
    // 3列に変える
    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
    ]
```
▶ 理解: `LazyVGrid` は画面外のセルをまだ生成しない。スクロールすると順次生成される

### 4-3: 2列に戻して GridItem のパターンを試す
```swift
    // adaptive: 最小80ptを保ちながら自動で列数調整
    private let columns = [GridItem(.adaptive(minimum: 80))]
```
▶ ここで確認: デバイス幅に応じて列数が変わること。2列に戻してから次へ進む

---

## Step 5 — カテゴリフィルターを追加する
**ファイル:** `Views/Components/CategoryChip.swift` を新規作成、その後 `Views/PhotoGalleryView.swift` を編集

### 5-1: カテゴリチップ用の子View
```swift
import SwiftUI

/// カテゴリフィルター用のカプセル型チップ
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    HStack {
        CategoryChip(title: "すべて", isSelected: true) {}
        CategoryChip(title: "自然", isSelected: false) {}
    }
}
```
▶ 理解: 再利用可能なViewは `Views/Components/` に分離する（フォルダ構成のルール）

### 5-2: PhotoGalleryView の ScrollView の上にフィルターを追加
```swift
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PhotoCategory.allCases) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // ScrollView + LazyVGrid でフォトグリッド
                ScrollView { ... }
            }
            .navigationTitle("フォトギャラリー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
```
▶ ここで確認: チップタップで写真が絞り込まれること
▶ 理解: `ForEach(PhotoCategory.allCases)` は `PhotoTag.allCases` ではなく `PhotoCategory.allCases` を使う。フィルターUIには「すべて」が必要なため

---

## Step 6 — 詳細画面と NavigationLink を繋ぐ
**ファイル:** `Views/PhotoDetailView.swift` を新規作成、その後 `PhotoGalleryView.swift` を編集

### 6-1: 詳細画面（大きな AsyncImage + タイトル/カテゴリ）
```swift
import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 大きな画像表示
                AsyncImage(url: photo.imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 300)
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 300)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }

                VStack(alignment: .leading) {
                    Text(photo.title).font(.title2.bold())
                    Label(photo.category.rawValue, systemImage: "tag.fill")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(photo.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```
▶ 理解: `PhotoDetailView` も `PhotoGridCell` と同様に `viewModel` を受け取る。これは次のサブステップで `formattedLikes(_:)` を使うため

### 6-2: いいね数と撮影者の表示を追加する
```swift
                VStack(alignment: .leading, spacing: 12) {
                    Text(photo.title)
                        .font(.title2.bold())

                    HStack {
                        Label(photo.category.rawValue, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(viewModel.formattedLikes(photo.likes), systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.pink)
                    }

                    Label("撮影: \(photo.author)", systemImage: "camera.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
```
▶ ここで確認: カテゴリと反対側にいいね数（K表記対応）が並び、その下に「撮影: ○○」が表示されること
▶ 理解: いいねは一覧画面と同じ `viewModel.formattedLikes(_:)` を再利用する。撮影者表示のために `Photo` に `author` プロパティを追加してある（Step 1）

### 6-3: LazyVGrid の各セルを NavigationLink でラップ
```swift
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.filteredPhotos) { photo in
                        NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                            PhotoGridCell(photo: photo, viewModel: viewModel)
                        }
                    }
                }
```
▶ ここで確認: セルタップで詳細画面に遷移し、大きな画像・いいね数・撮影者が表示されること
▶ 理解: `PhotoDetailView` も `viewModel:` を渡すように呼び出し側を更新する。渡し忘れるとコンパイルエラーになるので注意

---

## 完成チェックリスト
- [ ] 2列グリッドで写真が表示される
- [ ] AsyncImage の読み込み中・成功・失敗の3状態が確認できた
- [ ] カテゴリチップで絞り込みができる（`PhotoCategory.matches(_:)` 経由）
- [ ] タップで詳細画面へ遷移し、いいね数・撮影者が表示される
- [ ] `GridItem(.flexible)` / `.fixed` / `.adaptive` の違いを試した
- [ ] `PhotoTag`（データ）と `PhotoCategory`（フィルターUI）の役割の違いを説明できる
