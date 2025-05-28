LOCATION MANAGER

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.first?.coordinate {
            print("\u{1F4CD} Posizione aggiornata: \(coordinate.latitude), \(coordinate.longitude)")
            location = coordinate
        }
        manager.stopUpdatingLocation()
    }
}