import SwiftUI

// 詳細グリッド
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

#Preview {
    WeatherDetailGrid()
        .padding()
        .background(Color.blue.gradient)
        .environmentObject(WeatherViewModel())
}
