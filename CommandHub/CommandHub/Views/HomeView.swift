import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var history: ActionHistoryStore
    @EnvironmentObject private var agent: PatternLearningAgent

    @State private var showScanner = false
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.12, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        header
                        locationCard
                        scanButton
                        if let prediction = agent.nextPrediction() {
                            predictionCard(prediction)
                        }
                        learningCard
                        quickServices
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("CommandHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Label("History", systemImage: "brain.head.profile")
                    }
                    .foregroundStyle(.white)
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                CameraScanView()
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Universal Remote")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Point at any service — parking, doors, machines, tables.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var locationCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "location.fill")
                .font(.title2)
                .foregroundStyle(.cyan)
                .frame(width: 44, height: 44)
                .background(.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Location")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(location.locationLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
    }

    private var scanButton: some View {
        Button {
            showScanner = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.4), .blue.opacity(0.1)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .strokeBorder(.cyan.opacity(0.6), lineWidth: 3)
                        .frame(width: 120, height: 120)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }

                Text("Scan Service")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Point your phone at a parking meter, door, machine, or table")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.cyan.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func predictionCard(_ suggestion: AgentSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("AI Prediction")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                Spacer()
                ConfidenceBadge(confidence: suggestion.confidence)
            }

            Text(suggestion.message)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.yellow.opacity(0.3)))
    }

    private var learningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: agent.isLearning ? "arrow.triangle.2.circlepath" : "brain")
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse, isActive: agent.isLearning)
                Text("Cursor AI Learning")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(agent.patterns.count) patterns")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            ProgressView(value: history.learningProgress)
                .tint(.purple)

            Text(learningStatusText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.purple.opacity(0.3)))
    }

    private var learningStatusText: String {
        let count = history.actions.count
        if count < 3 {
            return "Learning your habits… \(count)/3 actions to unlock predictions."
        } else if history.learningProgress < 0.5 {
            return "Building your profile from \(count) actions."
        } else {
            return "Profile active — predicting based on \(agent.patterns.count) learned patterns."
        }
    }

    private var quickServices: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demo Services")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ServiceType.allCases) { service in
                    NavigationLink {
                        ServiceActionView(
                            detection: ServiceDetection(service: service, confidence: 1.0, method: "manual"),
                            isManualSelection: true
                        )
                    } label: {
                        ServiceChip(service: service)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ServiceChip: View {
    let service: ServiceType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: service.icon)
                .font(.title3)
                .foregroundStyle(.cyan)
            Text(service.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environmentObject(LocationService())
        .environmentObject(ActionHistoryStore())
        .environmentObject(PatternLearningAgent())
}
