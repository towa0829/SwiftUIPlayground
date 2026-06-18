# 03 ProfileCard ロードマップ

完成形: グラデーションカード + フォロー機能 + 詳細シート

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Profile.swift` を新規作成

### 1-1: struct の骨格（最小限）
```swift
import Foundation
import SwiftUI

struct Profile: Identifiable {
    let id: UUID
    var name: String
    var handle: String
    var bio: String
    var accentColor: Color
    var avatarSystemImage: String
}
```

### 1-2: init + サンプルデータ
```swift
    init(id: UUID = UUID(), name: String, handle: String, bio: String,
         accentColor: Color = .blue, avatarSystemImage: String = "person.circle.fill") {
        self.id = id; self.name = name; self.handle = handle; self.bio = bio
        self.accentColor = accentColor; self.avatarSystemImage = avatarSystemImage
    }
```
```swift
extension Profile {
    static let sample = Profile(
        name: "Towa Yamamoto", handle: "@towa_dev",
        bio: "iOSエンジニア / SwiftUI愛好家 🍎",
        accentColor: .purple, avatarSystemImage: "person.crop.circle.fill"
    )
    static let samples: [Profile] = [sample, /* 他2件 */]
}
```
（フォロワー数等のフィールドは後で追加）

---

## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/ProfileViewModel.swift` を新規作成

### 2-1: フォロー状態の管理
```swift
import Foundation

class ProfileViewModel: ObservableObject {
    @Published var profiles: [Profile] = Profile.samples
    @Published var isFollowing: [UUID: Bool] = [:]

    init() {
        for profile in profiles {
            isFollowing[profile.id] = false
        }
    }

    func toggleFollow(_ profile: Profile) {
        isFollowing[profile.id, default: false].toggle()
    }

    func followStatus(for profile: Profile) -> Bool {
        isFollowing[profile.id, default: false]
    }
}
```
▶ ここで確認: ビルドエラーがないこと

---

## Step 3 — ZStack でカード背景を作る
**ファイル:** `Views/ProfileCardView.swift` を新規作成

### 3-1: ZStack の基本形（背景色だけ）
```swift
import SwiftUI

struct ProfileCardView: View {
    let profile: Profile

    var body: some View {
        // ZStack: 複数のViewを奥から手前に重ねる
        ZStack(alignment: .bottomLeading) {
            // 一番奥: グラデーション背景
            LinearGradient(
                colors: [profile.accentColor.opacity(0.8), profile.accentColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // 手前: テキスト（まだ仮）
            Text(profile.name)
                .foregroundStyle(.white)
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(height: 200)
    }
}

#Preview {
    ProfileCardView(profile: Profile.sample)
        .padding()
}
```
▶ ここで確認: Preview でグラデーション背景に名前が表示されること

### 3-2: コンテンツを VStack に整える
```swift
            // Text(profile.name) を差し替え
            VStack(alignment: .leading, spacing: 12) {
                Text(profile.name).font(.title2.bold()).foregroundStyle(.white)
                Text(profile.handle).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                Text(profile.bio).font(.caption).foregroundStyle(.white.opacity(0.9)).lineLimit(2)
            }
            .padding(20)
```
▶ ここで確認: 名前・ハンドル・bioが縦並びで表示されること

### 3-3: アバターアイコンを追加
```swift
            VStack(alignment: .leading, spacing: 12) {
                // VStack の先頭に追加
                Image(systemName: profile.avatarSystemImage)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                // ...既存のテキスト
            }
```

---

## Step 4 — overlay でフォローボタンを重ねる
**ファイル:** `Views/ProfileCardView.swift` を編集

### 4-1: ViewModel を受け取れるようにする
```swift
struct ProfileCardView: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel  // 追加
```

### 4-2: ZStack の中のアバター横にフォローボタンを追加
```swift
                HStack {
                    Image(systemName: profile.avatarSystemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        viewModel.toggleFollow(profile)
                    } label: {
                        Text(viewModel.followStatus(for: profile) ? "フォロー中" : "フォロー")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundStyle(profile.accentColor)
                            .clipShape(Capsule())
                    }
                }
```
▶ ここで確認: フォローボタンのタップでテキストが切り替わること

### 4-3: overlay で右上に infoボタンを追加
```swift
        // ZStack の外側・clipShape の後に追加
        .overlay(alignment: .topTrailing) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.white.opacity(0.8))
                .padding(12)
        }
```
▶ ここで確認: カード右上にアイコンが表示されること。ZStackとoverlay の違い（サイズに影響するかどうか）に注目

---

## Step 5 — sheet でモーダル詳細画面を表示する
**ファイル:** `Views/ProfileDetailSheet.swift` を新規作成、その後 `ProfileCardView.swift` を編集

### 5-1: ProfileDetailSheet の骨格（最小限）
```swift
import SwiftUI

struct ProfileDetailSheet: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(profile.name)
                .navigationTitle("プロフィール")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ProfileDetailSheet(profile: Profile.sample)
}
```
▶ ここで確認: Preview で名前とクローズボタンが出ること

### 5-2: ProfileCardView に @State + .sheet を追加
```swift
    // profileCardView に追加
    @State private var showDetail = false

    // overlay の直後に追加
    .sheet(isPresented: $showDetail) {
        ProfileDetailSheet(profile: profile, viewModel: viewModel)
    }
```

### 5-3: infoボタンでシートを開く
```swift
        .overlay(alignment: .topTrailing) {
            Button {
                showDetail = true  // ← ここで true にする
            } label: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(12)
            }
        }
```
▶ ここで確認: infoボタンで下からシートがスライドアップし、「閉じる」で閉じること

### 5-4: ProfileDetailSheet の中身を充実させる
```swift
            ScrollView {
                VStack(spacing: 24) {
                    // ZStack でバナー + アバターを重ねる（Step 3の復習）
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(profile.accentColor.gradient)
                            .frame(height: 120)
                        Image(systemName: profile.avatarSystemImage)
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .background(Circle().fill(profile.accentColor).frame(width: 100, height: 100))
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .offset(y: 40)
                    }
                    .padding(.bottom, 40)

                    Text(profile.name).font(.title2.bold())
                    Text(profile.handle).foregroundStyle(.secondary)
                    Text(profile.bio).multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
```
▶ ここで確認: シート内でバナー＋アバターの重なりが表示されること

---

## Step 6 — カード一覧画面を作る
**ファイル:** `Views/ProfileListView.swift` を新規作成

### 6-1: ScrollView + VStack でカードを並べる
```swift
import SwiftUI

struct ProfileListView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.profiles) { profile in
                        ProfileCardView(profile: profile, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("プロフィール")
        }
    }
}

#Preview { ProfileListView() }
```
▶ ここで確認: 3枚のカードが縦に並んでいること。フォロー状態が全カードで共有されること

---

## 完成チェックリスト
- [ ] ZStack でグラデーション背景 + テキストが重なっている
- [ ] overlay でカード上にフォローボタンとinfoアイコンが重なっている
- [ ] フォローボタンのタップで状態が切り替わる
- [ ] infoボタンで下からシートが開く
- [ ] シート内に @Environment(\.dismiss) で閉じるボタンが動く
- [ ] 3枚のカードがScrollViewに並んでいる

---

## 改良ノート（写経後の修正）
- 未使用だった `@Published var selectedProfile` と、`isFollowing` の重複初期化を削除。
- bio・統計ラベルが `.caption`/`.caption2` で小さすぎたため `.subheadline`/`.footnote` に昇格。
- カードと詳細シートで重複していた統計表示用Viewを `Views/Components/ProfileStatView.swift` に統合。
