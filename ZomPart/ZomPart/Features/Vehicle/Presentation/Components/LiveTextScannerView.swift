import SwiftUI
import VisionKit

struct LiveTextScannerView: UIViewControllerRepresentable {

  let onTextRecognized: (String) -> Void
  let onDismiss: () -> Void

  static var isDeviceSupported: Bool {
    DataScannerViewController.isSupported
  }

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
    return scanner
  }

  func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
    if !scanner.isScanning {
      try? scanner.startScanning()
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onTextRecognized: onTextRecognized, onDismiss: onDismiss)
  }

  final class Coordinator: NSObject, DataScannerViewControllerDelegate {
    let onTextRecognized: (String) -> Void
    let onDismiss: () -> Void
    weak var scanner: DataScannerViewController?
    private var highlightViews: [RecognizedItem.ID: UIView] = [:]

    init(onTextRecognized: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
      self.onTextRecognized = onTextRecognized
      self.onDismiss = onDismiss
    }

    func dataScanner(
      _ scanner: DataScannerViewController,
      didTapOn item: RecognizedItem
    ) {
      switch item {
      case .text(let text):
        scanner.stopScanning()
        removeAllHighlights()
        onTextRecognized(text.transcript)
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

    private func removeAllHighlights() {
      highlightViews.values.forEach { $0.removeFromSuperview() }
      highlightViews.removeAll()
    }
  }
}
