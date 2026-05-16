import SwiftUI
import SBDesignSystem

struct GarageTabPlaceholderView: View {

  var body: some View {
    VStack {
      Image(systemName: "car.fill")
        .font(.system(size: 60))
        .foregroundStyle(Color.sbAccentPrimary)

      Text(Localized.Tab.garage.localized)
        .font(.sbTitleSemiboldLarge)
        .foregroundStyle(Color.sbTextPrimary)
    }
    .sbPadding(.large)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sbSurfacePrimary)
  }
}
