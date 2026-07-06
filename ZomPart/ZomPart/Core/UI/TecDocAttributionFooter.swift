import SwiftUI
import SBDesignSystem

/// Contractual TecAlliance attribution — the TecDoc license requires the
/// "TecDoc Inside" mark + copyright wherever TecDoc catalog data is shown
/// (scan results, scan detail, offers, catalog browse/search).
/// Text-only interim: swap in the official artwork imageset (per the
/// TecAlliance brand guide) before App Store submission.
struct TecDocAttributionFooter: View {

    var body: some View {
        Text(Localized.Common.tecdocAttribution.localizedKey)
            .font(.sbBodyRegularXSmall)
            .foregroundStyle(Color.sbTextTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }
}
