import SwiftUI
import SBDesignSystem

struct ThemePickerView: View {

    let themeManager: ThemeManager

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(SBTheme.allCases, id: \.self) { theme in
                    let isSelected = themeManager.currentTheme == theme

                    Button {
                        themeManager.currentTheme = theme
                    } label: {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Self.previewColors[theme] ?? .gray)
                                    .frame(width: 48, height: 48)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.sbBodySemiboldDefault)
                                        .foregroundStyle(.white)
                                }
                            }

                            Text(theme.rawValue.capitalized)
                                .font(.sbBodyRegularSmall)
                                .foregroundStyle(Color.sbTextPrimary)
                        }
                        .sbPadding(.medium)
                        .frame(maxWidth: .infinity)
                        .background(Color.sbSurfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? (Self.previewColors[theme] ?? Color.sbAccentPrimary) : .clear,
                                    lineWidth: 3
                                )
                        )
                        .sbCornerRadius(.default)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sbPadding(.large)
        }
        .background(Self.surfaceColors[themeManager.currentTheme] ?? Color.sbSurfacePrimary)
        .navigationTitle(Localized.Profile.theme.localized)
    }

    private static let previewColors: [SBTheme: Color] = [
        .lavender: Color(red: 0.55, green: 0.42, blue: 0.78),
        .spring: Color(red: 0.42, green: 0.72, blue: 0.45),
        .coral: Color(red: 0.93, green: 0.47, blue: 0.47),
        .meadow: Color(red: 0.40, green: 0.76, blue: 0.52),
        .ember: Color(red: 0.90, green: 0.50, blue: 0.25),
        .frost: Color(red: 0.35, green: 0.55, blue: 0.78),
        .grove: Color(red: 0.25, green: 0.58, blue: 0.42),
        .aura: Color(red: 0.62, green: 0.40, blue: 0.82),
        .horizon: Color(red: 0.88, green: 0.58, blue: 0.32),
        .bloom: Color(red: 0.20, green: 0.75, blue: 0.60),
        .galaxy: Color(red: 0.40, green: 0.30, blue: 0.70),
        .carnival: Color(red: 0.85, green: 0.30, blue: 0.65),
        .crimson: Color(red: 0.92, green: 0.00, blue: 0.08)
    ]

    private static let surfaceColors: [SBTheme: Color] = [
        .lavender: Color(red: 0.96, green: 0.95, blue: 0.99),
        .spring: Color(red: 0.95, green: 0.97, blue: 0.95),
        .coral: Color(red: 0.99, green: 0.95, blue: 0.95),
        .meadow: Color(red: 0.95, green: 0.98, blue: 0.95),
        .ember: Color(red: 0.99, green: 0.96, blue: 0.93),
        .frost: Color(red: 0.95, green: 0.96, blue: 0.98),
        .grove: Color(red: 0.94, green: 0.97, blue: 0.95),
        .aura: Color(red: 0.97, green: 0.95, blue: 0.99),
        .horizon: Color(red: 0.99, green: 0.97, blue: 0.94),
        .bloom: Color(red: 0.94, green: 0.98, blue: 0.97),
        .galaxy: Color(red: 0.95, green: 0.94, blue: 0.98),
        .carnival: Color(red: 0.99, green: 0.94, blue: 0.97),
        .crimson: Color(red: 0.99, green: 0.96, blue: 0.96)
    ]
}
