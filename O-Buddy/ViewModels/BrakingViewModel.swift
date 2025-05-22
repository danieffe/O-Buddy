import Foundation
import CoreLocation
import Combine

struct SpeedSample {
    let speed: Int
    let timestamp: Date
}

class BrakingViewModel: ObservableObject {
    @Published var brakingEvents: [BrakingEvent] = []
    @Published var isBraking = false
    @Published var brakingIntensity: Double = 0
    
    private var previousRPM: Int = 0
    private var previousFuelPressure: Int = 0
    private var lastUpdateTime = Date()
    
    private var speedHistory: [SpeedSample] = []
    
    // Soglie di rilevamento
    private let speedDecelThreshold = 10.8 // km/h/s
    private let rpmDropThreshold = 500 // RPM/s
    private let fuelPressureThreshold = 20 // Unità/s
    private let windowDuration: TimeInterval = 3.0 // Durata finestra mobile in secondi
    
    private var cancellables = Set<AnyCancellable>()
    
    init(speedPublisher: Published<Int>.Publisher,
         rpmPublisher: Published<Int>.Publisher,
         fuelPressurePublisher: Published<Int>.Publisher) {
        
        speedPublisher
            .sink { [weak self] newSpeed in
                self?.checkBrakingParameters(newSpeed: newSpeed)
            }
            .store(in: &cancellables)
        
        rpmPublisher
            .sink { [weak self] newRPM in
                self?.previousRPM = newRPM
            }
            .store(in: &cancellables)
        
        fuelPressurePublisher
            .sink { [weak self] newPressure in
                self?.previousFuelPressure = newPressure
            }
            .store(in: &cancellables)
    }
    
    private func checkBrakingParameters(newSpeed: Int) {
        let now = Date()
        
        // Aggiunge nuovo valore alla cronologia
        speedHistory.append(SpeedSample(speed: newSpeed, timestamp: now))
        
        // Rimuove campioni più vecchi della finestra temporale
        speedHistory.removeAll { now.timeIntervalSince($0.timestamp) > windowDuration }
        
        // Controlla se c'è un valore più vecchio da confrontare
        guard let oldest = speedHistory.first else { return }
        
        let deltaSpeed = oldest.speed - newSpeed
        let timeDelta = now.timeIntervalSince(oldest.timestamp)
        
        // Evita divisioni per 0
        guard timeDelta > 0.1 else { return }
        
        let decelerationRate = Double(deltaSpeed) / timeDelta
        let normalizedDeceleration = min(max(decelerationRate / 30.0, 0), 1)
        
        DispatchQueue.main.async {
            self.brakingIntensity = normalizedDeceleration
        }
        
        if decelerationRate > speedDecelThreshold {
            handleBrakingEvent(decelerationRate: decelerationRate, speed: newSpeed, vInitial: oldest.speed)
        }
    }
    
    private func handleBrakingEvent(decelerationRate: Double, speed: Int, vInitial: Int) {
        isBraking = true

        if brakingEvents.last == nil || Date().timeIntervalSince(brakingEvents.last!.timestamp) > 3 {
            // Conversione velocità da km/h a m/s
            let vInitMS = Double(vInitial) * 1000 / 3600
            let vFinalMS = Double(speed) * 1000 / 3600
            
            let mass = 1300.0
            let deltaEk = 0.5 * mass * (vInitMS * vInitMS - vFinalMS * vFinalMS)
            
            let efficiency = 0.25
            let energyPerLiter = 34_000_000.0 * efficiency
            let litersUsed = max(deltaEk / energyPerLiter, 0)

            let event = BrakingEvent(
                timestamp: Date(),
                deceleration: decelerationRate,
                speed: speed,
                intensity: brakingIntensity,
                fuelUsedLiters: litersUsed
            )
            brakingEvents.append(event)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isBraking = false
        }
    }

    func addLocationToLastEvent(_ location: CLLocation?, address: String) {
        guard !brakingEvents.isEmpty else { return }
        brakingEvents[brakingEvents.count - 1].location = location
        brakingEvents[brakingEvents.count - 1].address = address
    }
}
