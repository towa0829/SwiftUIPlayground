# 03 ProfileCard ロードマップ

完成形: グラデーションカード + 統計表示 + フォロー機能 + 詳細シート

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
    var location: String
    var website: String
    var followersCount: Int
    var followingCount: Int
    var postsCount: Int
    var accentColor: Color
    var avatarSystemImage: String
}
```
プロフィールカードには「投稿数」「フォロワー数」「フォロー中数」を表示したいので、
最初から `followersCount` などの数値フィールドと、詳細画面用の `location`・`website` を持たせておく。

### 1-2: init + サンプルデータ
```swift
    init(
        id: UUID = UUID(),
        name: String,
        handle: String,
        bio: String,
        location: String = "",
        website: String = "",
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        accentColor: Color = .blue,
        avatarSystemImage: String = "person.circle.fill"
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.bio = bio
        self.location = location
        self.website = website
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.accentColor = accentColor
        self.avatarSystemImage = avatarSystemImage
    }
```
`location`・`website`・各カウントにデフォルト値を与えることで、サンプルデータ側で
省略したいフィールドを省略できるようにする。

```swift
extension Profile {
    static let sample = Profile(
        name: "Towa Yamamoto",
        handle: "@towa_dev",
        bio: "iOSエンジニア / SwiftUI愛好家 🍎\nオープンソース活動中",
        location: "Tokyo, Japan",
        website: "https://example.com",
        followersCount: 1_204,
        followingCount: 387,
        postsCount: 82,
        accentColor: .purple,
        avatarSystemImage: "person.crop.circle.fill"
    )

    static let samples: [Profile] = [
        sample,
        Profile(
            name: "Hana Tanaka",
            handle: "@hana_design",
            bio: "UIデザイナー & SwiftUI修行中 ✏️",
            location: "Osaka, Japan",
            followersCount: 543,
            followingCount: 210,
            postsCount: 34,
            accentColor: .pink,
            avatarSystemImage: "person.crop.circle.fill.badge.checkmark"
        ),
        Profile(
            name: "Kenji Suzuki",
            handle: "@kenji_backend",
            bio: "バックエンドエンジニア | Swift Server-Side",
            location: "Fukuoka, Japan",
            followersCount: 2_891,
            followingCount: 150,
            postsCount: 195,
            accentColor: .green,
            avatarSystemImage: "person.crop.circle.badge.fill"
        ),
    ]
}
```
2件目・3件目のサンプルは `website` を省略している（デフォルト値 `""` が使われる）。

---

## Step 2 — ViewModel を作る
**ファイル:** `ViewModels/ProfileViewModel.swift` を新規作成

### 2-1: フォロー状態の管理
```swift
import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profiles: [Profile] = Profile.samples
    @Published var isFollowing: [UUID: Bool] = [:]

    func toggleFollow(_ profile: Profile) {
        isFollowing[profile.id, default: false].toggle()
    }

    func followStatus(for profile: Profile) -> Bool {
        isFollowing[profile.id, default: false]
    }
}
```
`@Published` プロパティを使うクラスなので `Combine` を import する（`ObservableObject` 自体は
Combine の仕組みの上に乗っている）。

`isFollowing` は辞書のデフォルト値付きsubscript `[profile.id, default: false]` を使うことで、
初期化時に全プロフィール分のエントリを作っておく必要がなくなる。まだキーが存在しない
プロフィールに対しても `false` が返るため、`init` でループして初期値を詰める処理は不要。

### 2-2: 数値を見やすい文字列に変換する
```swift
    func formattedCount(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fK", k)
        }
        return "\(count)"
    }
}
```
`1204` のような数値をそのまま表示すると窮屈なので、1000以上は `1.2K` のように
小数点1桁 + `K` サフィックスへ変換するヘルパーを用意する。カードと詳細シート両方の
統計表示から呼び出す。

▶ ここで確認: ビルドエラーがないこと

---

## Step 3 — 統計表示用コンポーネントを作る
**ファイル:** `Views/Components/ProfileStatView.swift` を新規作成

カードと詳細シートの両方で「数値 + ラベル」を縦に並べる統計表示が必要になる。
先に共通コンポーネントとして切り出しておくことで、Step 4・5で重複コードを書かずに済む。

### 3-1: value/title を縦並びにする
```swift
import SwiftUI

