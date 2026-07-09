import AVFoundation
import UIKit

@MainActor
final class CameraSessionProvider: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRunning = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.klik.camera")
    private var photoOutput: AVCapturePhotoOutput?
    private var photoDelegate: PhotoCaptureDelegate?
    private var isConfigured = false

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccessIfNeeded() async {
        switch authorizationStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
            if granted { await start() }
        case .authorized:
            await start()
        default:
            break
        }
    }

    func start() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }
                if !self.isConfigured { self.configure() }
                if !self.session.isRunning { self.session.startRunning() }
                Task { @MainActor in
                    self.isRunning = self.session.isRunning
                    continuation.resume()
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            Task { @MainActor in
                self?.isRunning = false
            }
        }
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }

                let output: AVCapturePhotoOutput
                if let existing = self.photoOutput {
                    output = existing
                } else {
                    let newOutput = AVCapturePhotoOutput()
                    if self.session.canAddOutput(newOutput) {
                        self.session.beginConfiguration()
                        self.session.addOutput(newOutput)
                        self.session.commitConfiguration()
                        self.photoOutput = newOutput
                        output = newOutput
                    } else {
                        continuation.resume(returning: nil)
                        return
                    }
                }

                let delegate = PhotoCaptureDelegate { [weak self] image in
                    self?.photoDelegate = nil
                    continuation.resume(returning: image)
                }
                self.photoDelegate = delegate
                output.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
            }
        }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.commitConfiguration()
        isConfigured = true
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
