//
//  BrakingViewModel.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 17/05/25.
//



import Foundation
import CoreLocation
import Combine

class BrakingViewModel: ObservableObject {
    @Published var brakingEvents: [BrakingEvent] = []
    @Published var isBraking = false
    @Published var brakingIntensity: Double = 0
    
    private var previousSpeed: Int = 0
    private var previousRPM: Int = 0
    private var previousFuelPressure: Int = 0
    private var lastUpdateTime = Date()
    
    // Soglie di rilevamento
    private let speedDecelThreshold = 10.0 // km/h/s
    private let rpmDropThreshold = 500 // RPM/s
    private let fuelPressureThreshold = 20 // Unità/s
    
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
        let timeDelta = now.timeIntervalSince(lastUpdateTime)
        
        // Filtra intervalli non validi
        guard timeDelta > 0.1 && timeDelta < 2 else {
            previousSpeed = newSpeed
            lastUpdateTime = now
            return
        }
        
        // Calcola le variazioni
        let speedDelta = previousSpeed - newSpeed
        let decelerationRate = Double(speedDelta) / timeDelta
        
        // Calcola l'intensità della frenata (0-1)
        let normalizedDeceleration = min(max(decelerationRate / 30.0, 0), 1) // 30 km/h/s = frenata molto forte
        
        DispatchQueue.main.async {
            self.brakingIntensity = normalizedDeceleration
        }
        
        // Rileva frenata brusca
        if decelerationRate > speedDecelThreshold {
            handleBrakingEvent(decelerationRate: decelerationRate, speed: newSpeed)
        }
        
        previousSpeed = newSpeed
        lastUpdateTime = now
    }
    
    private func handleBrakingEvent(decelerationRate: Double, speed: Int) {
        isBraking = true
        
        // Aggiungi evento solo se non c'è già un evento recente
        if brakingEvents.last == nil || Date().timeIntervalSince(brakingEvents.last!.timestamp) > 3 {
            let event = BrakingEvent(
                timestamp: Date(),
                deceleration: decelerationRate,
                speed: speed,
                intensity: brakingIntensity
            )
            brakingEvents.append(event)
        }
        
        // Reset dopo 2 secondi
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
