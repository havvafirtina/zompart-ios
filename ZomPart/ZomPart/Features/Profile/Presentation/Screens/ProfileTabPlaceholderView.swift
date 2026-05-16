import SwiftUI
import SBDesignSystem

struct ProfileTabPlaceholderView: View {

  var body: some View {
    VStack {
      Image(systemName: "person.fill")
        .font(.system(size: 60))
        .foregroundStyle(Color.sbAccentPrimary)

      Text(Localized.Tab.profile.localized)
        .font(.sbTitleSemiboldLarge)
        .foregroundStyle(Color.sbTextPrimary)
    }
    .sbPadding(.large)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sbSurfacePrimary)
  }
}
