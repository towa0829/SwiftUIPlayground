import SwiftUI

struct HabitListView: View {
    // @StateObject: このViewがHabitStoreを所有・管理する
    // Viewが破棄されるまでインスタンスが保持される
    @StateObject private var store = HabitStore()
    @State private var showAddHabit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 全体進捗サマリー
                    SummaryCard(store: store)
                        .padding(.horizontal)

                    // 習慣リスト
                    ForEach(store.habits) { habit in
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
        }
    }
}

#Preview {
    HabitListView()
}
