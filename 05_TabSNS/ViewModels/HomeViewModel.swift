import Foundation
import Combine

/// ホームタブだけでなく、探索・通知・プロフィールタブが参照する状態も一元管理するViewModel。
/// タブ間で同じデータ（投稿・ユーザー・通知・フォロー状態）を共有するために、各タブへこのインスタンスを渡す。
class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = Post.samples
    @Published var currentUser: SNSUser = SNSUser.currentUser
    @Published var notifications: [String] = [
        "Hana Tanaka があなたの投稿にいいねしました",
        "Kenji Suzuki があなたをフォローしました",
        "Yuki Kobayashi があなたの投稿にコメントしました",
    ]
    @Published private var followingStatus: [UUID: Bool] = [:]

    func toggleLike(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
    }

    func addPost(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPost = Post(
            authorName: currentUser.name,
            authorHandle: currentUser.handle,
            authorAvatarIcon: currentUser.avatarIcon,
            content: trimmed,
            likesCount: 0
        )
        posts.insert(newPost, at: 0)
        currentUser.postsCount += 1
    }

    func isFollowing(_ user: SNSUser) -> Bool {
        followingStatus[user.id, default: false]
    }

    func toggleFollow(_ user: SNSUser) {
        followingStatus[user.id, default: false].toggle()
    }

    func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "たった今" }
        if seconds < 3600 { return "\(seconds / 60)分前" }
        if seconds < 86400 { return "\(seconds / 3600)時間前" }
        return "\(seconds / 86400)日前"
    }
}
