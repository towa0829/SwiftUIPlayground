import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]
    @StateObject private var viewModel = TodoViewModel()

    private var completedCount: Int { items.filter(\.isCompleted).count }
    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Label("\(pendingCount) 件残り", systemImage: "circle")
                            .foregroundStyle(.orange)
                        Label("\(completedCount) 件完了", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }

                ForEach(items) { item in
                    NavigationLink(destination: TodoDetailView(item: item, viewModel: viewModel)) {
                        TodoRowView(item: item) {
                            viewModel.toggleItem(item)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteItems([item], context: modelContext)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleItem(item)
                        } label: {
                            Label(
                                item.isCompleted ? "未完了" : "完了",
                                systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(item.isCompleted ? .orange : .green)
                    }
                }
                .onDelete { offsets in
                    let toDelete = offsets.map { items[$0] }
                    viewModel.deleteItems(toDelete, context: modelContext)
                }
            }
            .navigationTitle("TODO")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                AddTodoView(viewModel: viewModel)
            }
            .task {
                seedIfNeeded()
            }
        }
    }

    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        for sample in TodoItem.samples {
            modelContext.insert(sample)
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
