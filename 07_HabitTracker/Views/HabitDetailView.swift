import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var store: HabitStore

    // Habitはクラス（参照型）のため、habit自身が常に最新状態を反映する
    private var currentHabit: Habit { habit }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 絵文字 + 名前
                VStack(spacing: 8) {
                    Text(currentHabit.emoji)
                        .font(.system(size: 72))
                    Text(currentHabit.name)
                        .font(.title.bold())
                    Label("\(currentHabit.streak)日連続", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
                .padding(.top)

                // 大きな円形プログレス
                ZStack {
                    Circle()
                        .stroke(currentHabit.color.opacity(0.2), lineWidth: 16)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: currentHabit.progress)
                        .stroke(
                            currentHabit.color,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 180, height: 180)
                        .animation(.spring(duration: 0.5), value: currentHabit.progress)

                    VStack(spacing: 4) {
                        Text("\(currentHabit.completedCount)")
                            .font(.system(size: 48, weight: .bold))
                        Text("/ \(currentHabit.targetCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // 操作ボタン
                HStack(spacing: 20) {
                    Button {
                        store.decrement(currentHabit)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(currentHabit.color.opacity(0.6))
                    }
                    .disabled(currentHabit.completedCount == 0)

                    Button {
                        store.increment(currentHabit)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(currentHabit.color)
                    }
                    .disabled(currentHabit.isCompleted)
                }

                // 一括完了ボタン
                if !currentHabit.isCompleted {
                    Button {
                        store.complete(currentHabit)
                    } label: {
                        Label("完了にする", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentHabit.color)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                } else {
                    Label("今日は達成済み！", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(currentHabit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit.samples[1], store: HabitStore())
    }
}
