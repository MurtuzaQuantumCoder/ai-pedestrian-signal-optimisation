import CoreLocation
import Foundation

struct UserAction: Codable, Identifiable, Equatable {
    let id: UUID
    let service: ServiceType
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let locationLabel: String?

    init(
        id: UUID = UUID(),
        service: ServiceType,
        timestamp: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationLabel: String? = nil
    ) {
        self.id = id
        self.service = service
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.locationLabel = locationLabel
    }

    var weekday: Int {
        Calendar.current.component(.weekday, from: timestamp)
    }

    var hour: Int {
        Calendar.current.component(.hour, from: timestamp)
    }

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: timestamp)
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct PatternInsight: Identifiable, Equatable {
    let id = UUID()
    let service: ServiceType
    let weekday: Int
    let hour: Int
    let occurrenceCount: Int
    let confidence: Double
    let isFromDemoData: Bool

    var weekdayName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[weekday - 1]
    }

    var timeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    var summary: String {
        "\(service.displayName) — \(weekdayName)s around \(timeDescription)"
    }

    var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }
}

struct AgentSuggestion: Identifiable, Equatable {
    let id = UUID()
    let service: ServiceType
    let message: String
    let confidence: Double
    let isAnomaly: Bool
    let isPrediction: Bool

    var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }
}
