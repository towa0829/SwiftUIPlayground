import Foundation
import Combine
import SwiftUI

class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = FeedPost.samples

    func toggleLike(_ post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedBody.isEmpty else { return }
        let post = FeedPost(
            title: trimmedTitle,
            body: trimmedBody,
            authorName: "自分",
            authorIcon: "person.crop.circle.fill"
        )
        posts.insert(post, at: 0)
    }

    func deletePost(_ post: FeedPost) {
        posts.removeAll { $0.id == post.id }
    }

    /// IndexSetをまとめて削除する。配列をforEachで個別削除すると
    /// 削除のたびにindexがずれて誤った要素を消す恐れがあるため remove(atOffsets:) を使う。
    func deletePosts(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
    }
}
