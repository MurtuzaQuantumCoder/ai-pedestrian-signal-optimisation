import AVFoundation
import UIKit

@MainActor
final class CameraService: NSObject, ObservableObject {
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published private(set) var isSessionRunning = false
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.klik.camera.session")
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDeviceInput: AVCaptureDeviceInput?
    private var isConfigured = false

    override init() {
        super.init()
        authorizationStatus = Self.mapAuthorization(AVCaptureDevice.authorizationStatus(for: .video))
    }

    func requestAccessIfNeeded() async {
        switch authorizationStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                await configureAndStart()
            }
        case .authorized:
            await configureAndStart()
        case .denied, .restricted:
            break
        }
    }

    func configureAndStart() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                if !self.isConfigured {
                    self.configureSession()
                }

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                Task { @MainActor in
                    self.isSessionRunning = self.session.isRunning
                    continuation.resume()
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()

            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let settings = AVCapturePhotoSettings()
            if self.photoOutput.supportedFlashModes.contains(.auto) {
                settings.flashMode = .auto
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            if let currentDeviceInput {
                self.session.removeInput(currentDeviceInput)
            }

            let newPosition: AVCaptureDevice.Position
            if let currentDeviceInput {
                newPosition = currentDeviceInput.device.position == .back ? .front : .back
            } else {
                newPosition = .back
            }

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                return
            }

            self.session.addInput(input)
            self.currentDeviceInput = input
        }
    }

    func clearCapturedImage() {
        capturedImage = nil
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            Task { @MainActor in
                errorMessage = "Unable to access the camera."
            }
            return
        }

        session.addInput(input)
        currentDeviceInput = input

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        session.commitConfiguration()
        isConfigured = true
    }

    private static func mapAuthorization(_ status: AVAuthorizationStatus) -> AuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            Task { @MainActor in
                self.errorMessage = error.localizedDescription
            }
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            Task { @MainActor in
                self.errorMessage = "Could not process the captured photo."
            }
            return
        }

        Task { @MainActor in
            self.capturedImage = image
        }
    }
}
