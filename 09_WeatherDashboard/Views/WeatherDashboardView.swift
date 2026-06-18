import SwiftUI

struct WeatherDashboardView: View {
    // @EnvironmentObject: 親から注入されたViewModelを受け取る
    // .environmentObject() で注入されていないと実行時エラーになる
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 都市選択ピッカー
                    CityPickerView()

                    // メイン天気カード
                    WeatherMainCard()

                    // 時間別予報
                    HourlyForecastRow()

                    // 週間予報
                    WeeklyForecastCard()

                    // 詳細情報
                    WeatherDetailGrid()
                }
                .padding()
            }
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
        }
    }
}

#Preview {
    WeatherDashboardView()
        .environmentObject(WeatherViewModel())
}
