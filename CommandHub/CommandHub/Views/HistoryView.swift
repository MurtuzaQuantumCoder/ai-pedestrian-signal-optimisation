import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var history: ActionHistoryStore
    @EnvironmentObject private var agent: PatternLearningAgent

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.09, blue: 0.16).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        learningSection
                        patternsSection
                        actionsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("AI History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reload demo data") {
                            history.reloadDemoData()
                            agent.refresh()
                        }
                        Button("Clear all", role: .destructive) {
                            history.clearAll()
                            agent.refresh()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learning Progress", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundStyle(.purple)

            ProgressView(value: history.learningProgress)
                .tint(.purple)

            HStack {
                statBox(title: "Actions", value: "\(history.actions.count)")
                statBox(title: "Patterns", value: "\(agent.patterns.count)")
                statBox(title: "Analyzed", value: "\(agent.totalActionsAnalyzed)")
            }

            Text(progressDescription)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private var progressDescription: String {
        if history.actions.count < 3 {
            return "After 3 actions, CommandHub starts predicting your next need."
        }
        return "Cursor AI has built a profile from your action history and demo patterns."
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learned Patterns")
                .font(.headline)
                .foregroundStyle(.white)

            if agent.patterns.isEmpty {
                Text("No patterns yet — complete a few actions to start learning.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                ForEach(agent.patterns) { pattern in
                    HStack(spacing: 12) {
                        Image(systemName: pattern.service.icon)
                            .foregroundStyle(.cyan)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.summary)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(pattern.occurrenceCount)× observed")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()
                        ConfidenceBadge(confidence: pattern.confidence)
                    }
                    .padding(12)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Log")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(history.actions.prefix(20)) { action in
                HStack(spacing: 12) {
                    Image(systemName: action.service.icon)
                        .foregroundStyle(.cyan)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.service.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text(action.timeLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        if let label = action.locationLabel {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                Divider().overlay(.white.opacity(0.1))
            }
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    HistoryView()
        .environmentObject(ActionHistoryStore())
        .environmentObject(PatternLearningAgent())
}
