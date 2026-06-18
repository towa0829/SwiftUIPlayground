import SwiftUI

struct Product: Identifiable {
    let id: UUID
    var name: String
    var brand: String
    var category: ProductCategory
    var price: Double
    var rating: Double
    var reviewCount: Int
    var isFavorite: Bool
    var description: String

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: ProductCategory,
        price: Double,
        rating: Double = 0,
        reviewCount: Int = 0,
        isFavorite: Bool = false,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.rating = rating
        self.reviewCount = reviewCount
        self.isFavorite = isFavorite
        self.description = description
    }

    var formattedPrice: String {
        "¥\(Int(price).formatted())"
    }
}

enum ProductCategory: String, CaseIterable, Identifiable {
    case all = "すべて"
    case electronics = "電子機器"
    case books = "本"
    case clothing = "ファッション"
    case food = "食品"
    case sports = "スポーツ"

    var id: String { rawValue }

    // 絵文字/色をここに一本化する（行・詳細の両Viewから共通利用）。
    // 個別Viewでswitch/三項演算を重複させると non-exhaustive な抜け漏れが起きやすい。
    var emoji: String {
        switch self {
        case .all: return "🛍"
        case .electronics: return "📱"
        case .books: return "📚"
        case .clothing: return "👔"
        case .food: return "🍵"
        case .sports: return "🏃"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .electronics: return .blue
        case .books: return .orange
        case .clothing: return .purple
        case .food: return .green
        case .sports: return .red
        }
    }
}

extension Product {
    static let samples: [Product] = [
        Product(name: "iPhone 16 Pro", brand: "Apple", category: .electronics, price: 159800, rating: 4.8, reviewCount: 2341, isFavorite: true, description: "最新のA18 Proチップを搭載したフラッグシップiPhone。"),
        Product(name: "MacBook Air M3", brand: "Apple", category: .electronics, price: 164800, rating: 4.9, reviewCount: 1892, description: "超薄型・軽量で高性能なノートPC。"),
        Product(name: "AirPods Pro 2", brand: "Apple", category: .electronics, price: 39800, rating: 4.7, reviewCount: 4210, isFavorite: true, description: "アクティブノイズキャンセリング搭載の完全ワイヤレスイヤホン。"),
        Product(name: "Swift Programming Language", brand: "Apple", category: .books, price: 3200, rating: 4.6, reviewCount: 892, description: "Swiftの公式リファレンスガイド。"),
        Product(name: "SwiftUI実践入門", brand: "技術評論社", category: .books, price: 3800, rating: 4.4, reviewCount: 345, isFavorite: true, description: "SwiftUIを実践的に学べる入門書。"),
        Product(name: "ランニングシューズ Pro", brand: "Nike", category: .sports, price: 18900, rating: 4.5, reviewCount: 1203, description: "クッション性抜群のランニングシューズ。"),
        Product(name: "ヨガマット 6mm", brand: "Manduka", category: .sports, price: 8900, rating: 4.6, reviewCount: 678, description: "滑りにくいプレミアムヨガマット。"),
        Product(name: "Tシャツ 無地", brand: "UNIQLO", category: .clothing, price: 1500, rating: 4.3, reviewCount: 5620, description: "シンプルな無地Tシャツ。"),
        Product(name: "デニムジャケット", brand: "Levi's", category: .clothing, price: 12800, rating: 4.4, reviewCount: 892, isFavorite: true, description: "クラシックなデニムジャケット。"),
        Product(name: "有機緑茶 50g", brand: "伊藤園", category: .food, price: 800, rating: 4.7, reviewCount: 2103, description: "宇治産100%の高品質有機緑茶。"),
        Product(name: "ダークチョコレート", brand: "Meiji", category: .food, price: 250, rating: 4.5, reviewCount: 3450, isFavorite: true, description: "カカオ72%の高品質ダークチョコレート。"),
        Product(name: "Galaxy S24", brand: "Samsung", category: .electronics, price: 124800, rating: 4.6, reviewCount: 1567, description: "最新Androidフラッグシップスマートフォン。"),
    ]
}
