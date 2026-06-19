import SwiftUI

struct SummaryCard: View {
    let habits: [Habit]

    private var totalCompleted: Int {
        habits.filter(\.isCompleted).count
    }

    private var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の進捗")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(totalCompleted) / \(habits.count) 完了")
                        .font(.title2.bold())
                }
                Spacer()
                // ProgressView: 進捗を視覚的に表示（円形、CircularProgressStyleを適用）
                ProgressView(value: overallProgress)
                    .progressViewStyle(CircularProgressStyle())
            }

            // ProgressView: 線形（デフォルト）
            ProgressView(value: overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCard(habits: Habit.samples)
        .padding()
        .background(Color(.systemGroupedBackground))
}
