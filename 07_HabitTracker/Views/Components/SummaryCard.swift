import SwiftUI

struct SummaryCard: View {
    // @ObservedObject: 外部から受け取ったObservableObjectを購読
    @ObservedObject var store: HabitStore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の進捗")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(store.totalCompleted) / \(store.habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView: 進捗を視覚的に表示（円形）
                ProgressView(value: store.overallProgress)
                    .progressViewStyle(CircularProgressStyle())
            }

            // ProgressView: 線形（デフォルト）
            ProgressView(value: store.overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCard(store: HabitStore())
        .padding()
        .background(Color(.systemGroupedBackground))
}
