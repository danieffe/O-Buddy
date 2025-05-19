//
//  BreakingEvent.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 17/05/25.
//

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
}
