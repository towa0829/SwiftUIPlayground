# 09 WeatherDashboard ロードマップ

完成形: EnvironmentObject で深い階層にデータを渡すMVVMパターン

---

## Step 1 — データモデルを作る
**ファイル:** `Models/Weather.swift` を新規作成

### 1-1: WeatherType enum
```swift
import Foundation
import SwiftUI

enum WeatherType: String {
    case sunny       = "晴れ"
    case cloudy      = "曇り"
    case rainy       = "雨"
    case snowy       = "雪"
    case partlyCloudy = "晴れ時々曇り"

    var icon: String {
        switch self {
        case .sunny:        return "sun.max.fill"
        case .cloudy:       return "cloud.fill"
        case .rainy:        return "cloud.rain.fill"
        case .snowy:        return "cloud.snow.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .sunny:        return [Color(red: 0.25, green: 0.6, blue: 0.95), Color(red: 0.4, green: 0.75, blue: 1.0)]
        case .cloudy:       return [Color(red: 0.55, green: 0.6, blue: 0.7),  Color(red: 0.7, green: 0.74, blue: 0.82)]
        case .rainy:        return [Color(red: 0.3,  green: 0.4, blue: 0.55), Color(red: 0.4, green: 0.5,  blue: 0.65)]
        case .snowy:        return [Color(red: 0.55, green: 0.7, blue: 0.85), Color(red: 0.75, green: 0.85, blue: 0.95)]
        case .partlyCloudy: return [Color(red: 0.3,  green: 0.55, blue: 0.85), Color(red: 0.55, green: 0.72, blue: 0.92)]
        }
    }
}
```

### 1-2: WeatherCondition + HourlyForecast + DailyForecast
```swift
struct HourlyForecast: Identifiable {
    let id = UUID()
    let hour: String
    let temperature: Double
    let condition: WeatherType
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let dayName: String
    let condition: WeatherType
    let highTemp: Double
    let lowTemp: Double
}

struct WeatherCondition: Identifiable {
    let id: UUID
    let cityName: String
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let condition: WeatherType
    let hourlyForecast: [HourlyForecast]
    let weeklyForecast: [DailyForecast]

    var formattedTemp: String { "\(Int(temperature))°" }
    var backgroundColors: [Color] { condition.backgroundColors }
}
```

### 1-3: サンプルデータ（東京・大阪・札幌）
```swift
extension WeatherCondition {
    static let samples: [WeatherCondition] = [
        WeatherCondition(
            id: UUID(), cityName: "東京", temperature: 22, feelsLike: 20,
            humidity: 62, windSpeed: 3.5, condition: .partlyCloudy,
            hourlyForecast: [
                HourlyForecast(hour: "今", temperature: 22, condition: .partlyCloudy),
                HourlyForecast(hour: "13時", temperature: 24, condition: .sunny),
                // ...
            ],
            weeklyForecast: [ /* ... */ ]
        ),
        // 大阪・札幌も同様に
    ]
}
```
▶ ここで確認: `WeatherCondition.samples.count == 3` であること

---

## Step 2 — WeatherViewModel (ObservableObject) を作る
**ファイル:** `ViewModels/WeatherViewModel.swift` を新規作成

```swift
import Foundation
import Combine

// EnvironmentObject として子Viewに注入する ObservableObject
class WeatherViewModel: ObservableObject {
    @Published var weatherList: [WeatherCondition] = WeatherCondition.samples
    @Published var selectedCity: WeatherCondition

    init() {
        self.selectedCity = WeatherCondition.samples[0]
    }

    func selectCity(_ city: WeatherCondition) {
        selectedCity = city
    }

    func formattedHumidity(_ value: Int) -> String { "\(value)%" }
    func formattedWind(_ value: Double) -> String { String(format: "%.1f m/s", value) }
}
```
▶ ここで確認: ビルドエラーがないこと

---

## Step 3 — EnvironmentObject の注入ポイントを作る（超重要）
**ファイル:** `App/WeatherApp.swift` を新規作成

### 3-1: 注入の仕組みを理解する前に図解
```
WeatherAppRoot            ← @StateObject で生成 → .environmentObject() で注入
  └── WeatherDashboardView ← @EnvironmentObject で受け取り（引数不要！）
        ├── CityPickerView ← @EnvironmentObject で受け取り
        ├── WeatherMainCard ← @EnvironmentObject で受け取り
        └── WeatherDetailGrid ← @EnvironmentObject で受け取り
```

