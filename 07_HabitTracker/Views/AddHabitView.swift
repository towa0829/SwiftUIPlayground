import SwiftUI
import SwiftData

struct AddHabitView: View {
    @ObservedObject var store: HabitStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var targetCount = 1
    @State private var selectedColorName = "blue"

    let emojiOptions = ["⭐️", "🏃", "📚", "💧", "🧘", "🌍", "🍎", "💪", "🎯", "🎵"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("習慣の名前", text: $name)

                    // 絵文字セレクター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.title2)
                                    .padding(8)
                                    .background(emoji == e ? Color.blue.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                }

                Section("目標") {
                    Stepper("目標回数: \(targetCount)", value: $targetCount, in: 1...100)
                }

                Section("カラー") {
                    HStack(spacing: 12) {
                        ForEach(Habit.colorOptions, id: \.self) { colorName in
                            Circle()
                                .fill(Habit.color(named: colorName))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColorName == colorName ? 3 : 0)
                                )
                                .shadow(
                                    color: Habit.color(named: colorName).opacity(0.5),
                                    radius: selectedColorName == colorName ? 4 : 0
                                )
                                .onTapGesture { selectedColorName = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("習慣を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        store.addHabit(
                            name: name,
                            emoji: emoji,
                            target: targetCount,
                            colorName: selectedColorName,
                            context: modelContext
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddHabitView(store: HabitStore())
        .modelContainer(for: Habit.self, inMemory: true)
}
