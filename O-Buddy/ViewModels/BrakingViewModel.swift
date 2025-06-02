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
    @Published var fuelPrice: Double = 0.0 // ADD: Make fuelPrice public so it can be set by MainViewModel

    private var previousSpeed: Int = 0
    private var previousRPM: Int = 0
    private var previousFuelPressure: Int = 0
    private var lastUpdateTime = Date()
    private var speedHistory: [SpeedSample] = []
    private let speedDecelThreshold = 10.0
    private let rpmDropThreshold = 500
    private let fuelPressureThreshold = 20
    private let windowDuration: TimeInterval = 3.0
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
    
    var totalFuelUsed: Double {
        brakingEvents.map(\.fuelUsedLiters).reduce(0, +)
    }

    var totalFuelCost: Double {
        brakingEvents.map(\.fuelCost).reduce(0, +)
    }


    private func checkBrakingParameters(newSpeed: Int) {
        let now = Date()
        speedHistory.append(SpeedSample(speed: newSpeed, timestamp: now))

        speedHistory.removeAll { now.timeIntervalSince($0.timestamp) > windowDuration }

        guard let oldest = speedHistory.first else { return }

        let timeDelta = now.timeIntervalSince(oldest.timestamp)
        guard timeDelta > 0.1 else { return }

        let deltaSpeed = oldest.speed - newSpeed
        let decelerationRate = Double(deltaSpeed) / timeDelta
        let normalizedDeceleration = min(max(decelerationRate / 30.0, 0), 1)

        DispatchQueue.main.async {
            self.brakingIntensity = normalizedDeceleration
        }
        
        if decelerationRate > speedDecelThreshold {
            handleBrakingEvent(decelerationRate: decelerationRate, speed: newSpeed, vInitial: oldest.speed)
        }
        
        previousSpeed = newSpeed
        lastUpdateTime = now
    }
    
    private func handleBrakingEvent(decelerationRate: Double, speed: Int, vInitial: Int) {
        isBraking = true
        
        if brakingEvents.last == nil || Date().timeIntervalSince(brakingEvents.last!.timestamp) > 3 {
            let vInitMS = Double(vInitial) * 1000 / 3600
            let vFinalMS = Double(speed) * 1000 / 3600
            
            // ADD: Debug prints for kinetic energy calculation
            print("--- Braking Event Calculation ---")
            print("fuelPrice: \(fuelPrice) €/L")
            print("vInitial (km/h): \(vInitial), vFinal (km/h): \(speed)")
            print("vInitMS (m/s): \(vInitMS), vFinalMS (m/s): \(vFinalMS)")

            let mass = 1300.0 // kg
            let deltaEk = 0.5 * mass * (vInitMS * vInitMS - vFinalMS * vFinalMS)
            print("deltaEk (Joules): \(deltaEk)")

            let efficiency = 0.25 // Example efficiency
            let energyPerLiter = 34_000_000.0 * efficiency // Joules per liter of fuel
            print("energyPerLiter (Joules/L): \(energyPerLiter)")

            let litersUsed = max(deltaEk / energyPerLiter, 0)
            let cost = litersUsed * fuelPrice
            
            print("litersUsed: \(litersUsed) L")
            print("fuelCost: \(cost) €")
            print("---------------------------------")

            let event = BrakingEvent(
                timestamp: Date(),
                deceleration: decelerationRate,
                speed: speed,
                intensity: brakingIntensity,
                fuelUsedLiters: litersUsed,
                fuelCost: cost
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
// End of file. No additional code.
