import SwiftUI

struct ProductRowView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        HStack(spacing: 12) {
            // 商品アイコン（カテゴリ別）
            RoundedRectangle(cornerRadius: 10)
                .fill(product.category.color.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay {
                    Text(product.category.emoji)
                        .font(.title2)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(product.brand)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(viewModel.starsString(for: product.rating))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text("(\(product.reviewCount))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(product.formattedPrice)
                    .font(.subheadline.bold())

                Button {
                    viewModel.toggleFavorite(product)
                } label: {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(product.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    List {
        ProductRowView(product: Product.samples[0], viewModel: ProductViewModel())
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
}