/// 「投稿」「フォロワー」などの統計値を value/title の縦並びで表示する共通コンポーネント。
/// カード(白文字onグラデーション)と詳細画面(primary/secondary)の両方から見た目を調整して使う。
struct ProfileStatView: View {
    let value: String
    let title: String
    var valueFont: Font = .subheadline.bold()
    var titleFont: Font = .footnote
    var valueColor: Color = .primary
    var titleColor: Color = .secondary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ProfileStatView(value: "82", title: "投稿")
        ProfileStatView(value: "1.2K", title: "フォロワー", valueColor: .white, titleColor: .white.opacity(0.7))
            .padding()
            .background(Color.purple)
    }
}
```
フォント・色をデフォルト引数にしておくことで、呼び出し側は変えたいプロパティだけ
上書きできる（例: カードの上では白文字にしたいので `valueColor: .white` を渡す）。

▶ ここで確認: Preview で2つの統計表示が並び、片方は紫背景に白文字で見えること

---

## Step 4 — ZStack でカード背景を作る
**ファイル:** `Views/ProfileCardView.swift` を新規作成

### 4-1: ZStack の基本形（背景色だけ）
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

### 4-2: コンテンツを VStack に整える
```swift
            // Text(profile.name) を差し替え
            VStack(alignment: .leading, spacing: 12) {
                Text(profile.name).font(.title2.bold()).foregroundStyle(.white)
                Text(profile.handle).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                Text(profile.bio).font(.subheadline).foregroundStyle(.white.opacity(0.9)).lineLimit(2)
            }
            .padding(20)
```
bio は `.caption` だと小さすぎて読みにくいため `.subheadline` を使う。

▶ ここで確認: 名前・ハンドル・bioが縦並びで表示されること

### 4-3: アバターアイコンを追加
```swift
            VStack(alignment: .leading, spacing: 12) {
                // VStack の先頭に追加
                Image(systemName: profile.avatarSystemImage)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                // ...既存のテキスト
            }
```

---

## Step 5 — overlay でフォローボタンを重ねる
**ファイル:** `Views/ProfileCardView.swift` を編集

### 5-1: ViewModel を受け取れるようにする
```swift
struct ProfileCardView: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel  // 追加
```

### 5-2: アバター横にフォローボタンを追加
```swift
                HStack {
                    Image(systemName: profile.avatarSystemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)

                    Spacer()

                    // フォローボタン
                    Button {
                        viewModel.toggleFollow(profile)
                    } label: {
                        Text(viewModel.followStatus(for: profile) ? "フォロー中" : "フォロー")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.followStatus(for: profile) ? Color.white.opacity(0.3) : Color.white)
                            .foregroundStyle(viewModel.followStatus(for: profile) ? .white : profile.accentColor)
                            .clipShape(Capsule())
                    }
                }
```
フォロー中は背景を半透明の白、文字を白にすることで「フォロー」ボタンと見た目を変え、
状態の違いが一目で分かるようにする。

▶ ここで確認: フォローボタンのタップでテキストと見た目が切り替わること

### 5-3: 統計表示（ProfileStatView）を追加
```swift
                // フォロワー統計
                HStack(spacing: 20) {
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.postsCount),
                        title: "投稿",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.followersCount),
                        title: "フォロワー",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                    ProfileStatView(
                        value: viewModel.formattedCount(profile.followingCount),
                        title: "フォロー中",
                        valueColor: .white,
                        titleColor: .white.opacity(0.7)
                    )
                }
```
bio の下に追加する。Step 3 で作った `ProfileStatView` をそのまま使い、グラデーション背景に
合わせて `valueColor`/`titleColor` を白系に上書きする。

▶ ここで確認: bioの下に投稿・フォロワー・フォロー中の3つの数値が並ぶこと

### 5-4: overlay で右上に infoボタンを追加
```swift
        // ZStack の外側・clipShape の後に追加
        .shadow(color: profile.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.white.opacity(0.8))
                .padding(12)
        }
```
▶ ここで確認: カード右上にアイコンが表示されること。ZStackとoverlay の違い（サイズに影響するかどうか）に注目

---

## Step 6 — sheet でモーダル詳細画面を表示する
**ファイル:** `Views/ProfileDetailSheet.swift` を新規作成、その後 `ProfileCardView.swift` を編集

### 6-1: ProfileDetailSheet の骨格（最小限）
```swift
import SwiftUI

struct ProfileDetailSheet: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(profile.name)
                .navigationTitle("プロフィール")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ProfileDetailSheet(profile: Profile.sample, viewModel: ProfileViewModel())
}
```
カードと同じ `viewModel` を渡すことで、詳細画面のフォローボタンとカードのフォローボタンの
状態を共有できるようにしておく。

▶ ここで確認: Preview で名前とクローズボタンが出ること

### 6-2: ProfileCardView に @State + .sheet を追加
```swift
    // ProfileCardView に追加
    @State private var showDetail = false

    // overlay の直後に追加
    .sheet(isPresented: $showDetail) {
        ProfileDetailSheet(profile: profile, viewModel: viewModel)
    }
