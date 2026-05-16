import SwiftUI
import SBDesignSystem

struct VINScannerView: View {

  @Bindable var viewModel: VINScannerViewModel
  @State private var showCamera = false

  var body: some View {
    ScrollView {
      VStack {
        headerSection
        cameraButton
        manualInputSection
        resolveButton
        statusSection
      }
      .sbPadding(.large)
    }
    .background(Color.sbSurfacePrimary)
    .navigationTitle(Localized.Garage.scanVIN.localized)
    .fullScreenCover(isPresented: $showCamera) {
      CameraPickerView { image in
        showCamera = false
        guard let image else { return }
        Task { await viewModel.processImage(image) }
      }
      .ignoresSafeArea()
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

  private var cameraButton: some View {
    Button {
      Task {
        let granted = await viewModel.requestCameraAccess()
        if granted { showCamera = true }
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

struct CameraPickerView: UIViewControllerRepresentable {

  let onCapture: (UIImage?) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
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
