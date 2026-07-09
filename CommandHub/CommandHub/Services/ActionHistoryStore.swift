import Foundation

@MainActor
final class ActionHistoryStore: ObservableObject {
    @Published private(set) var actions: [UserAction] = []
    @Published private(set) var learningProgress: Double = 0
    @Published private(set) var hasLoadedDemoData = false

    private let storageKey = "commandhub.actions"
    private let demoLoadedKey = "commandhub.demoLoaded"

    init() {
        load()
        hasLoadedDemoData = UserDefaults.standard.bool(forKey: demoLoadedKey)
        if !hasLoadedDemoData {
            seedDemoData()
        }
        updateLearningProgress()
    }

    func record(_ action: UserAction) {
        actions.insert(action, at: 0)
        persist()
        updateLearningProgress()
    }

    func record(service: ServiceType, location: (lat: Double?, lon: Double?, label: String?)) {
        let action = UserAction(
            service: service,
            timestamp: Date(),
            latitude: location.lat,
            longitude: location.lon,
            locationLabel: location.label
        )
        record(action)
    }

    func clearAll() {
        actions.removeAll()
        persist()
        updateLearningProgress()
    }

    func reloadDemoData() {
        actions.removeAll()
        seedDemoData()
    }

    private func seedDemoData() {
        let calendar = Calendar.current
        let now = Date()

        // Tuesday 7pm laundromat pattern (3 occurrences)
        for weekOffset in 1...3 {
            if let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
               let tuesday = nearestWeekday(.tuesday, to: date, hour: 19) {
                actions.append(UserAction(
                    service: .laundromatMachine,
                    timestamp: tuesday,
                    latitude: 51.5074,
                    longitude: -0.1278,
                    locationLabel: "Spin & Dry Laundromat, Shoreditch"
                ))
            }
        }

        // Thursday 9am parking pattern (4 occurrences)
        for weekOffset in 0...3 {
            if let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
               let thursday = nearestWeekday(.thursday, to: date, hour: 9) {
                actions.append(UserAction(
                    service: .parkingMeter,
                    timestamp: thursday,
                    latitude: 51.5155,
                    longitude: -0.1410,
                    locationLabel: "City Road Parking, London"
                ))
            }
        }

        // Hotel door — Friday evenings
        for weekOffset in 1...2 {
            if let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
               let friday = nearestWeekday(.friday, to: date, hour: 18) {
                actions.append(UserAction(
                    service: .hotelDoor,
                    timestamp: friday,
                    latitude: 51.5007,
                    longitude: -0.1246,
                    locationLabel: "The Strand Hotel"
                ))
            }
        }

        // Restaurant table — Saturday brunch
        for weekOffset in 1...2 {
            if let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
               let saturday = nearestWeekday(.saturday, to: date, hour: 11) {
                actions.append(UserAction(
                    service: .restaurantTable,
                    timestamp: saturday,
                    latitude: 51.5138,
                    longitude: -0.0984,
                    locationLabel: "Brew & Bean Café"
                ))
            }
        }

        actions.sort { $0.timestamp > $1.timestamp }
        hasLoadedDemoData = true
        UserDefaults.standard.set(true, forKey: demoLoadedKey)
        persist()
        updateLearningProgress()
    }

    private func nearestWeekday(_ weekday: Weekday, to date: Date, hour: Int) -> Date? {
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = weekday.rawValue
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)
    }

    private enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([UserAction].self, from: data)
        else { return }
        actions = decoded
    }

    private func updateLearningProgress() {
        let uniquePatterns = Set(actions.map { "\($0.service.rawValue)-\($0.weekday)-\($0.hour)" })
        learningProgress = min(1.0, Double(uniquePatterns.count) / 6.0)
    }
}
