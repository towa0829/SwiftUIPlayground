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

#Preview {
    WeeklyForecastCard()
        .padding()
        .background(Color.blue.gradient)
        .environmentObject(WeatherViewModel())
}
