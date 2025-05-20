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
    private let speedDecelThreshold = 15.0 // km/h/s
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

        if brakingEvents.last == nil || Date().timeIntervalSince(brakingEvents.last!.timestamp) > 3 {
            // Conversione velocità da km/h a m/s
            let vInitial = Double(previousSpeed) * 1000 / 3600
            let vFinal = Double(speed) * 1000 / 3600
            
            // Stima massa del veicolo (es: 1300 kg)
            let mass = 1300.0
            
            // Energia cinetica persa (Joule)
            let deltaEk = 0.5 * mass * (vInitial * vInitial - vFinal * vFinal)
            
            // Potere calorifico benzina (circa 34 MJ/l), rendimento medio 25%
            let efficiency = 0.25
            let energyPerLiter = 34_000_000.0 * efficiency // J/l

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
