import SwiftUI
import SBDesignSystem
import PhotosUI

struct ScanInputView: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ScanInputViewModel
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCancelAlert = false
    @State private var galleryImageForPreview: IdentifiableImage?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        photoSection
                        ocrChips
                        textInputSection
                            .id("textInput")
                        uploadStatus
                    }
                    .sbPadding(.large)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isTextFieldFocused) { _, focused in
                    if focused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo("textInput", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            if !isTextFieldFocused {
                analyzeButton
                    .sbHorizontalPadding(.large)
                    .sbVerticalPadding(.medium)
                    .background(Color.sbSurfacePrimary)
            }
        }
        .background(Color.sbSurfacePrimary)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .navigationTitle(Localized.Scan.title.localized)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.hasInput {
                        showCancelAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
        .alert(
            Localized.Scan.cancelScanTitle.localized,
            isPresented: $showCancelAlert
        ) {
            Button(Localized.Common.cancel.localized, role: .cancel) {}
            Button(Localized.Common.confirm.localized, role: .destructive) {
                dismiss()
            }
        } message: {
            Text(Localized.Scan.cancelScanMessage.localizedKey)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ScanCameraView(
                maxPhotos: 8,
                currentPhotoCount: viewModel.photos.count,
                onPhotosCaptured: { photos in
                    for photo in photos {
                        viewModel.addPhoto(photo)
                    }
                },
                onTextRecognized: { text in
                    viewModel.addOCRText(text)
                },
                onDismiss: {
                    showCamera = false
                }
            )
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.addPhoto(image)
                    galleryImageForPreview = IdentifiableImage(image: image)
                }
                selectedPhotoItem = nil
            }
        }
        .fullScreenCover(item: $galleryImageForPreview) { wrapper in
            PhotoTextPickerView(
                image: wrapper.image,
                onTextsSelected: { texts in
                    for text in texts {
                        viewModel.addOCRText(text)
                    }
                },
                onDismiss: {
                    galleryImageForPreview = nil
                }
            )
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

            HStack(spacing: 16) {
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

                ForEach(Array(viewModel.ocrTexts.enumerated()), id: \.offset) { index, text in
                    HStack {
                        Text(text)
                            .font(.sbBodyRegularSmall)
                            .foregroundStyle(Color.sbTextPrimary)

                        Button {
                            viewModel.removeOCRText(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.sbBodyRegularXSmall)
                                .foregroundStyle(Color.sbTextTertiary)
                        }
                    }
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
            .focused($isTextFieldFocused)
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
    }
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
