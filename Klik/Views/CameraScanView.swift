import SwiftUI

struct CameraScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var location: LocationService

    @StateObject private var camera = CameraSessionProvider()
    @State private var detections: [ServiceDetection] = []
    @State private var isScanning = false
    @State private var selectedDetection: ServiceDetection?
    @State private var showManualPicker = false
    @State private var scanStatus = "Point at a service…"

    var body: some View {
        NavigationStack {
            ZStack {
                if camera.authorizationStatus == .authorized {
                    CameraPreviewRepresentable(session: camera.session)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                    permissionView
                }

                scanOverlay

                if let detection = selectedDetection ?? detections.first {
                    VStack {
                        Spacer()
                        detectionBanner(detection)
                            .padding(.bottom, 120)
                    }
                }

                VStack {
                    Spacer()
                    controlBar
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Manual") { showManualPicker = true }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .task {
                await camera.requestAccessIfNeeded()
            }
            .onDisappear { camera.stop() }
            .sheet(item: $selectedDetection) { detection in
                NavigationStack {
                    ServiceActionView(detection: detection)
                }
            }
            .confirmationDialog("Select Service", isPresented: $showManualPicker, titleVisibility: .visible) {
                ForEach(ServiceType.allCases) { service in
                    Button(service.displayName) {
                        selectedDetection = ServiceDetection(service: service, confidence: 1.0, method: "manual")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
            Text("Camera access required to scan services.")
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding()
    }

    private var scanOverlay: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.cyan.opacity(0.8), lineWidth: 2)
                .frame(width: 280, height: 280)
                .overlay(alignment: .top) {
                    Text(scanStatus)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6), in: Capsule())
                        .foregroundStyle(.white)
                        .offset(y: -36)
                }
                .padding(.top, 100)

            if !detections.isEmpty {
                detectionChips
                    .padding(.top, 24)
            }

            Spacer()
        }
    }

    private var detectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(detections) { detection in
                    Button {
                        selectedDetection = detection
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: detection.service.icon)
                            Text(detection.service.displayName)
                            Text("\(detection.confidencePercent)%")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.cyan.opacity(0.3), in: Capsule())
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15), in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func detectionBanner(_ detection: ServiceDetection) -> some View {
        Button {
            selectedDetection = detection
        } label: {
            HStack {
                Image(systemName: detection.service.icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detected: \(detection.service.displayName)")
                        .font(.headline)
                    Text("\(detection.confidencePercent)% confidence via \(detection.method)")
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(.cyan.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.cyan.opacity(0.5)))
            .padding(.horizontal, 20)
        }
    }

    private var controlBar: some View {
        HStack(spacing: 40) {
            Button {
                detections = []
                scanStatus = "Point at a service…"
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.15), in: Circle())
            }

            Button {
                Task { await performScan() }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 76, height: 76)
                    if isScanning {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Circle()
                            .fill(.cyan)
                            .frame(width: 62, height: 62)
                        Image(systemName: "viewfinder")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(isScanning || camera.authorizationStatus != .authorized)

            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.bottom, 40)
    }

    private func performScan() async {
        isScanning = true
        scanStatus = "Analyzing…"
        defer { isScanning = false }

        if let image = await camera.capturePhoto() {
            let results = await CameraRecognitionService.recognize(in: image)
            detections = results

            if let best = results.first {
                scanStatus = "Found \(best.service.displayName)"
            } else {
                scanStatus = "No match — try Manual or reposition"
            }
        } else {
            scanStatus = "Capture failed — try again"
        }
    }
}

#Preview {
    CameraScanView()
        .environmentObject(LocationService())
}
