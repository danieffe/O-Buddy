//
//  BreakingEvent.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 17/05/25.
//

import Foundation
import CoreLocation


struct BrakingEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let deceleration: Double
    let speed: Int?
    var intensity: Double = 0
    var latitude: Double?
    var longitude: Double?
    var address: String = ""
    var fuelUsedLiters: Double = 0
    var fuelCost: Double = 0.0
    var speedAtReturn: Int?

    // ADD: Initializer to support Codable and existing usage with CLLocation
    init(id: UUID = UUID(), timestamp: Date, deceleration: Double, speed: Int?, intensity: Double = 0, location: CLLocation? = nil, address: String = "", fuelUsedLiters: Double = 0, fuelCost: Double = 0.0, speedAtReturn: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.deceleration = deceleration
        self.speed = speed
        self.intensity = intensity
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.address = address
        self.fuelUsedLiters = fuelUsedLiters
        self.fuelCost = fuelCost
        self.speedAtReturn = speedAtReturn
    }

    // ADD: Computed property for CLLocation if needed for convenience
    var location: CLLocation? {
        if let lat = latitude, let lon = longitude {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }
}
