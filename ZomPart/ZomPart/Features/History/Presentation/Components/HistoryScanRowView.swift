import SwiftUI
import SBDesignSystem

struct HistoryScanRowView: View {

    let scan: HistoryScanSummaryDomain
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                stateBadge

                VStack(alignment: .leading) {
                    if let part = scan.selectedPart {
                        Text(part.name)
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)
                    } else {
                        Text(stateLabel)
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)
                    }

                    HStack {
                        if let vehicle = scan.vehicle {
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .font(.sbBodyRegularSmall)
                                .foregroundStyle(Color.sbTextSecondary)
                        }

                        Spacer()

                        Text(formattedDate)
                            .font(.sbBodyRegularXSmall)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextTertiary)
            }
            .sbPadding(.large)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
            .sbShadow(.soft)
        }
        .buttonStyle(.plain)
    }

    private var stateBadge: some View {
        Image(systemName: stateIcon)
            .font(.title3)
            .foregroundStyle(stateColor)
            .frame(width: 32)
    }

    private var stateIcon: String {
        switch scan.state {
        case "OFFERS_READY": return "checkmark.seal.fill"
        case "DISAMBIGUATION": return "questionmark.circle.fill"
        case "FAILED": return "exclamationmark.triangle.fill"
        default: return "clock.fill"
        }
    }

    private var stateColor: Color {
        switch scan.state {
        case "OFFERS_READY": return Color.sbStatusSuccess
        case "DISAMBIGUATION": return Color.sbStatusWarning
        case "FAILED": return Color.sbStatusError
        default: return Color.sbTextTertiary
        }
    }

    private var stateLabel: String {
        switch scan.state {
        case "OFFERS_READY": return Localized.Scan.resultTitle.localized
        case "DISAMBIGUATION": return Localized.Scan.disambiguationTitle.localized
        case "FAILED": return Localized.Scan.failedTitle.localized
        case "INPUT_COLLECTED": return Localized.Scan.processing.localized
        default: return scan.state
        }
    }

    private var formattedDate: String {
        // Supabase timestamptz usually carries fractional seconds, but
        // emits none when they are exactly zero — try both formats.
        guard let date = Self.iso8601.date(from: scan.createdAt)
                ?? Self.iso8601NoFraction.date(from: scan.createdAt) else {
            return scan.createdAt
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
