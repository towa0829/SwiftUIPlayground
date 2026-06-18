import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var store: HabitStore

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(habit.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("\(habit.completedCount) / \(habit.targetCount)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 連続日数バッジ
                if habit.streak > 0 {
                    Label("\(habit.streak)日", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }

                // 完了ボタン / 進捗ボタン
                Button {
                    if habit.isCompleted {
                        store.reset(habit)
                    } else {
                        store.increment(habit)
                    }
                } label: {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(habit.isCompleted ? habit.color : .secondary)
                }
                .buttonStyle(.plain)
            }

            // ProgressView: 線形プログレスバー
            ProgressView(value: habit.progress)
                .tint(habit.color)
                .animation(.easeInOut(duration: 0.3), value: habit.progress)
        }
        .padding()
        .background(
            habit.isCompleted
            ? habit.color.opacity(0.08)
            : Color(.secondarySystemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(habit.isCompleted ? habit.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        HabitRowView(habit: Habit.samples[0], store: HabitStore())
        HabitRowView(habit: Habit.samples[1], store: HabitStore())
        HabitRowView(habit: Habit.samples[3], store: HabitStore())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
