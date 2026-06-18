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
    case sunny = "晴れ"
    case cloudy = "曇り"
    case rainy = "雨"
    case snowy = "雪"
    case stormy = "嵐"
    case partlyCloudy = "晴れ時々曇り"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .sunny: return [Color(red: 0.25, green: 0.6, blue: 0.95), Color(red: 0.4, green: 0.75, blue: 1.0)]
        case .cloudy: return [Color(red: 0.55, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.74, blue: 0.82)]
        case .rainy: return [Color(red: 0.3, green: 0.4, blue: 0.55), Color(red: 0.4, green: 0.5, blue: 0.65)]
        case .snowy: return [Color(red: 0.55, green: 0.7, blue: 0.85), Color(red: 0.75, green: 0.85, blue: 0.95)]
        case .stormy: return [Color(red: 0.2, green: 0.25, blue: 0.38), Color(red: 0.35, green: 0.4, blue: 0.52)]
        case .partlyCloudy: return [Color(red: 0.3, green: 0.55, blue: 0.85), Color(red: 0.55, green: 0.72, blue: 0.92)]
        }
    }
}
```
`stormy`（嵐）も用意しておく。雪国の時間別予報で雪→嵐→雪と切り替わる表現に使う。

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

    init(
        id: UUID = UUID(),
        cityName: String,
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        condition: WeatherType,
        hourlyForecast: [HourlyForecast] = [],
        weeklyForecast: [DailyForecast] = []
    ) {
        self.id = id
        self.cityName = cityName
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.condition = condition
        self.hourlyForecast = hourlyForecast
        self.weeklyForecast = weeklyForecast
    }

    var formattedTemp: String { "\(Int(temperature))°" }
    var backgroundColors: [Color] { condition.backgroundColors }
}
```
`id` にデフォルト値 `UUID()` を与えるカスタム`init`にしておく。これは見た目のためではなく、
Step 2で実装する「天気の更新」処理のための準備: 更新時は新しい`WeatherCondition`を作り直すが、
`id`だけは元の値を明示的に渡して維持し、`hourlyForecast`/`weeklyForecast`は省略して空配列の
デフォルト値に頼れるようにする。

### 1-3: サンプルデータ（東京・大阪・札幌）
```swift
extension WeatherCondition {
    static let samples: [WeatherCondition] = [
        WeatherCondition(
            cityName: "東京",
            temperature: 22, feelsLike: 20,
            humidity: 62, windSpeed: 3.5, condition: .partlyCloudy,
            hourlyForecast: [
                HourlyForecast(hour: "今", temperature: 22, condition: .partlyCloudy),
                HourlyForecast(hour: "13時", temperature: 24, condition: .sunny),
                // ...
            ],
            weeklyForecast: [ /* ... */ ]
        ),
        // 大阪も同様に
        WeatherCondition(
            cityName: "札幌",
            temperature: 8, feelsLike: 5,
            humidity: 78, windSpeed: 6.2, condition: .snowy,
            hourlyForecast: [
                HourlyForecast(hour: "今", temperature: 8, condition: .snowy),
                HourlyForecast(hour: "15時", temperature: 5, condition: .stormy),
                HourlyForecast(hour: "16時", temperature: 4, condition: .stormy),
                // ...
            ],
            weeklyForecast: [ /* ... */ ]
        ),
    ]
}
```
札幌の時間別予報に `.stormy` を混ぜておくと、Step 5のアイコン表示で6種類すべてを
一度に確認できる。

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

### 2-2: 天気を更新する（refreshWeather）
```swift
    // シミュレーション: 天気を更新（実際はAPIコール）
    // WeatherCondition のプロパティは let なので、新しい値で作り直して置き換える。
    // id は維持し、温度/体感温度/湿度/風速だけを小さくランダム変動させる。
    private func randomized(_ city: WeatherCondition) -> WeatherCondition {
        let newTemperature: Double = city.temperature + Double.random(in: -3...3)
        let newFeelsLike: Double = city.feelsLike + Double.random(in: -3...3)
        let newHumidity: Int = min(100, max(0, city.humidity + Int.random(in: -5...5)))
        let newWindSpeed: Double = max(0, city.windSpeed + Double.random(in: -1...1))
        return WeatherCondition(
            id: city.id,
            cityName: city.cityName,
            temperature: newTemperature,
            feelsLike: newFeelsLike,
            humidity: newHumidity,
            windSpeed: newWindSpeed,
            condition: city.condition,
            hourlyForecast: city.hourlyForecast,
            weeklyForecast: city.weeklyForecast
        )
    }

    func refreshWeather() {
        weatherList = weatherList.map(randomized)
        // 選択中の都市も最新のインスタンスへ差し替える
        if let updated = weatherList.first(where: { $0.id == selectedCity.id }) {
            selectedCity = updated
        }
    }
```
`objectWillChange.send()` を呼ぶだけでは実際の値は変わらない。`WeatherCondition`のプロパティは
`let`なので、各都市について新しいインスタンスを作り直して`weatherList`を置き換える必要がある。
`id`だけ元の値を渡すことで、`selectedCity`との突き合わせ（`first(where:)`）が機能する。

▶ ここで確認: `refreshWeather()` を呼ぶと気温・湿度・風速が毎回少しずつ変わること（Step 4の
更新ボタンで確認する）

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

### 4-2: グラデーション背景を天気に連動させる + ツールバーに更新ボタンを追加
```swift
            .background(
                LinearGradient(
                    colors: viewModel.selectedCity.backgroundColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("天気")
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーの文字色も白系にする（背景がグラデーションのため）
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refreshWeather()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                }
            }
```
更新ボタンは Step 2-2 で作った `refreshWeather()` を呼ぶだけ。`weatherList`/`selectedCity` が
`@Published` なので、値が変わると画面全体が再描画される。

