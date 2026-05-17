import SwiftUI
import SBDesignSystem

struct ScanTabPlaceholderView: View {

    var body: some View {
        VStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Tab.scan.localized)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)
        }
        .sbPadding(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sbSurfacePrimary)
    }
}
