import Foundation
import CoreLocation

struct BrakingEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let deceleration: Double
    let speed: Int?
    var intensity: Double = 0
    var location: CLLocation?
    var address: String = ""
    var fuelUsedLiters: Double = 0
    var fuelCost: Double = 0.0
}

struct FuelStation: Identifiable {
    let id = UUID()
    let gestore: String
    let indirizzo: String
    let prezzo: String
    let selfService: Bool
    let data: String
    let distanza: Double
    let latitudine: Double
    let longitudine: Double
}

struct FuelStationRaw: Codable {
    let gestore: String
    let indirizzo: String
    let prezzo: String
    let selfService: String?
    let data: String
    let distanza: String
    let latitudine: String
    let longitudine: String
}
