import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    // @StateObject: このViewがHabitStoreを所有・管理する
    // Viewが破棄されるまでインスタンスが保持される
    @StateObject private var store = HabitStore()
    @State private var showAddHabit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 全体進捗サマリー
                    SummaryCard(habits: habits)
                        .padding(.horizontal)

                    // 習慣リスト
                    ForEach(habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit, store: store)) {
                            HabitRowView(habit: habit, store: store)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("習慣トラッカー")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView(store: store)
            }
            .task {
                seedIfNeeded()
            }
        }
    }

    private func seedIfNeeded() {
        guard habits.isEmpty else { return }
        for sample in Habit.samples {
            modelContext.insert(sample)
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true)
}
