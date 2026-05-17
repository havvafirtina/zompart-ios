import SwiftUI
import SBDesignSystem

struct PhotoGridView: View {

    let photos: [UIImage]
    let onRemove: (Int) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                        .sbCornerRadius(.medium)

                    Button {
                        onRemove(index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.sbBodyRegularSmall)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .offset(x: 4, y: -4)
                }
            }
        }
    }
}
