import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    
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
            self.location = location.coordinate
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Errore localizzazione: \(error.localizedDescription)")
    }
}