▶ ここで確認: 都市切り替えで背景色が変わること。更新ボタンをタップすると気温が変わること

---

## Step 5 — 子コンポーネントをファイルごとに分割する
ひとつのファイルに複数structを書くと見通しが悪くなるため、コンポーネントごとに
ファイルを分ける。すべて `@EnvironmentObject` で `WeatherViewModel` を受け取るので、
親から引数を渡す必要はない。

### 5-1: 都市選択（`Views/Components/CityPickerView.swift`）
```swift
import SwiftUI

// 都市選択
struct CityPickerView: View {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedCity.id == city.id
                                ? Color.white.opacity(0.3)
                                : Color.white.opacity(0.1)
                            )
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .overlay(
                                // 選択中はさらに白い枠線を付けて分かりやすくする
                                Capsule().stroke(
                                    viewModel.selectedCity.id == city.id ? Color.white : Color.clear,
                                    lineWidth: 1.5
                                )
                            )
                    }
                }
            }
            // 端の都市が画面端に張り付かないようにする
            .padding(.horizontal)
        }
    }
}
```
▶ 理解: `CityPickerView` は `viewModel` を init引数で受け取っていない。
`@EnvironmentObject` で親が注入したものを直接使っている。

### 5-2: メイン天気カード（`Views/WeatherMainCard.swift`）
```swift
import SwiftUI

// メイン天気カード
struct WeatherMainCard: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var city: WeatherCondition { viewModel.selectedCity }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: city.condition.icon)
                .font(.system(size: 72))
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.white)

            Text(city.cityName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))

            Text(city.formattedTemp)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(.white)

            Text(city.condition.rawValue)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            Text("体感 \(Int(city.feelsLike))°")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }
}
```
`var city: WeatherCondition { viewModel.selectedCity }` のように計算プロパティで
ショートカットを作っておくと、以降 `viewModel.selectedCity.xxx` を書かずに `city.xxx` で済む。

### 5-3: 時間別予報（`Views/HourlyForecastRow.swift`）
```swift
import SwiftUI

// 時間別予報
struct HourlyForecastRow: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("時間ごとの予報", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.selectedCity.hourlyForecast) { forecast in
                        VStack(spacing: 8) {
                            Text(forecast.hour)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.8))
                            Image(systemName: forecast.condition.icon)
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            Text("\(Int(forecast.temperature))°")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                // 端のカードが画面端に張り付かないようにする
                .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```
▶ ここで確認: 札幌を選ぶと、Step 1-3 で仕込んだ `.stormy` のカードが雷雲アイコンで表示されること

### 5-4: 週間予報（`Views/WeeklyForecastCard.swift`）
```swift
import SwiftUI

// 週間予報
struct WeeklyForecastCard: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("7日間の予報", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                ForEach(viewModel.selectedCity.weeklyForecast) { forecast in
                    HStack {
                        Text(forecast.dayName)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 40, alignment: .leading)

                        Image(systemName: forecast.condition.icon)
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 24)

                        Text(forecast.condition.rawValue)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))

                        Spacer()

                        Text("\(Int(forecast.lowTemp))°")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, alignment: .trailing)

                        Text("\(Int(forecast.highTemp))°")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

### 5-5: 詳細セル + 詳細グリッド（`Views/Components/WeatherDetailCell.swift` / `Views/WeatherDetailGrid.swift`）
```swift
// WeatherDetailCell.swift — アイコン+タイトル+値の汎用カード
struct WeatherDetailCell: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```
```swift
// WeatherDetailGrid.swift — WeatherDetailCell を2列のグリッドに並べる
struct WeatherDetailGrid: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var city: WeatherCondition { viewModel.selectedCity }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            WeatherDetailCell(icon: "humidity.fill", title: "湿度", value: viewModel.formattedHumidity(city.humidity))
            WeatherDetailCell(icon: "wind", title: "風速", value: viewModel.formattedWind(city.windSpeed))
            WeatherDetailCell(icon: "thermometer.low", title: "体感気温", value: "\(Int(city.feelsLike))°")
            WeatherDetailCell(icon: "location.fill", title: "都市", value: city.cityName)
        }
    }
}
```
`WeatherDetailCell` 自身は `@EnvironmentObject` を持たない単純な表示用Viewにし、
値の取得・整形（`formattedHumidity`など）は呼び出し側の `WeatherDetailGrid` に任せる。

### 5-6: WeatherDashboardView に全コンポーネントを追加する
```swift
            ScrollView {
                VStack(spacing: 20) {
                    CityPickerView()      // ← 引数なし！
                    WeatherMainCard()     // ← 引数なし！
                    HourlyForecastRow()   // ← 引数なし！
                    WeeklyForecastCard()  // ← 引数なし！
                    WeatherDetailGrid()   // ← 引数なし！
                }
                .padding()
            }
```
▶ ここで確認: 全コンポーネントが引数なしで配置でき、都市選択・更新ボタンの操作で
画面全体が同時に更新されること

---

## 完成チェックリスト
- [ ] .environmentObject() の注入場所（WeatherAppRoot）を理解した
- [ ] @EnvironmentObject を使う子Viewは init引数でViewModelを受け取らない
- [ ] Previewに .environmentObject() を忘れるとクラッシュすることを確認した
- [ ] 都市切り替えで全コンポーネントが同時に更新される
- [ ] 更新ボタンで気温・湿度・風速がランダムに変化する（refreshWeather）
- [ ] 札幌の時間別予報で `.stormy`（嵐）アイコンが表示される
- [ ] @StateObject（所有）/@ObservedObject（参照）/@EnvironmentObject（環境から取得）の3つを使い分けられるようになった
