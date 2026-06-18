import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        List(viewModel.notifications, id: \.self) { notification in
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(notification)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("通知")
    }
}

#Preview {
    NavigationStack {
        NotificationsView(viewModel: HomeViewModel())
    }
}