### 3-2: WeatherAppRoot を書く
```swift
import SwiftUI

struct WeatherAppRoot: View {
    // @StateObject: このViewがViewModelを所有する
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        WeatherDashboardView()
            // .environmentObject: 子孫View全体でviewModelを共有する
            // どんなに深い階層でも @EnvironmentObject で受け取れる
            .environmentObject(viewModel)
    }
}

#Preview {
    WeatherAppRoot()
}
```
▶ 理解: 通常の `@ObservedObject` は親 → 子 → 孫と1段ずつ渡す必要がある。
`EnvironmentObject` は注入した瞬間から全子孫が使える。

---

## Step 4 — WeatherDashboardView (@EnvironmentObject を受け取る)
**ファイル:** `Views/WeatherDashboardView.swift` を新規作成

### 4-1: @EnvironmentObject の最小形
```swift
import SwiftUI

struct WeatherDashboardView: View {
    // @EnvironmentObject: .environmentObject() で注入されていないと実行時クラッシュ！
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(viewModel.selectedCity.cityName)
                        .font(.title)
                    Text(viewModel.selectedCity.formattedTemp)
                        .font(.system(size: 80, weight: .thin))
                }
                .foregroundStyle(.white)
                .padding()
            }
            .background(Color.blue.gradient.ignoresSafeArea())
            .navigationTitle("天気")
        }
    }
}

// ⚠️ Previewでも .environmentObject() が必要！
#Preview {
    WeatherDashboardView()
        .environmentObject(WeatherViewModel())
}
```
▶ ここで確認: Preview に .environmentObject() を忘れるとクラッシュすることを体感する

### 4-2: グラデーション背景を天気に連動させる
```swift
            .background(
                LinearGradient(
                    colors: viewModel.selectedCity.backgroundColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
```
▶ ここで確認: 都市切り替えで背景色が変わること（次ステップで都市切替を実装）

---

## Step 5 — 子コンポーネントを作る（各コンポーネントも @EnvironmentObject）
**ファイル:** `Views/WeatherCardView.swift` を新規作成

### 5-1: 都市選択コンポーネント（CityPickerView）
```swift
import SwiftUI

struct CityPickerView: View {
    // 親から引数で受け取らない。EnvironmentObjectで直接アクセスする。
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.weatherList) { city in
                    Button {
                        viewModel.selectCity(city)
                    } label: {
                        Text(city.cityName)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(
                                viewModel.selectedCity.id == city.id
                                ? Color.white.opacity(0.3)
                                : Color.white.opacity(0.1)
                            )
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
```
▶ 理解: `CityPickerView` は `viewModel` を init引数で受け取っていない。
`@EnvironmentObject` で親が注入したものを直接使っている。

### 5-2: 時間別予報（HourlyForecastRow）
```swift
struct HourlyForecastRow: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.selectedCity.hourlyForecast) { forecast in
                    VStack(spacing: 8) {
                        Text(forecast.hour).font(.caption).foregroundStyle(.white.opacity(0.8))
                        Image(systemName: forecast.condition.icon)
                            .symbolRenderingMode(.multicolor)
                        Text("\(Int(forecast.temperature))°").font(.subheadline.bold()).foregroundStyle(.white)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

### 5-3: WeatherDashboardView に全コンポーネントを追加する
```swift
            ScrollView {
                VStack(spacing: 20) {
                    CityPickerView()      // ← 引数なし！
                    // メイン温度表示...
                    HourlyForecastRow()   // ← 引数なし！
                    WeeklyForecastCard()  // ← 引数なし！
                    WeatherDetailGrid()   // ← 引数なし！
                }
                .padding()
            }
```
▶ ここで確認: 全コンポーネントが引数なしで配置でき、都市選択で全体が更新されること

---

## 完成チェックリスト
- [ ] .environmentObject() の注入場所（WeatherAppRoot）を理解した
- [ ] @EnvironmentObject を使う子Viewは init引数でViewModelを受け取らない
- [ ] Previewに .environmentObject() を忘れるとクラッシュすることを確認した
- [ ] 都市切り替えで全コンポーネントが同時に更新される
- [ ] @StateObject（所有）/@ObservedObject（参照）/@EnvironmentObject（環境から取得）の3つを使い分けられるようになった

---

## 改良ノート（写経後の修正）
- **`refreshWeather()` が no-op だったバグを修正**: `objectWillChange.send()` だけで実際の値が変わらなかった処理を、気温・体感温度・湿度・風速を実際にランダム変動させる実装に変更。
- 横スクロール（都市選択・時間別予報）の内容に `.padding(.horizontal)` を付け、端が画面端に張り付かないように修正。
- 多数のstructが同居していた `WeatherCardView.swift`（4 struct）/`WeatherDashboardView.swift`（3 struct）を分割し、`HourlyForecastRow`/`WeeklyForecastCard`/`WeatherDetailGrid`/`WeatherMainCard` と `Views/Components/{WeatherDetailCell,CityPickerView}` へ整理。
