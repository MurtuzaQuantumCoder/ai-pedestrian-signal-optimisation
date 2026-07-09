import SwiftUI

struct ServiceActionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var history: ActionHistoryStore
    @EnvironmentObject private var agent: PatternLearningAgent

    let detection: ServiceDetection
    var isManualSelection: Bool = false

    @State private var isCompleting = false
    @State private var showSuccess = false
    @State private var successMessage = ""

    private var suggestion: AgentSuggestion? {
        agent.suggestion(
            for: detection.service,
            locationLabel: location.locationLabel
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.10, green: 0.14, blue: 0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                serviceHeader
                detectionInfo

                if let suggestion {
                    suggestionCard(suggestion)
                }

                Spacer()

                actionButton

                if showSuccess {
                    successBanner
                }
            }
            .padding(24)
        }
        .navigationTitle(detection.service.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isManualSelection {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            agent.refresh()
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: detection.service.icon)
                .font(.system(size: 56))
                .foregroundStyle(.cyan)
                .frame(width: 100, height: 100)
                .background(.cyan.opacity(0.15), in: Circle())

            Text(detection.service.displayName)
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(location.locationLabel)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 16)
    }

    private var detectionInfo: some View {
        HStack {
            Label("Recognition", systemImage: "eye.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            ConfidenceBadge(confidence: detection.confidence)
            Text(detection.method)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func suggestionCard(_ suggestion: AgentSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: suggestion.isAnomaly ? "exclamationmark.triangle.fill" : "sparkles")
                    .foregroundStyle(suggestion.isAnomaly ? .orange : .yellow)
                Text(suggestion.isAnomaly ? "Unusual Pattern" : "AI Suggestion")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(suggestion.isAnomaly ? .orange : .yellow)
                Spacer()
                ConfidenceBadge(confidence: suggestion.confidence)
            }

            Text(suggestion.message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            (suggestion.isAnomaly ? Color.orange : Color.yellow).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((suggestion.isAnomaly ? Color.orange : Color.yellow).opacity(0.3))
        )
    }

    private var actionButton: some View {
        Button {
            completeAction()
        } label: {
            HStack {
                if isCompleting {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "bolt.fill")
                    Text(detection.service.actionTitle)
                        .fontWeight(.bold)
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.cyan, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isCompleting)
    }

    private var successBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(successMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func completeAction() {
        isCompleting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            history.record(
                service: detection.service,
                location: (
                    lat: location.currentLocation?.coordinate.latitude,
                    lon: location.currentLocation?.coordinate.longitude,
                    label: location.locationLabel
                )
            )
            agent.refresh()

            successMessage = detection.service.successMessage
            withAnimation { showSuccess = true }
            isCompleting = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !isManualSelection {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ServiceActionView(
            detection: ServiceDetection(service: .parkingMeter, confidence: 0.87, method: "vision + text")
        )
    }
    .environmentObject(LocationService())
    .environmentObject(ActionHistoryStore())
    .environmentObject(PatternLearningAgent())
}
