import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel

    // 最新の状態を取得
    var current: Product {
        viewModel.allProducts.first(where: { $0.id == product.id }) ?? product
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 商品画像プレースホルダー
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 240)
                    .overlay {
                        VStack(spacing: 8) {
                            Text(current.category.emoji)
                                .font(.system(size: 72))
                            Text(current.brand)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                VStack(alignment: .leading, spacing: 12) {
                    // 名前 + お気に入り
                    HStack {
                        Text(current.name)
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            viewModel.toggleFavorite(current)
                        } label: {
                            Image(systemName: current.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(current.isFavorite ? .red : .secondary)
                        }
                    }

                    // 価格
                    Text(current.formattedPrice)
                        .font(.title.bold())
                        .foregroundStyle(.blue)

                    // 評価
                    HStack(spacing: 6) {
                        Text(viewModel.starsString(for: current.rating))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", current.rating))
                            .font(.headline)
                        Text("(\(current.reviewCount)件のレビュー)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // 商品説明
                    Text("商品説明")
                        .font(.headline)
                    Text(current.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // カテゴリ
                    HStack {
                        Label(current.category.rawValue, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label(current.brand, systemImage: "building.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // カートに追加ボタン
                Button {
                    // 実装例（実際の購入処理はここに追加）
                } label: {
                    Label("カートに追加", systemImage: "cart.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            // 画像・本文・ボタンの左右マージンを統一（画像だけフルブリードにしない）
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product.samples[0], viewModel: ProductViewModel())
    }
}
