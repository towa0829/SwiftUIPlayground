import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showNewPost = false

    var body: some View {
        List(viewModel.posts) { post in
            NavigationLink(destination: PostDetailView(post: post, viewModel: viewModel)) {
                PostRowView(post: post, viewModel: viewModel)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("ホーム")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewPost = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewPost) {
            NewPostView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
