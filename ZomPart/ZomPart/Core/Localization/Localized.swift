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
}
