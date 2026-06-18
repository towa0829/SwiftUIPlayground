import SwiftUI

// カスタムProgressViewStyle
struct CircularProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: configuration.fractionCompleted)
            Text("\(Int((configuration.fractionCompleted ?? 0) * 100))%")
                .font(.footnote.bold())
        }
        .frame(width: 56, height: 56)
    }
}

#Preview {
    ProgressView(value: 0.65)
        .progressViewStyle(CircularProgressStyle())
}
