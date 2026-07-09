import SwiftUI
import UIKit

struct CameraView: View {
    @StateObject private var camera = CameraService()

    var body: some View {
        ZStack {
            switch camera.authorizationStatus {
            case .authorized:
                cameraContent
            case .notDetermined:
                ProgressView("Starting camera…")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
            case .denied, .restricted:
                permissionDeniedView
            }
        }
        .background(.black)
        .ignoresSafeArea()
        .task {
            await camera.requestAccessIfNeeded()
        }
        .onDisappear {
            camera.stop()
        }
        .alert(
            "Camera Error",
            isPresented: Binding(
                get: { camera.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        camera.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(camera.errorMessage ?? "")
        }
    }

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            if let capturedImage = camera.capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .background(.black)
                    .transition(.opacity)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: camera.switchCamera) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .accessibilityLabel("Switch camera")
                }
                .padding()

                Spacer()

                HStack {
                    if camera.capturedImage != nil {
                        Button("Retake") {
                            withAnimation {
                                camera.clearCapturedImage()
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.45), in: Capsule())
                    }

                    Spacer()

                    Button(action: camera.capturePhoto) {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(.white)
                                .frame(width: 58, height: 58)
                        }
                    }
                    .accessibilityLabel("Capture photo")
                    .disabled(camera.capturedImage != nil)

                    Spacer()

                    if camera.capturedImage != nil {
                        Color.clear
                            .frame(width: 80, height: 44)
                    }
                }
                .padding(.bottom, 36)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.8))

            Text("Camera Access Needed")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Klik needs camera access to show the live preview. Enable it in Settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 32)

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

#Preview {
    CameraView()
}
