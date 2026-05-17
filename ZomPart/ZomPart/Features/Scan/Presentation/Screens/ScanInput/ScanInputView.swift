import SwiftUI
import SBDesignSystem
import PhotosUI

struct ScanInputView: View {

    @Bindable var viewModel: ScanInputViewModel
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCancelAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                photoSection
                ocrChips
                textInputSection
                uploadStatus
                analyzeButton
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Scan.title.localized)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localized.Common.cancel.localized) {
                    showCancelAlert = true
                }
            }
        }
        .alert(
            Localized.Scan.cancelScanTitle.localized,
            isPresented: $showCancelAlert
        ) {
            Button(Localized.Common.cancel.localized, role: .cancel) {}
            Button(Localized.Common.confirm.localized, role: .destructive) {
                // TODO: Phase 4 — call scan-start(start_over: true) and pop
            }
        } message: {
            Text(Localized.Scan.cancelScanMessage.localizedKey)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                showCamera = false
                guard let image else { return }
                Task { await viewModel.addPhoto(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.addPhoto(image)
                }
                selectedPhotoItem = nil
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localized.Scan.photosCount.localized(viewModel.totalPhotos))
                    .font(.sbBodyMediumDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                Spacer()
            }

            if !viewModel.photos.isEmpty {
                PhotoGridView(photos: viewModel.photos) { index in
                    viewModel.removePhoto(at: index)
                }
            }

            HStack {
                Button {
                    showCamera = true
                } label: {
                    Label(Localized.Scan.takePhoto.localized, systemImage: "camera.fill")
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .sbPadding(.medium)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.medium)
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(Localized.Scan.chooseFromGallery.localized, systemImage: "photo.on.rectangle")
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .sbPadding(.medium)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.medium)
                }
            }
            .disabled(viewModel.photos.count >= 8)
        }
        .sbVerticalPadding(.medium)
    }

    @ViewBuilder
    private var ocrChips: some View {
        if !viewModel.ocrTexts.isEmpty {
            VStack(alignment: .leading) {
                Text(Localized.Scan.ocrMetadata.localizedKey)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)

                FlowLayout(viewModel.ocrTexts) { text in
                    Text(text)
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextPrimary)
                        .sbPadding(.small)
                        .background(Color.sbSurfaceSecondary)
                        .sbCornerRadius(.small)
                }
            }
            .sbVerticalPadding(.small)
        }
    }

    private var textInputSection: some View {
        VStack(alignment: .leading) {
            TextField(
                Localized.Scan.descriptionPlaceholder.localized,
                text: $viewModel.inputText,
                axis: .vertical
            )
            .font(.sbBodyRegularDefault)
            .lineLimit(3...6)
            .sbPadding(.medium)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.medium)
        }
        .sbVerticalPadding(.medium)
    }

    @ViewBuilder
    private var uploadStatus: some View {
        if viewModel.state == .loading && viewModel.totalPhotos > 0 {
            VStack {
                ProgressView(value: viewModel.uploadProgress)
                    .tint(Color.sbAccentPrimary)

                Text(Localized.Scan.uploading.localized(viewModel.uploadedCount, viewModel.totalPhotos))
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)
            }
            .sbVerticalPadding(.medium)
        }
    }

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            Group {
                if viewModel.state == .loading {
                    ProgressView()
                        .tint(Color.sbTextOnAccent)
                } else {
                    Text(Localized.Scan.analyze.localizedKey)
                }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbTextOnAccent)
            .frame(maxWidth: .infinity)
            .sbControlHeight(.regular)
            .background(Color.sbAccentPrimary)
            .sbCornerRadius(.default)
        }
        .disabled(!viewModel.canAnalyze || viewModel.state == .loading)
        .sbVerticalPadding(.large)
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {

    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                content(item)
            }
        }
    }
}
