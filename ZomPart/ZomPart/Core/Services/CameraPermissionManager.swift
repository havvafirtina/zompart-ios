import AVFoundation

@Observable
@MainActor
final class CameraPermissionManager {

  private(set) var status: AVAuthorizationStatus

  init() {
    self.status = AVCaptureDevice.authorizationStatus(for: .video)
  }

  func requestAccessIfNeeded() async -> Bool {
    switch status {
    case .authorized:
      return true
    case .notDetermined:
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      status = granted ? .authorized : .denied
      return granted
    default:
      return false
    }
  }
}
