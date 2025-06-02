//
//  FuelStationRaw.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 02/06/25.
//

import Foundation
import CoreLocation

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
