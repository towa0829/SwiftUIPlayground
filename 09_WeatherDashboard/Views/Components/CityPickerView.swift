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

#Preview {
    CityPickerView()
        .padding(.vertical)
        .background(Color.blue.gradient)
        .environmentObject(WeatherViewModel())
}
