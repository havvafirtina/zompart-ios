import SwiftUI
import SBDesignSystem

struct PlateScannerView: View {

    @Bindable var viewModel: PlateScannerViewModel
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack {
                headerSection
                scanButton
                manualInputSection
                resolveButton
                statusSection
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Garage.scanPlate.localized)
        .fullScreenCover(isPresented: $showScanner) {
            scannerOverlay
        }
    }

    private var headerSection: some View {
        VStack {
            Image(systemName: "car.rear.and.tire.marks")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Garage.scanPlateDescription.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .sbVerticalPadding(.large)
    }

    private var scanButton: some View {
        Button {
            Task {
                let granted = await viewModel.requestCameraAccess()
                if granted { showScanner = true }
            }
        } label: {
            HStack {
                Image(systemName: "camera.fill")
                Text(Localized.Garage.openCamera.localizedKey)
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbTextOnAccent)
            .frame(maxWidth: .infinity)
            .sbControlHeight(.regular)
            .background(Color.sbAccentPrimary)
            .sbCornerRadius(.default)
        }
    }

    private var scannerOverlay: some View {
        ZStack(alignment: .topTrailing) {
            if LiveTextScannerView.isDeviceSupported {
                LiveTextScannerView { recognizedText in
                    let cleaned = recognizedText.replacingOccurrences(of: " ", with: "").uppercased()
                    viewModel.manualPlate = cleaned
                    showScanner = false
                } onDismiss: {
                    showScanner = false
                }
                .ignoresSafeArea()
            } else {
                CameraPickerView { image in
                    showScanner = false
                    guard let image else { return }
                    Task { await viewModel.processImage(image) }
                }
                .ignoresSafeArea()
            }

            Button {
                showScanner = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
    }

    private var manualInputSection: some View {
        VStack(alignment: .leading) {
            Text(Localized.Garage.enterManually.localizedKey)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextSecondary)

            TextField(Localized.Garage.platePlaceholder.localized, text: $viewModel.manualPlate)
                .font(.sbBodyMediumDefault)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .sbPadding(.medium)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.medium)
        }
        .sbVerticalPadding(.large)
    }

    private var resolveButton: some View {
        Button {
            Task { await viewModel.resolveEnteredPlate() }
        } label: {
            Text(Localized.Garage.resolveVehicle.localizedKey)
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(Color.sbAccentPrimary)
                .frame(maxWidth: .infinity)
                .sbControlHeight(.regular)
                .background(Color.sbAccentSubtle)
                .sbCornerRadius(.default)
        }
        .disabled(viewModel.manualPlate.isEmpty)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .sbVerticalPadding(.large)
        case .error(let message):
            Text(message)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbStatusError)
                .sbVerticalPadding(.medium)
        case .loaded(let result):
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.sbStatusSuccess)
                Text("\(result.vehicle.make) \(result.vehicle.model)")
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)
            }
            .sbPadding(.medium)
            .background(Color.sbStatusSuccessSubtle)
            .sbCornerRadius(.medium)
            .sbVerticalPadding(.large)
        default:
            EmptyView()
        }
    }
}
