import Foundation
import Combine

// EnvironmentObject として使用するために ObservableObject に準拠
class WeatherViewModel: ObservableObject {
    @Published var weatherList: [WeatherCondition] = WeatherCondition.samples
    @Published var selectedCity: WeatherCondition

    init() {
        self.selectedCity = WeatherCondition.samples[0]
    }

    func selectCity(_ city: WeatherCondition) {
        selectedCity = city
    }

    func formattedHumidity(_ value: Int) -> String {
        "\(value)%"
    }

    func formattedWind(_ value: Double) -> String {
        String(format: "%.1f m/s", value)
    }

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
}
