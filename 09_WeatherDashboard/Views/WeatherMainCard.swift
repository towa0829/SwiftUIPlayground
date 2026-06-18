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

#Preview {
    WeatherMainCard()
        .background(Color.blue.gradient)
        .environmentObject(WeatherViewModel())
}
