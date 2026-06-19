import Foundation
import SwiftData
import SwiftUI

final class TodoViewModel: ObservableObject {
    @Published var newTitle: String = ""

    func addItem(context: ModelContext) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(TodoItem(title: trimmed))
        newTitle = ""
    }

    func toggleItem(_ item: TodoItem) {
        item.isCompleted.toggle()
    }

    func deleteItems(_ items: [TodoItem], context: ModelContext) {
        for item in items {
            context.delete(item)
        }
    }
}
