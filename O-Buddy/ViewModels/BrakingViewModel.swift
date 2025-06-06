//
//  BrakingViewModel.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 17/05/25.
//


import Foundation
import CoreLocation
import Combine
import SwiftUI // ADD: Import SwiftUI for @AppStorage

class BrakingViewModel: ObservableObject {
@Published var brakingEvents: [BrakingEvent] = []
@Published var isBraking = false
@Published var brakingIntensity: Double = 0
@Published var fuelPrice: Double = 0.0
@Published var expandedEventId: UUID?

// ADD: Read vehicle mass from AppStorage
@AppStorage("vehicleMass") private var storedVehicleMass: String = ""

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

// Track the ID of the currently active braking event for updating speedAtReturn
private var activeBrakingEventId: UUID?
// LocationManager instance to access current location
private var locationManager: LocationManager
// CLGeocoder instance for reverse geocoding
private let geocoder = CLGeocoder()

private let userDefaultsKey = "brakingEvents" // ADD

init(
  // CHANGE: Changed parameter types to AnyPublisher
  speedPublisher: AnyPublisher<Int, Never>,
  // CHANGE: Changed parameter types to AnyPublisher
  rpmPublisher: AnyPublisher<Int, Never>,
  // CHANGE: Changed parameter types to AnyPublisher
  fuelPressurePublisher: AnyPublisher<Int, Never>,
  locationManager: LocationManager = LocationManager()
) {
  
  self.locationManager = locationManager // Store the passed LocationManager
  
  loadBrakingEvents() // ADD: Load events on init

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
  
  // ADD: Save events whenever brakingEvents changes
  $brakingEvents
      .debounce(for: .seconds(1), scheduler: DispatchQueue.main) // Debounce to avoid frequent saves
      .sink { [weak self] _ in
          self?.saveBrakingEvents()
      }
      .store(in: &cancellables)
}

var totalFuelUsed: Double {
  brakingEvents.map(\.fuelUsedLiters).reduce(0, +)
}

var totalFuelCost: Double {
  brakingEvents.map(\.fuelCost).reduce(0, +)
}

// ADD: Computed property to calculate daily braking events count
var dailyBrakingEventsCount: Int {
  let calendar = Calendar.current
  let today = Date()
  return brakingEvents.filter { event in
      calendar.isDate(event.timestamp, inSameDayAs: today)
  }.count
}

// ADD: Computed property to calculate daily fuel cost
var dailyFuelCost: Double {
  let calendar = Calendar.current
  let today = Date()
  let todayEvents = brakingEvents.filter { event in
      calendar.isDate(event.timestamp, inSameDayAs: today)
  }
  return todayEvents.map(\.fuelCost).reduce(0, +)
}

// ADD: Helper functions to get the start of different periods
private func getStartOfWeek(for date: Date) -> Date {
  let calendar = Calendar.current
  var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
  // Ensure it starts on the first weekday (e.g., Monday for many locales)
  components.weekday = calendar.firstWeekday
  return calendar.date(from: components) ?? date // Fallback to current date if calculation fails
}

private func getStartOfMonth(for date: Date) -> Date {
  let calendar = Calendar.current
  return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date // Fallback
}

private func getStartOfYear(for date: Date) -> Date {
  let calendar = Calendar.current
  return calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date // Fallback
}

// ADD: Computed properties for WEEKLY fuel lost and cost
var weeklyLostFuelLiters: Double {
  let startOfWeek = getStartOfWeek(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfWeek }
  return eventsInPeriod.map(\.fuelUsedLiters).reduce(0, +)
}

var weeklyLostFuelCost: Double {
  let startOfWeek = getStartOfWeek(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfWeek }
  return eventsInPeriod.map(\.fuelCost).reduce(0, +)
}

// ADD: Computed properties for MONTHLY fuel lost and cost
var monthlyLostFuelLiters: Double {
  let startOfMonth = getStartOfMonth(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfMonth }
  return eventsInPeriod.map(\.fuelUsedLiters).reduce(0, +)
}

var monthlyLostFuelCost: Double {
  let startOfMonth = getStartOfMonth(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfMonth }
  return eventsInPeriod.map(\.fuelCost).reduce(0, +)
}

// ADD: Computed properties for YEARLY fuel lost and cost
var yearlyLostFuelLiters: Double {
  let startOfYear = getStartOfYear(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfYear }
  return eventsInPeriod.map(\.fuelUsedLiters).reduce(0, +)
}

var yearlyLostFuelCost: Double {
  let startOfYear = getStartOfYear(for: Date())
  let eventsInPeriod = brakingEvents.filter { $0.timestamp >= startOfYear }
  return eventsInPeriod.map(\.fuelCost).reduce(0, +)
}

func toggleEventExpansion(for id: UUID) {
  if expandedEventId == id {
      expandedEventId = nil
  } else {
      expandedEventId = id
  }
}

// ADD: Save function
private func saveBrakingEvents() {
  if let encoded = try? JSONEncoder().encode(brakingEvents) {
      UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
      print("DEBUG: Braking events saved to UserDefaults. Total events: \(brakingEvents.count)")
  } else {
      print("ERROR: Failed to encode braking events.")
  }
}

// ADD: Load function
private func loadBrakingEvents() {
  if let savedEventsData = UserDefaults.standard.data(forKey: userDefaultsKey) {
      if let decodedEvents = try? JSONDecoder().decode([BrakingEvent].self, from: savedEventsData) {
          self.brakingEvents = decodedEvents
          print("DEBUG: Braking events loaded from UserDefaults. Total events: \(brakingEvents.count)")
      } else {
          print("ERROR: Failed to decode braking events.")
      }
  } else {
      print("DEBUG: No braking events found in UserDefaults.")
  }
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
      // A hard braking event is detected
      handleBrakingEvent(decelerationRate: decelerationRate, speed: newSpeed, vInitial: oldest.speed)
  } else if let activeId = activeBrakingEventId, decelerationRate <= speedDecelThreshold {
      // If hard braking has stopped and there's an active event, update speedAtReturn
      if let index = brakingEvents.firstIndex(where: { $0.id == activeId }) {
          brakingEvents[index].speedAtReturn = newSpeed
          print("DEBUG: Braking event \(activeId) speedAtReturn updated to \(newSpeed) km/h")
      }
      activeBrakingEventId = nil // Clear the active event ID
      saveBrakingEvents() // ADD: Save after speedAtReturn update
  }
  
