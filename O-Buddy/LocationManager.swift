//
//  LocationManager.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 02/06/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // CHANGE: Change location type from CLLocationCoordinate2D? to CLLocation?
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest

        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            print("⚠️ Autorizzazione alla localizzazione negata o limitata.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, location.horizontalAccuracy > 0 {
            print("📍 Posizione aggiornata: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            // CHANGE: Assign the full CLLocation object
            self.location = location
            // manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Errore localizzazione: \(error.localizedDescription)")
    }

    // ADD: Handle authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            print("✅ Autorizzazione alla localizzazione concessa. Avvio aggiornamenti posizione.")
        case .denied, .restricted:
            print("⚠️ Autorizzazione alla localizzazione negata o limitata dopo il cambiamento.")
        case .notDetermined:
            break // Authorization request already sent
        @unknown default:
            break
        }
    }
}
// End of file. No additional code.
