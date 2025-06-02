//
//  FuelStation.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 02/06/25.
//

import Foundation
import CoreLocation


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
