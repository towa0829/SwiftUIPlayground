import Foundation
import Combine
import SwiftUI

// ObservableObject: 変更を@StateObject/@ObservedObjectで購読できるクラス
class HabitStore: ObservableObject {
    // @Published: 値が変更されるとViewが自動的に再描画される
    @Published var habits: [Habit] = Habit.samples

    var totalCompleted: Int {
        habits.filter(\.isCompleted).count
    }

    var overallProgress: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.progress } / Double(habits.count)
    }

    // streak更新の単一ルール:
    // 「未達 → 達成」に転じた瞬間に +1、「達成 → 未達」に戻った瞬間に -1。
    // increment/decrement/complete/reset すべてがこのルールに従うため、
    // 行のトグル操作と詳細画面のボタン操作で結果が一致する。
    private func syncStreak(at index: Int, wasCompleted: Bool) {
        let isCompleted = habits[index].isCompleted
        if !wasCompleted && isCompleted {
            habits[index].streak += 1
        } else if wasCompleted && !isCompleted {
            habits[index].streak = max(0, habits[index].streak - 1)
        }
    }

    func increment(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        if habits[index].completedCount < habits[index].targetCount {
            habits[index].completedCount += 1
        }
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func decrement(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        if habits[index].completedCount > 0 {
            habits[index].completedCount -= 1
        }
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func complete(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        habits[index].completedCount = habits[index].targetCount
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func reset(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let wasCompleted = habits[index].isCompleted
        habits[index].completedCount = 0
        syncStreak(at: index, wasCompleted: wasCompleted)
    }

    func addHabit(name: String, emoji: String, target: Int, color: Color) {
        let habit = Habit(name: name, emoji: emoji, targetCount: target, color: color)
        habits.append(habit)
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }
}
