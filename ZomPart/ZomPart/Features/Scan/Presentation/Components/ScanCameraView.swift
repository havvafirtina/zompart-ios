import SwiftUI
import SBDesignSystem
import VisionKit
import AVFoundation

struct ScanCameraView: View {

    let maxPhotos: Int
    let currentPhotoCount: Int
    let onPhotosCaptured: ([UIImage]) -> Void
    let onTextRecognized: (String) -> Void
    let onDismiss: () -> Void

    @State private var capturedPhotos: [UIImage] = []
    @State private var scannerCoordinator: ScanCameraCoordinator?
    @State private var cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)

    private var remainingSlots: Int {
        maxPhotos - currentPhotoCount - capturedPhotos.count
    }

    var body: some View {
        Group {
            switch cameraAuthStatus {
            case .authorized:
                scannerContent
            case .notDetermined:
                Color.black
                    .ignoresSafeArea()
                    .task {
                        _ = await AVCaptureDevice.requestAccess(for: .video)
                        cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    }
            default:
                permissionDeniedView
            }
        }
        .statusBarHidden()
    }

    private var scannerContent: some View {
        ZStack {
            if LiveTextScannerView.isDeviceSupported {
                ScanCameraRepresentable(
                    onTextTapped: { text in
                        onTextRecognized(text)
                    },
                    coordinatorRef: $scannerCoordinator
                )
                .ignoresSafeArea()
            }

            focusFrameOverlay

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.sbTextSecondary)

            Text(Localized.Scan.cameraPermissionTitle.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)

            Text(Localized.Scan.cameraPermissionMessage.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button(Localized.Common.openSettings.localizedKey) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Button(Localized.Common.cancel.localizedKey) {
                onDismiss()
            }
            .foregroundStyle(Color.sbTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sbPadding(.xLarge)
        .background(Color.sbSurfacePrimary)
    }

    private var topBar: some View {
        HStack {
            Button {
                finishAndDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }

            Spacer()

            if !capturedPhotos.isEmpty {
                Text("\(currentPhotoCount + capturedPhotos.count)/\(maxPhotos)")
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
        }
        .padding()
    }

    private var bottomBar: some View {
        HStack {
            if !capturedPhotos.isEmpty {
                thumbnailPreview
            }

            Spacer()

            if remainingSlots > 0 {
                captureButton
            }

            Spacer()

            if !capturedPhotos.isEmpty {
                doneButton
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var captureButton: some View {
        Button {
            Task {
                guard let coordinator = scannerCoordinator,
                      let photo = await coordinator.capturePhoto() else { return }
                capturedPhotos.append(photo)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
            }
        }
    }

    private var thumbnailPreview: some View {
        ZStack {
            if let last = capturedPhotos.last {
                Image(uiImage: last)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white, lineWidth: 2)
                    )
            }

            Text("\(capturedPhotos.count)")
                .font(.sbBodySemiboldSmall)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.sbAccentPrimary)
                .clipShape(Circle())
                .offset(x: 24, y: -24)
        }
    }

    private var doneButton: some View {
        Button {
            finishAndDismiss()
        } label: {
            Text(Localized.Common.done.localized)
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(.white)
                .sbHorizontalPadding(.large)
                .sbControlHeight(.compact)
                .background(Color.sbAccentPrimary)
                .sbCornerRadius(.medium)
        }
    }

    private var focusFrameOverlay: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                .frame(width: 280, height: 280)

            Text(Localized.Scan.cameraFocusHint.localizedKey)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 12)

            Spacer()
        }
        .allowsHitTesting(false)
    }

    private func finishAndDismiss() {
        if !capturedPhotos.isEmpty {
            onPhotosCaptured(capturedPhotos)
        }
        onDismiss()
    }
}

struct ScanCameraRepresentable: UIViewControllerRepresentable {

    let onTextTapped: (String) -> Void
    @Binding var coordinatorRef: ScanCameraCoordinator?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        DispatchQueue.main.async {
            coordinatorRef = context.coordinator
        }
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    func makeCoordinator() -> ScanCameraCoordinator {
        ScanCameraCoordinator(onTextTapped: onTextTapped)
    }
}

@MainActor
final class ScanCameraCoordinator: NSObject, DataScannerViewControllerDelegate {

    let onTextTapped: (String) -> Void
    weak var scanner: DataScannerViewController?
    private var highlightViews: [RecognizedItem.ID: UIView] = [:]

    init(onTextTapped: @escaping (String) -> Void) {
        self.onTextTapped = onTextTapped
    }

    func capturePhoto() async -> UIImage? {
        try? await scanner?.capturePhoto()
    }

    func dataScanner(
        _ scanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    ) {
        switch item {
        case .text(let text):
            onTextTapped(text.transcript)
        default:
            break
        }
    }

    func dataScanner(
        _ scanner: DataScannerViewController,
        didAdd items: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        for item in items {
            addHighlight(for: item, in: scanner)
        }
    }

    func dataScanner(
        _ scanner: DataScannerViewController,
        didUpdate items: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        for item in items {
            updateHighlight(for: item)
        }
    }

    func dataScanner(
        _ scanner: DataScannerViewController,
        didRemove items: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        for item in items {
            removeHighlight(for: item.id)
        }
    }

    private func addHighlight(for item: RecognizedItem, in scanner: DataScannerViewController) {
        let view = UIView()
        view.layer.borderColor = UIColor.systemYellow.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 6
        view.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
        view.frame = boundingRect(for: item.bounds)
        scanner.overlayContainerView.addSubview(view)
        highlightViews[item.id] = view
    }

    private func updateHighlight(for item: RecognizedItem) {
        let rect = boundingRect(for: item.bounds)
        UIView.animate(withDuration: 0.15) {
            self.highlightViews[item.id]?.frame = rect
        }
    }

    private func boundingRect(for bounds: RecognizedItem.Bounds) -> CGRect {
        let xs = [bounds.topLeft.x, bounds.topRight.x, bounds.bottomLeft.x, bounds.bottomRight.x]
        let ys = [bounds.topLeft.y, bounds.topRight.y, bounds.bottomLeft.y, bounds.bottomRight.y]
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        let maxX = xs.max() ?? 0
        let maxY = ys.max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            .insetBy(dx: -4, dy: -4)
    }

    private func removeHighlight(for id: RecognizedItem.ID) {
        highlightViews[id]?.removeFromSuperview()
        highlightViews.removeValue(forKey: id)
    }
}