  previousSpeed = newSpeed
  lastUpdateTime = now
}

private func handleBrakingEvent(decelerationRate: Double, speed: Int, vInitial: Int) {
  isBraking = true
  
  // Only create a new event if sufficient time has passed or no events exist
  if brakingEvents.last == nil || Date().timeIntervalSince(brakingEvents.last!.timestamp) > 3 {
      let vInitMS = Double(vInitial) * 1000 / 3600
      let vFinalMS = Double(speed) * 1000 / 3600
      
      print("--- Braking Event Calculation ---")
      print("fuelPrice: \(fuelPrice) €/L")
      print("vInitial (km/h): \(vInitial), vFinal (km/h): \(speed)")
      print("vInitMS (m/s): \(vInitMS), vFinalMS (m/s): \(vFinalMS)")

      // CHANGE: Use storedVehicleMass from AppStorage, default to 1300.0 if invalid/empty
      let mass = Double(storedVehicleMass) ?? 1300.0 // kg
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

      var event = BrakingEvent(
          timestamp: Date(),
          deceleration: decelerationRate,
          speed: speed,
          intensity: brakingIntensity,
          // REMOVE: location: nil
          fuelUsedLiters: litersUsed,
          fuelCost: cost,
          speedAtReturn: nil // This will be updated in checkBrakingParameters when deceleration stops
      )
      
      // Capture location and geocode
      if let currentLocation = locationManager.location {
          // CHANGE: Assign to latitude/longitude directly
          event.latitude = currentLocation.coordinate.latitude
          event.longitude = currentLocation.coordinate.longitude

          geocoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks, error) in
              guard let self = self else { return }
              if let placemark = placemarks?.first {
                  let addressString = [
                      placemark.thoroughfare,
                      placemark.subThoroughfare,
                      placemark.locality,
                      placemark.country
                  ].compactMap { $0 }.joined(separator: ", ")
                  
                  if let index = self.brakingEvents.firstIndex(where: { $0.id == event.id }) {
                      self.brakingEvents[index].address = addressString
                      print("DEBUG: Braking event \(event.id) address updated to \(addressString)")
                      self.saveBrakingEvents() // ADD: Save after address update
                  }
              } else if let error = error {
                  print("DEBUG: Geocoding failed with error: \(error.localizedDescription)")
              }
          }
      }
      
      brakingEvents.append(event)
      // Set the newly created event as the active one
      activeBrakingEventId = event.id
      saveBrakingEvents() // ADD: Save after new event
  }
  
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.isBraking = false
  }
}

func addLocationToLastEvent(_ location: CLLocation?, address: String) {
  guard !brakingEvents.isEmpty else { return }
  // CHANGE: Update latitude and longitude instead of location
  brakingEvents[brakingEvents.count - 1].latitude = location?.coordinate.latitude
  brakingEvents[brakingEvents.count - 1].longitude = location?.coordinate.longitude
  brakingEvents[brakingEvents.count - 1].address = address
  saveBrakingEvents() // ADD: Save after location update
}
}
