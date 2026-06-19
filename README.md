# SwiftUI 写経学習教材

SwiftUIを実践的に学ぶための10教材セット。
各教材は独立して動作し、1〜3時間で完成できる規模です。

## 各教材の使い方

1. Xcodeで **新規 SwiftUI プロジェクト** を作成
2. 教材フォルダの Swift ファイルをプロジェクトに追加
3. 各教材の `README.md` の「セットアップ」に従い起動ポイントを設定
4. **`ROADMAP.md` を開いて Step 1 から順に写経していく**
5. 各 Step の末尾にある「▶ ここで確認」で動作を確認してから次へ進む

## 各教材のファイル構成

各教材フォルダには以下の2つのドキュメントがあります。

| ファイル | 内容 |
|---|---|
| `README.md` | 学習テーマの解説・APIの使い方・発展課題 |
| `ROADMAP.md` | **どのファイルのどの部分を、どの順で書くかの手順書** |

## 教材一覧

| # | 教材 | 学習テーマ | 推定時間 |
|---|------|-----------|---------|
| 01 | [TodoApp](01_TodoApp/) | `List` / `NavigationStack` / `SwipeActions` / `SwiftData` | 1〜2h |
| 02 | [SettingsApp](02_SettingsApp/) | `Form` / `Toggle` / `Picker` / `AppStorage` | 1〜2h |
| 03 | [ProfileCard](03_ProfileCard/) | `ZStack` / `overlay` / `Sheet` | 1〜2h |
| 04 | [PhotoGallery](04_PhotoGallery/) | `ScrollView` / `LazyVGrid` / `AsyncImage` | 1〜2h |
| 05 | [TabSNS](05_TabSNS/) | `TabView` / `NavigationStack` | 2〜3h |
| 06 | [PostModal](06_PostModal/) | `Sheet` / `FullScreenCover` / `@Binding` | 1〜2h |
| 07 | [HabitTracker](07_HabitTracker/) | `ObservableObject` / `@StateObject` / `ProgressView` / `SwiftData` | 2〜3h |
| 08 | [ProductSearch](08_ProductSearch/) | `.searchable` / フィルタリング | 1〜2h |
| 09 | [WeatherDashboard](09_WeatherDashboard/) | `EnvironmentObject` / MVVM | 2〜3h |
| 10 | [AnimatedFavorite](10_AnimatedFavorite/) | `Animation` / `matchedGeometryEffect` | 2〜3h |

## 推奨学習順序

```
01 → 02 → 03   基礎（List / Form / ZStack）
04 → 05         レイアウト応用（Grid / TabView）
06 → 07         状態管理（Sheet / ObservableObject）
08 → 09 → 10   発展（Search / EnvironmentObject / Animation）
```

## MVVM 構成（全教材共通）

```
教材名/
├── Models/         # データの形（struct、またはSwiftData永続化対象は@Model final class）
├── ViewModels/     # ビジネスロジック（ObservableObject）
├── Views/          # 画面UI（SwiftUI View）
├── README.md       # テーマ解説・APIリファレンス・発展課題
└── ROADMAP.md      # 写経の手順書（何をどの順で書くか）
```

> 01 (TodoApp) と 07 (HabitTracker) はSwiftDataで永続化しているため、`Models/` 配下のデータ定義は `@Model final class` になっている（他の教材は `struct`）。
