import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var targetCount: Int        // 1日の目標回数
    var completedCount: Int     // 今日の完了回数
    var streak: Int             // 連続日数
    var colorName: String

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        targetCount: Int = 1,
        completedCount: Int = 0,
        streak: Int = 0,
        colorName: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.targetCount = targetCount
        self.completedCount = completedCount
        self.streak = streak
        self.colorName = colorName
    }

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1.0)
    }

    var isCompleted: Bool {
        completedCount >= targetCount
    }
}

extension Habit {
    static let colorOptions: [String] = ["blue", "red", "green", "orange", "purple", "pink", "yellow", "teal"]

    static func color(named colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }

    var color: Color {
        Habit.color(named: colorName)
    }
}

extension Habit {
    static let samples: [Habit] = [
        Habit(name: "朝の瞑想", emoji: "🧘", targetCount: 1, completedCount: 1, streak: 7, colorName: "purple"),
        Habit(name: "読書", emoji: "📚", targetCount: 30, completedCount: 12, streak: 3, colorName: "orange"),
        Habit(name: "ウォーキング", emoji: "🚶", targetCount: 10000, completedCount: 6540, streak: 14, colorName: "green"),
        Habit(name: "水を飲む", emoji: "💧", targetCount: 8, completedCount: 5, streak: 21, colorName: "blue"),
        Habit(name: "英語学習", emoji: "🌍", targetCount: 1, completedCount: 0, streak: 0, colorName: "red"),
    ]
}
