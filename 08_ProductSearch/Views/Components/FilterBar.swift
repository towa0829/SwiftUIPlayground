import SwiftUI

struct FilterBar: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProductCategory.allCases) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedCategory == category ? Color.blue : Color(.secondarySystemBackground)
                            )
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    FilterBar(viewModel: ProductViewModel())
}
