import Foundation
import SwiftData
import SwiftUI

// ObservableObject: 変更を@StateObject/@ObservedObjectで購読できるクラス
final class HabitStore: ObservableObject {
    // streak更新の単一ルール:
    // 「未達 → 達成」に転じた瞬間に +1、「達成 → 未達」に戻った瞬間に -1。
    // increment/decrement/complete/reset すべてがこのルールに従うため、
    // 行のトグル操作と詳細画面のボタン操作で結果が一致する。
    private func syncStreak(_ habit: Habit, wasCompleted: Bool) {
        let isCompleted = habit.isCompleted
        if !wasCompleted && isCompleted {
            habit.streak += 1
        } else if wasCompleted && !isCompleted {
            habit.streak = max(0, habit.streak - 1)
        }
    }

    func increment(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount < habit.targetCount {
            habit.completedCount += 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func decrement(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        if habit.completedCount > 0 {
            habit.completedCount -= 1
        }
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func complete(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = habit.targetCount
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func reset(_ habit: Habit) {
        let wasCompleted = habit.isCompleted
        habit.completedCount = 0
        syncStreak(habit, wasCompleted: wasCompleted)
    }

    func addHabit(name: String, emoji: String, target: Int, colorName: String, context: ModelContext) {
        context.insert(Habit(name: name, emoji: emoji, targetCount: target, colorName: colorName))
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
    }
}
