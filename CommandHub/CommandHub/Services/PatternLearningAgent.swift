import Foundation

/// Cursor AI pattern-learning agent: analyzes action history and generates predictions.
@MainActor
final class PatternLearningAgent: ObservableObject {
    @Published private(set) var patterns: [PatternInsight] = []
    @Published private(set) var isLearning = false
    @Published private(set) var totalActionsAnalyzed = 0

    private var historyStore: ActionHistoryStore?

    func bind(to store: ActionHistoryStore) {
        historyStore = store
        analyzePatterns(from: store.actions)
    }

    func refresh() {
        guard let store = historyStore else { return }
        analyzePatterns(from: store.actions)
    }

    /// Generate a suggestion for a detected service at the current moment.
    func suggestion(
        for service: ServiceType,
        at date: Date = Date(),
        locationLabel: String? = nil
    ) -> AgentSuggestion? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)

        guard let pattern = patterns.first(where: { $0.service == service }) else {
            if totalActionsAnalyzed >= 3 {
                return AgentSuggestion(
                    service: service,
                    message: "I'm still learning your \(service.displayName.lowercased()) habits. Keep using CommandHub!",
                    confidence: 0.35,
                    isAnomaly: false,
                    isPrediction: false
                )
            }
            return nil
        }

        let weekdayMatch = pattern.weekday == weekday
        let hourMatch = abs(pattern.hour - hour) <= 2
        let isUsualTime = weekdayMatch && hourMatch

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let todayName = formatter.string(from: date)

        if isUsualTime {
            return AgentSuggestion(
                service: service,
                message: "You're at your usual \(service.displayName.lowercased()) spot on \(todayName)s around this time. Ready to go?",
                confidence: pattern.confidence,
                isAnomaly: false,
                isPrediction: true
            )
        }

        if pattern.weekday == weekday && !hourMatch {
            return AgentSuggestion(
                service: service,
                message: "You usually use \(service.displayName.lowercased()) on \(pattern.weekdayName)s, but not at this hour — slightly unusual.",
                confidence: pattern.confidence * 0.7,
                isAnomaly: true,
                isPrediction: false
            )
        }

        if pattern.weekday != weekday {
            let locationPart = locationLabel.map { " near \($0)" } ?? ""
            return AgentSuggestion(
                service: service,
                message: "You usually use \(service.displayName.lowercased()) on \(pattern.weekdayName)s around \(pattern.timeDescription)\(locationPart), but it's \(todayName) — unusual for you.",
                confidence: pattern.confidence * 0.75,
                isAnomaly: true,
                isPrediction: false
            )
        }

        return nil
    }

    /// Predict what the user might need next based on time-of-day patterns.
    func nextPrediction(at date: Date = Date()) -> AgentSuggestion? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)

        let matches = patterns.filter {
            $0.weekday == weekday && abs($0.hour - hour) <= 1
        }.sorted { $0.confidence > $1.confidence }

        guard let best = matches.first, totalActionsAnalyzed >= 3 else { return nil }

        return AgentSuggestion(
            service: best.service,
            message: "Next you'll probably need \(best.service.displayName.lowercased()) — that's your \(best.weekdayName) pattern.",
            confidence: best.confidence,
            isAnomaly: false,
            isPrediction: true
        )
    }

    private func analyzePatterns(from actions: [UserAction]) {
        isLearning = true
        totalActionsAnalyzed = actions.count

        var buckets: [String: (service: ServiceType, weekday: Int, hour: Int, count: Int)] = [:]

        for action in actions {
            let key = "\(action.service.rawValue)-\(action.weekday)-\(action.hour)"
            if var bucket = buckets[key] {
                bucket.count += 1
                buckets[key] = bucket
            } else {
                buckets[key] = (action.service, action.weekday, action.hour, 1)
            }
        }

        let maxCount = buckets.values.map(\.count).max() ?? 1

        patterns = buckets.values
            .map { bucket in
                let confidence = min(0.95, 0.45 + (Double(bucket.count) / Double(maxCount)) * 0.5)
                return PatternInsight(
                    service: bucket.service,
                    weekday: bucket.weekday,
                    hour: bucket.hour,
                    occurrenceCount: bucket.count,
                    confidence: confidence,
                    isFromDemoData: bucket.count >= 2 && actions.count > 5
                )
            }
            .sorted { $0.confidence > $1.confidence }

        isLearning = false
    }
}
