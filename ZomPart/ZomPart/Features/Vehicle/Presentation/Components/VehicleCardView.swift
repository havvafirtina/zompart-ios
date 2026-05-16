import SwiftUI
import SBDesignSystem

struct VehicleCardView: View {

  let vehicle: VehicleDomain
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading) {
          Text(vehicleTitle)
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbTextPrimary)

          Text(vehicleSubtitle)
            .font(.sbBodyRegularSmall)
            .foregroundStyle(Color.sbTextSecondary)
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

  private var vehicleTitle: String {
    let year = vehicle.year.map { String($0) } ?? ""
    return [year, vehicle.make, vehicle.model]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }

  private var vehicleSubtitle: String {
    if let plate = vehicle.plate, !plate.isEmpty {
      return plate
    } else if let vin = vehicle.vin, !vin.isEmpty {
      return vin
    }
    return vehicle.resolveMethod.rawValue
  }
}
