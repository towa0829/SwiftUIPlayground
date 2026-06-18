# 04 PhotoGallery ロードマップ

完成形: カテゴリフィルター付き2列グリッド + 非同期画像読み込み

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Photo.swift` を新規作成

### 1-1: カテゴリ enum
```swift
import Foundation

enum PhotoCategory: String, CaseIterable, Identifiable {
    case all      = "すべて"
    case nature   = "自然"
    case city     = "都市"
    case food     = "食べ物"
    case travel   = "旅行"

    var id: String { rawValue }
}
```

### 1-2: Photo struct + サンプルデータ
```swift
struct Photo: Identifiable {
    let id: UUID
    let title: String
    let category: PhotoCategory
    let imageURL: URL
    let likes: Int

    init(id: UUID = UUID(), title: String, category: PhotoCategory,
         imageURLString: String, likes: Int = 0) {
        self.id = id; self.title = title; self.category = category
        self.imageURL = URL(string: imageURLString)!
        self.likes = likes
    }
}

extension Photo {
    static let samples: [Photo] = [
        Photo(title: "山の夕暮れ", category: .nature,
              imageURLString: "https://picsum.photos/seed/mtn1/400/400", likes: 234),
        Photo(title: "夜の渋谷",  category: .city,
              imageURLString: "https://picsum.photos/seed/city1/400/400", likes: 512),
        Photo(title: "ラーメン",  category: .food,
              imageURLString: "https://picsum.photos/seed/ramen/400/400", likes: 671),
        Photo(title: "京都の神社", category: .travel,
              imageURLString: "https://picsum.photos/seed/kyoto/400/400", likes: 923),
        // ...必要なだけ追加
    ]
}
```
▶ ここで確認: `Photo.samples.count` が期待通りの件数であること

---

## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/PhotoViewModel.swift` を新規作成

### 2-1: フィルタリングロジック
```swift
import Foundation

class PhotoViewModel: ObservableObject {
    @Published var allPhotos: [Photo] = Photo.samples
    @Published var selectedCategory: PhotoCategory = .all

    // selectedCategory が変わると自動的に再計算される computed property
    var filteredPhotos: [Photo] {
        if selectedCategory == .all { return allPhotos }
        return allPhotos.filter { $0.category == selectedCategory }
    }
}
```
▶ ここで確認: `selectedCategory = .nature` にすると自然写真だけが返ること

---

## Step 3 — AsyncImage でセルを作る
**ファイル:** `Views/PhotoGridCell.swift` を新規作成

### 3-1: AsyncImage の最小形
```swift
import SwiftUI

struct PhotoGridCell: View {
    let photo: Photo

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
    PhotoGridCell(photo: Photo.samples[0])
}
```
▶ ここで確認: Preview で画像が表示されること（初回は時間がかかる）

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

### 3-3: いいね数のオーバーレイを追加
```swift
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: photo.imageURL) { ... }
                .frame(minHeight: 150, maxHeight: 150)
                .clipped()

            // 半透明バッジ
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.caption2)
                Text("\(photo.likes)").font(.caption2.bold())
            }
            .foregroundStyle(.white)
            .padding(6)
            .background(.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
        }
        .aspectRatio(1, contentMode: .fit)
    }
```

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
                        PhotoGridCell(photo: photo)
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
**ファイル:** `Views/PhotoGalleryView.swift` を編集

### 5-1: カテゴリチップ用の子View
```swift
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
```

### 5-2: PhotoGalleryView の ScrollView の上にフィルターを追加
```swift
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 横スクロールのカテゴリフィルター
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
                    .padding(.horizontal).padding(.vertical, 8)
                }

                // 既存のグリッドScrollView
                ScrollView { ... }
            }
            .navigationTitle("フォトギャラリー")
        }
    }
```
▶ ここで確認: チップタップで写真が絞り込まれること

---

## Step 6 — 詳細画面と NavigationLink を繋ぐ
**ファイル:** `Views/PhotoDetailView.swift` を新規作成、その後 `PhotoGalleryView.swift` を編集

### 6-1: 詳細画面（大きな AsyncImage）
```swift
import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: photo.imageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .empty: ProgressView().frame(height: 300)
                    default: Color.gray.frame(height: 300)
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

### 6-2: LazyVGrid の各セルを NavigationLink でラップ
```swift
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.filteredPhotos) { photo in
                        NavigationLink(destination: PhotoDetailView(photo: photo)) {
                            PhotoGridCell(photo: photo)
                        }
                    }
                }
```
▶ ここで確認: セルタップで詳細画面に遷移し、大きな画像が表示されること

---

## 完成チェックリスト
- [ ] 2列グリッドで写真が表示される
- [ ] AsyncImage の読み込み中・成功・失敗の3状態が確認できた
- [ ] カテゴリチップで絞り込みができる
- [ ] タップで詳細画面へ遷移する
- [ ] `GridItem(.flexible)` / `.fixed` / `.adaptive` の違いを試した
