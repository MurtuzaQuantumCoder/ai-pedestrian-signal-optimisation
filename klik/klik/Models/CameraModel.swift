import AVFoundation
import SwiftUI

@MainActor
final class CameraModel: ObservableObject {
    enum AuthorizationState {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    @Published private(set) var authorizationState: AuthorizationState = .notDetermined
    @Published private(set) var isSessionRunning = false
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.klik.camera.session")

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationState = .authorized
            await configureAndStartSession()
        case .notDetermined:
            authorizationState = .notDetermined
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .authorized : .denied
            if granted {
                await configureAndStartSession()
            }
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        @unknown default:
            authorizationState = .denied
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            Task { @MainActor in
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }

    private func configureAndStartSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.session.beginConfiguration()
                defer { self.session.commitConfiguration() }

                self.session.sessionPreset = .photo

                do {
                    try self.configureVideoInput()
                    try self.configurePhotoOutput()
                    self.errorMessage = nil
                } catch {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume()
                    return
                }

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                Task { @MainActor in
                    self.isSessionRunning = self.session.isRunning
                }

                continuation.resume()
            }
        }
    }

    private func configureVideoInput() throws {
        session.inputs.forEach { session.removeInput($0) }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCameraAvailable
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }

        session.addInput(input)
    }

    private func configurePhotoOutput() throws {
        session.outputs.forEach { session.removeOutput($0) }

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }

        session.addOutput(output)
    }
}

enum CameraError: LocalizedError {
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "No back camera is available on this device."
        case .cannotAddInput:
            return "Unable to add the camera input to the capture session."
        case .cannotAddOutput:
            return "Unable to add the photo output to the capture session."
        }
    }
}