```

### 6-3: infoボタンでシートを開く
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

### 6-4: バナー + アバターのヘッダーを作る
```swift
struct ProfileDetailSheet: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    /// アバターをバナーの下端に半分だけ重ねて表示するためのサイズ。
    /// offsetとpaddingはこの値から導出し、マジックナンバーを避ける。
    private let avatarDiameter: CGFloat = 100

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー (ZStack + overlay の組み合わせ)
                    ZStack(alignment: .bottom) {
                        // バナー背景
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [profile.accentColor, profile.accentColor.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 120)

                        // アバター (バナー下端から半分だけ突き出すように重ねる)
                        Image(systemName: profile.avatarSystemImage)
                            .font(.system(size: avatarDiameter * 0.8))
                            .foregroundStyle(.white)
                            .background(Circle().fill(profile.accentColor).frame(width: avatarDiameter, height: avatarDiameter))
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .offset(y: avatarDiameter / 2)
                    }
                    .padding(.bottom, avatarDiameter / 2)
                    // ...続きは次のステップ
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
```
`80`・`100`・`40` のような数値を直接書く代わりに `avatarDiameter` 定数を1つ置き、
オフセットやフォントサイズをそこから計算する（`avatarDiameter / 2` など）。
こうすると後でアバターサイズを変えたいときに1箇所だけ直せばよい。

▶ ここで確認: シート内でバナー＋アバターの重なりが表示されること

### 6-5: 名前・統計・位置情報・フォローボタンを追加
```swift
                    // プロフィール情報
                    VStack(spacing: 8) {
                        Text(profile.name)
                            .font(.title2.bold())
                        Text(profile.handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(profile.bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // 統計
                    HStack(spacing: 32) {
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.postsCount),
                            title: "投稿",
                            valueFont: .title3.bold()
                        )
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.followersCount),
                            title: "フォロワー",
                            valueFont: .title3.bold()
                        )
                        ProfileStatView(
                            value: viewModel.formattedCount(profile.followingCount),
                            title: "フォロー中",
                            valueFont: .title3.bold()
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // 詳細情報
                    VStack(alignment: .leading, spacing: 12) {
                        if !profile.location.isEmpty {
                            Label(profile.location, systemImage: "mappin.circle.fill")
                        }
                        if !profile.website.isEmpty {
                            Label(profile.website, systemImage: "link.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // フォローボタン
                    Button {
                        viewModel.toggleFollow(profile)
                    } label: {
                        Text(viewModel.followStatus(for: profile) ? "フォロー中" : "フォローする")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.followStatus(for: profile) ? Color.secondary.opacity(0.2) : profile.accentColor)
                            .foregroundStyle(viewModel.followStatus(for: profile) ? .primary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
```
ヘッダーの直後に追加する。統計はカードと同じ `ProfileStatView` を使うが、ここでは
カード版より大きな `valueFont: .title3.bold()` を渡し、色はデフォルト（primary/secondary）
のままにする。

`location`/`website` は空文字の場合は表示しないよう `if !profile.location.isEmpty` などで
ガードする（Step 1で `""` をデフォルト値にしたのはこのため）。

フォローボタンはカードのフォローボタンと同じ `viewModel` を操作するため、シートを
開いたままタップしてもカード側の表示と状態が一致する。

▶ ここで確認: 統計・位置情報・リンク・フォローボタンが表示され、フォローボタンがカードと連動して切り替わること

---

## Step 7 — カード一覧画面を作る
**ファイル:** `Views/ProfileListView.swift` を新規作成

### 7-1: ScrollView + VStack でカードを並べる
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
- [ ] `Profile` が `location`/`website`/3つのカウントを持っている
- [ ] `ProfileViewModel.formattedCount` が1000以上の数値を `1.2K` のように整形する
- [ ] `ProfileStatView` がカードと詳細シートの両方から使われている（重複なし）
- [ ] ZStack でグラデーション背景 + テキスト + 統計表示が重なっている
- [ ] overlay でカード上にフォローボタンとinfoアイコンが重なっている
- [ ] フォローボタンのタップで状態が切り替わり、カードと詳細シートで連動する
- [ ] infoボタンで下からシートが開き、バナー＋アバター＋統計＋位置情報が表示される
- [ ] シート内に @Environment(\.dismiss) で閉じるボタンが動く
- [ ] 3枚のカードがScrollViewに並んでいる
