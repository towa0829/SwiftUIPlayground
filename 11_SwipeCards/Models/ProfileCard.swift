import SwiftUI

/// スワイプ対象になる1枚のプロフィールカード
struct ProfileCard: Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var emoji: String
    var bio: String
    var color: Color
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        emoji: String,
        bio: String,
        color: Color,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.emoji = emoji
        self.bio = bio
        self.color = color
        self.tags = tags
    }
}

extension ProfileCard {
    static let samples: [ProfileCard] = [
        ProfileCard(name: "もも", age: 24, emoji: "🐶", bio: "散歩とおやつが好きです", color: .orange, tags: ["散歩", "おやつ"]),
        ProfileCard(name: "りん", age: 27, emoji: "🐱", bio: "日向ぼっこが得意です", color: .pink, tags: ["日向ぼっこ", "マイペース"]),
        ProfileCard(name: "そら", age: 22, emoji: "🐰", bio: "にんじんに目がありません", color: .green, tags: ["にんじん", "ジャンプ"]),
        ProfileCard(name: "あお", age: 29, emoji: "🐧", bio: "寒いところが大好きです", color: .blue, tags: ["雪", "泳ぐ"]),
        ProfileCard(name: "くる", age: 25, emoji: "🐻", bio: "はちみつ探しが趣味です", color: .brown, tags: ["はちみつ", "冬眠"]),
        ProfileCard(name: "つき", age: 23, emoji: "🦊", bio: "夜の散歩が好きです", color: .red, tags: ["夜行性", "森"]),
        ProfileCard(name: "はな", age: 26, emoji: "🐼", bio: "笹をかじるのが日課です", color: .mint, tags: ["笹", "のんびり"]),
        ProfileCard(name: "ゆめ", age: 21, emoji: "🦁", bio: "群れのリーダー気質です", color: .yellow, tags: ["リーダー", "草原"]),
    ]
}
