import SwiftUI

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

#Preview {
    WeatherDetailCell(icon: "humidity.fill", title: "湿度", value: "62%")
        .padding()
        .background(Color.blue.gradient)
}
