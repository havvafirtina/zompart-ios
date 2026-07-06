import SwiftUI
import SBDesignSystem

struct VINScannerView: View {

    @Bindable var viewModel: VINScannerViewModel
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
        .navigationTitle(Localized.Garage.scanVIN.localized)
        .fullScreenCover(isPresented: $showScanner) {
            scannerOverlay
        }
    }

    private var headerSection: some View {
        VStack {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Garage.scanVINDescription.localizedKey)
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
                    viewModel.manualVIN = cleaned
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

            TextField(Localized.Garage.vinPlaceholder.localized, text: $viewModel.manualVIN)
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
            Task { await viewModel.resolveEnteredVIN() }
        } label: {
            Text(Localized.Garage.resolveVehicle.localizedKey)
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(Color.sbAccentPrimary)
                .frame(maxWidth: .infinity)
                .sbControlHeight(.regular)
                .background(Color.sbAccentSubtle)
                .sbCornerRadius(.default)
        }
        .disabled(viewModel.manualVIN.count != 17)
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
                Text("\(result.vehicle.make.displayCased) \(result.vehicle.model.displayCased)")
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

struct CameraPickerView: UIViewControllerRepresentable {

    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Assigning .camera on a device without one (Simulator, MDM-restricted
        // hardware) raises NSInvalidArgumentException — fall back to the library.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
        }
    }
}
