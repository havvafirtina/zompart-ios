import Foundation

enum Localized {

    enum Common: String, LocalizableContent, CaseIterable {
        case ok = "common.ok"
        case cancel = "common.cancel"
        case retry = "common.retry"
        case next = "common.next"
        case skip = "common.skip"
        case done = "common.done"
        case save = "common.save"
        case delete = "common.delete"
        case confirm = "common.confirm"
    }

    enum Tab: String, LocalizableContent, CaseIterable {
        case scan = "tab.scan"
        case garage = "tab.garage"
        case profile = "tab.profile"
    }

    enum Error: String, LocalizableContent, CaseIterable {
        case network = "error.network"
        case unknown = "error.unknown"
        case tokenExpired = "error.tokenExpired"
    }

    enum Onboarding: String, LocalizableContent, CaseIterable {
        case page1Title = "onboarding.page1.title"
        case page1Subtitle = "onboarding.page1.subtitle"
        case page2Title = "onboarding.page2.title"
        case page2Subtitle = "onboarding.page2.subtitle"
        case page3Title = "onboarding.page3.title"
        case page3Subtitle = "onboarding.page3.subtitle"
    }

    enum Garage: String, LocalizableContent, CaseIterable {
        case emptyTitle = "garage.empty.title"
        case emptySubtitle = "garage.empty.subtitle"
        case addVehicle = "garage.addVehicle"
        case scanVIN = "garage.scanVIN"
        case scanVINSubtitle = "garage.scanVIN.subtitle"
        case scanVINDescription = "garage.scanVIN.description"
        case scanPlate = "garage.scanPlate"
        case scanPlateSubtitle = "garage.scanPlate.subtitle"
        case scanPlateDescription = "garage.scanPlate.description"
        case manualEntry = "garage.manualEntry"
        case manualEntrySubtitle = "garage.manualEntry.subtitle"
        case vinPlaceholder = "garage.vin.placeholder"
        case platePlaceholder = "garage.plate.placeholder"
        case enterManually = "garage.enterManually"
        case openCamera = "garage.openCamera"
        case resolveVehicle = "garage.resolveVehicle"
        case vehicleAdded = "garage.vehicleAdded"
        case selectYear = "garage.wizard.selectYear"
        case selectMake = "garage.wizard.selectMake"
        case selectModel = "garage.wizard.selectModel"
        case selectTrim = "garage.wizard.selectTrim"
        case selectEngine = "garage.wizard.selectEngine"
        case vehicleAlreadyExists = "garage.vehicleAlreadyExists"
    }

    enum Auth: String, LocalizableContent, CaseIterable {
        case title = "auth.title"
        case subtitle = "auth.subtitle"
        case emailPlaceholder = "auth.email.placeholder"
        case firstNamePlaceholder = "auth.firstName.placeholder"
        case lastNamePlaceholder = "auth.lastName.placeholder"
        case intentSignup = "auth.intent.signup"
        case intentLogin = "auth.intent.login"
        case sendOTP = "auth.sendOTP"
        case otpTitle = "auth.otp.title"
        case otpSubtitle = "auth.otp.subtitle"
        case otpPlaceholder = "auth.otp.placeholder"
        case otpVerify = "auth.otp.verify"
        case errorValidation = "auth.error.validation"
        case errorEmailRegistered = "auth.error.emailRegistered"
        case errorEmailNotRegistered = "auth.error.emailNotRegistered"
        case errorOtpInvalid = "auth.error.otpInvalid"
        case errorNetwork = "auth.error.network"
        case errorUnknown = "auth.error.unknown"
    }

    enum Scan: String, LocalizableContent, CaseIterable {
        case title = "scan.title"
        case selectVehicle = "scan.selectVehicle"
        case noVehicles = "scan.noVehicles"
        case addVehicleFirst = "scan.addVehicleFirst"
        case startScan = "scan.startScan"
        case scanWithPhoto = "scan.scanWithPhoto"
        case scanWithPhotoSubtitle = "scan.scanWithPhoto.subtitle"
        case scanWithText = "scan.scanWithText"
        case scanWithTextSubtitle = "scan.scanWithText.subtitle"
        case howItWorks = "scan.howItWorks"
        case subtitle = "scan.subtitle"
        case takePhoto = "scan.takePhoto"
        case chooseFromGallery = "scan.chooseFromGallery"
        case descriptionPlaceholder = "scan.description.placeholder"
        case photosCount = "scan.photos.count"
        case ocrMetadata = "scan.ocr.metadata"
        case analyze = "scan.analyze"
        case uploading = "scan.uploading"
        case processing = "scan.processing"
        case processingTip1 = "scan.processing.tip1"
        case processingTip2 = "scan.processing.tip2"
        case processingTip3 = "scan.processing.tip3"
        case processingTip4 = "scan.processing.tip4"
        case resultTitle = "scan.result.title"
        case viewOffers = "scan.viewOffers"
        case disambiguationTitle = "scan.disambiguation.title"
        case disambiguationSubtitle = "scan.disambiguation.subtitle"
        case failedTitle = "scan.failed.title"
        case failedSubtitle = "scan.failed.subtitle"
        case searchByText = "scan.searchByText"
        case cancelScanTitle = "scan.cancel.title"
        case cancelScanMessage = "scan.cancel.message"
    }

    enum Offers: String, LocalizableContent, CaseIterable {
        case recommended = "offers.recommended"
        case cheapest = "offers.cheapest"
        case fastest = "offers.fastest"
        case empty = "offers.empty"
        case sponsored = "offers.sponsored"
    }
}
