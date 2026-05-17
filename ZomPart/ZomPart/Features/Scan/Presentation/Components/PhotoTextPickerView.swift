import SwiftUI
import SBDesignSystem
import Vision

struct PhotoTextPickerView: View {

    let image: UIImage
    let onTextsSelected: ([String]) -> Void
    let onDismiss: () -> Void

    @State private var detectedTexts: [DetectedTextItem] = []
    @State private var selectedTexts: [String] = []
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let displayRect = imageDisplayRect(in: geo.size)

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ForEach(detectedTexts) { item in
                        let rect = convertBoundingBox(item.boundingBox, imageDisplayRect: displayRect)
                        Button {
                            toggleSelection(item.text)
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    selectedTexts.contains(item.text) ? Color.sbStatusSuccess : Color.yellow,
                                    lineWidth: selectedTexts.contains(item.text) ? 4 / scale : 3 / scale
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            selectedTexts.contains(item.text)
                                            ? Color.sbStatusSuccess.opacity(0.2)
                                            : Color.yellow.opacity(0.15)
                                        )
                                )
                        }
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = max(1.0, min(lastScale * value.magnification, 5.0))
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale <= 1.0 {
                                withAnimation(.spring(duration: 0.3)) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    guard scale > 1.0 else { return }
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.5
                            lastScale = 2.5
                        }
                    }
                }
            }

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .statusBarHidden()
        .task {
            await detectTexts()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }

            Spacer()

            if !selectedTexts.isEmpty {
                Button {
                    onTextsSelected(selectedTexts)
                    onDismiss()
                } label: {
                    Text(Localized.Common.done.localized)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(.white)
                        .sbHorizontalPadding(.large)
                        .sbControlHeight(.compact)
                        .background(Color.sbStatusSuccess)
                        .sbCornerRadius(.medium)
                }
            }
        }
        .padding()
        .padding(.top, 44)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if !selectedTexts.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(selectedTexts.enumerated()), id: \.offset) { _, text in
                        HStack {
                            Text(text)
                                .font(.sbBodyRegularSmall)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Button {
                                toggleSelection(text)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.sbBodyRegularXSmall)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .sbPadding(.small)
                        .background(Color.sbStatusSuccess.opacity(0.8))
                        .sbCornerRadius(.small)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 60)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func toggleSelection(_ text: String) {
        if let index = selectedTexts.firstIndex(of: text) {
            selectedTexts.remove(at: index)
        } else {
            selectedTexts.append(text)
        }
    }

    private func detectTexts() async {
        guard let cgImage = image.cgImage else { return }

        let orientation = cgImageOrientation(from: image.imageOrientation)

        do {
            let texts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DetectedTextItem], Error>) in
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: [])
                        return
                    }

                    let items = observations.compactMap { obs -> DetectedTextItem? in
                        guard let candidate = obs.topCandidates(1).first else { return nil }
                        return DetectedTextItem(
                            text: candidate.string,
                            boundingBox: obs.boundingBox
                        )
                    }
                    continuation.resume(returning: items)
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation,
                    options: [:]
                )
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            detectedTexts = texts
        } catch {
            detectedTexts = []
        }
    }

    private func imageDisplayRect(in containerSize: CGSize) -> CGRect {
        let imageAspect = image.size.width / image.size.height
        let containerAspect = containerSize.width / containerSize.height

        let displayWidth: CGFloat
        let displayHeight: CGFloat

        if imageAspect > containerAspect {
            displayWidth = containerSize.width
            displayHeight = containerSize.width / imageAspect
        } else {
            displayHeight = containerSize.height
            displayWidth = containerSize.height * imageAspect
        }

        let offsetX = (containerSize.width - displayWidth) / 2
        let offsetY = (containerSize.height - displayHeight) / 2

        return CGRect(x: offsetX, y: offsetY, width: displayWidth, height: displayHeight)
    }

    private func convertBoundingBox(_ box: CGRect, imageDisplayRect: CGRect) -> CGRect {
        let x = imageDisplayRect.origin.x + box.origin.x * imageDisplayRect.width
        let y = imageDisplayRect.origin.y + (1 - box.origin.y - box.height) * imageDisplayRect.height
        let w = box.width * imageDisplayRect.width
        let h = box.height * imageDisplayRect.height

        return CGRect(x: x, y: y, width: w, height: h).insetBy(dx: -3, dy: -3)
    }

    private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

struct DetectedTextItem: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
}
