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

#Preview {
    HourlyForecastRow()
        .padding()
        .background(Color.blue.gradient)
        .environmentObject(WeatherViewModel())
}
