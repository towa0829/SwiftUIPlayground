# 09 WeatherDashboard

## 学習テーマ
- `EnvironmentObject` — 深いView階層でデータを共有する
- MVVM — Model / ViewModel / View の責務分離

## 完成イメージ
- グラデーション背景の天気ダッシュボード
- 都市切り替えで天気が変化
- 時間別・週間予報
- 湿度・風速などの詳細グリッド
- 更新ボタンで気温・湿度・風速などが実際にランダム変動する（`refreshWeather()`）

## ファイル構成
```
09_WeatherDashboard/
├── Models/
│   └── Weather.swift               # 天気データモデル全般
├── ViewModels/
│   └── WeatherViewModel.swift      # EnvironmentObjectとして共有（refreshWeatherで実際に変動）
├── App/
│   └── WeatherApp.swift            # EnvironmentObject注入ポイント
└── Views/
    ├── WeatherDashboardView.swift  # メイン画面（EnvironmentObject受け取り）
    ├── WeatherMainCard.swift       # 現在の天気メインカード
    ├── HourlyForecastRow.swift     # 時間別予報（横スクロール）
    ├── WeeklyForecastCard.swift    # 週間予報カード
    ├── WeatherDetailGrid.swift     # 湿度・風速などの詳細グリッド
    └── Components/
        ├── CityPickerView.swift    # 都市切り替えチップ（横スクロール）
        └── WeatherDetailCell.swift # 詳細グリッドの1セル
```

## セットアップ
1. Xcodeで新規 SwiftUI プロジェクト作成
2. デフォルトの `ContentView.swift` を削除
3. このフォルダのSwiftファイルを全てプロジェクトに追加
4. `@main` App struct の `body` を `WeatherAppRoot()` に変更

## 学習ポイント

### EnvironmentObject — 深い階層へのデータ共有
```
WeatherAppRoot                    ← @StateObject で生成・.environmentObject() で注入
  └── WeatherDashboardView        ← @EnvironmentObject で受け取り
        ├── CityPickerView        ← @EnvironmentObject で受け取り
        ├── WeatherMainCard       ← @EnvironmentObject で受け取り
        └── WeatherDetailGrid     ← @EnvironmentObject で受け取り
```

通常の `@ObservedObject` は親→子に1段ずつ渡す必要がある。
`EnvironmentObject` はどこからでも `@EnvironmentObject` を宣言するだけで取得できる。

### 注入と受け取り
```swift
// 注入側（親View）
struct WeatherAppRoot: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        WeatherDashboardView()
            .environmentObject(viewModel)  // 子孫全体で共有
    }
}

// 受け取り側（子・孫View）
struct WeatherDetailGrid: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    // .environmentObject() で注入されていないと実行時クラッシュ
}
```

### Previewでの注意
```swift
#Preview {
    WeatherDashboardView()
        .environmentObject(WeatherViewModel())  // Previewでも必要！
}
```
Previewに `.environmentObject()` を忘れると「No observable object of type X」クラッシュ。

### @StateObject vs @EnvironmentObject
| | @StateObject | @EnvironmentObject |
|---|---|---|
| 所有 | このViewが生成・所有 | 親が注入、参照のみ |
| 渡し方 | init引数 or 直接使用 | .environmentObject() |
| 使いどころ | ルートView | 深い階層のView |

## 発展課題
- 実際の天気API連携（OpenWeatherMap）
- `@Environment(\.locale)` で言語対応
- WidgetKit でホーム画面ウィジェット
