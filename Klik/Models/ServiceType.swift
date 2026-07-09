import Foundation

enum ServiceType: String, Codable, CaseIterable, Identifiable {
    case parkingMeter
    case hotelDoor
    case laundromatMachine
    case restaurantTable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .parkingMeter: return "Parking Meter"
        case .hotelDoor: return "Hotel Door"
        case .laundromatMachine: return "Laundromat Machine"
        case .restaurantTable: return "Restaurant Table"
        }
    }

    var icon: String {
        switch self {
        case .parkingMeter: return "parkingsign.circle.fill"
        case .hotelDoor: return "door.left.hand.closed"
        case .laundromatMachine: return "washer.fill"
        case .restaurantTable: return "cup.and.saucer.fill"
        }
    }

    var actionTitle: String {
        switch self {
        case .parkingMeter: return "Pay £2.50 for 2 hours"
        case .hotelDoor: return "Unlock door"
        case .laundromatMachine: return "Start wash cycle (40 min, £4)"
        case .restaurantTable: return "Order cappuccino"
        }
    }

    var successMessage: String {
        switch self {
        case .parkingMeter: return "Parking paid — 2 hours confirmed."
        case .hotelDoor: return "Door unlocked. Welcome back!"
        case .laundromatMachine: return "Wash cycle started — 40 minutes."
        case .restaurantTable: return "Cappuccino ordered — arriving shortly."
        }
    }

    /// Keywords used by Vision text recognition to identify this service.
    var recognitionKeywords: [String] {
        switch self {
        case .parkingMeter:
            return ["parking", "park", "meter", "pay", "paybyphone", "ticket", "tariff", "p&d"]
        case .hotelDoor:
            return ["hotel", "room", "keycard", "unlock", "welcome", "reception", "suite"]
        case .laundromatMachine:
            return ["wash", "laundry", "laundromat", "dryer", "cycle", "detergent", "spin"]
        case .restaurantTable:
            return ["menu", "table", "order", "cafe", "coffee", "restaurant", "cappuccino", "bar"]
        }
    }

    /// Image classification labels mapped to this service (Vision VNClassifyImageRequest).
    var classificationLabels: [String] {
        switch self {
        case .parkingMeter:
            return ["parking meter", "ticket machine", "vending machine", "payphone", "atm"]
        case .hotelDoor:
            return ["door", "doorway", "entrance", "lock", "hotel room"]
        case .laundromatMachine:
            return ["washing machine", "dryer", "laundromat", "laundry", "appliance"]
        case .restaurantTable:
            return ["table", "dining table", "restaurant", "cafe", "coffee cup", "menu"]
        }
    }
}

struct ServiceDetection: Identifiable, Equatable {
    let id = UUID()
    let service: ServiceType
    let confidence: Double
    let method: String

    var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }
}
