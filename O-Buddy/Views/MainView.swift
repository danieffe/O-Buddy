//
//  MainView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 04/06/25.
//

import SwiftUI
import CoreLocation
import Combine

struct MainView: View {
    let circleSize: CGFloat = 40
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
    let verticalOffset: CGFloat = -100
    let lineOverlap: CGFloat = 8

    @State private var pulseScale: CGFloat = 1.0
    let eventCircleSize: CGFloat = 40
    let eventCircleStrokeWidth: CGFloat = 25
    let initialEventCircleOffset: CGFloat = 95
    let eventCircleVerticalSpacing: CGFloat = 70
    let eventCircleNonExpandedStrokeWidth: CGFloat = 10


    let iconSize: CGFloat = 30
    let iconPadding: CGFloat = 20

    @StateObject private var obdViewModel: OBDViewModel
    @StateObject private var brakingViewModel: BrakingViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var stations: [FuelStation] = []
    @AppStorage("selectedFuel") private var selectedFuel = "gasolio"
    @AppStorage("vehicleMass") private var storedVehicleMass: String = ""
    @State private var showMassAlert: Bool = false
    @State private var showSettingsView: Bool = false

    private let fuelTypes = ["benzina", "gasolio", "gpl", "metano", "premium", "gasolio_plus"]
    private let service = FuelPriceService()

    init(obdViewModel: OBDViewModel = OBDViewModel(), brakingViewModel: BrakingViewModel? = nil) {
        _obdViewModel = StateObject(wrappedValue: obdViewModel)

        let bvm: BrakingViewModel
        if let existingBrakingViewModel = brakingViewModel {
            bvm = existingBrakingViewModel
        } else {
            let newLocationManager = LocationManager()
            bvm = BrakingViewModel(
                speedPublisher: obdViewModel.$speed.eraseToAnyPublisher(),
                rpmPublisher: obdViewModel.$rpm.eraseToAnyPublisher(),
                fuelPressurePublisher: obdViewModel.$fuelPressure.eraseToAnyPublisher(),
                locationManager: newLocationManager
            )
            _locationManager = StateObject(wrappedValue: newLocationManager)
        }
        _brakingViewModel = StateObject(wrappedValue: bvm)
    }

    var averagePrice: Double {
        let prices = stations.compactMap { Double($0.prezzo.replacingOccurrences(of: ",", with: ".")) }
        return prices.isEmpty ? 0.0 : prices.reduce(0, +) / Double(prices.count)
    }

    var drivingStyle: (style: DrivingStyle, color: Color) {
        let count = brakingViewModel.dailyBrakingEventsCount
        switch count {
        case 0:
            return (.smooth, .black)
        case 1...4:
            return (.normal, .green)
        case 5...10:
            return (.nervous, .orange)
        default:
            return (.aggressive, .red)
        }
    }

    var body: some View {
        NavigationStack {
            NavigationLink(destination: SettingsView(), isActive: $showSettingsView) { EmptyView() }
                .hidden()
            GeometryReader { geo in
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    let circleCenterY = geo.size.height / 2 + verticalOffset
                    let circleBottomY = circleCenterY + (circleSize / 2)
                    let finalHeight = geo.size.height - circleBottomY + lineOverlap

                    Rectangle()
                        .fill(Color.black)
                        .ignoresSafeArea()
                        .frame(width: 15, height: finalHeight)
                        .position(
                            x: geo.size.width / 2,
                            y: circleBottomY - lineOverlap + (finalHeight / 2)
                        )

                    Group {
                                          if obdViewModel.isConnected {
                                              Circle()
                                                  .fill(Color.black)
                                                  .overlay(
                                                      Circle()
                                                          .stroke(Color.black, style: strokeStyle)
                                                          .opacity(0)
                                                  )
                                          } else {
                                              Rectangle()
                                                  .fill(Color.black)
                                          }
                                      }
                                      .frame(width: circleSize, height: circleSize)
                                      .position(
                                          x: geo.size.width / 2,
                                          y: circleCenterY
                                      )
                                      .scaleEffect(pulseScale)
                                      .animation(
                                          .easeInOut(duration: 1.2)
                                              .repeatForever(autoreverses: true),
                                          value: pulseScale
                                      )

                    Group {
                                          if obdViewModel.isConnected {
                                              VStack {
                                                  Text("Driving style".localized)
                                                      .font(.body)
                                                      .fontWeight(.bold)
                                                      .foregroundColor(.black)
                                                  Text(drivingStyle.style.rawValue)
                                                      .font(.body)
                                                      .foregroundColor(drivingStyle.color)
                                              }
                                              .multilineTextAlignment(.center)
                                              .position(
                                                  x: geo.size.width / 2 - 90,
                                                  y: circleCenterY - 150
                                              )

                                              VStack {
                                                  Text("Actual speed".localized)
                                                      .font(.body)
                                                      .fontWeight(.bold)
                                                      .foregroundColor(.black)
                                                  Text("\(obdViewModel.speed) km/h")
                                                      .font(.body)
                                                      .foregroundColor(.black)
                                              }
                                              .multilineTextAlignment(.center)
                                              .position(
                                                  x: geo.size.width / 2 + 90,
                                                  y: circleCenterY - 150
                                              )

                                              VStack {
                                                  Text("Daily brakes:".localized)
                                                      .font(.body)
                                                      .fontWeight(.bold)
                                                      .foregroundColor(.black)
                                                  Text("\(brakingViewModel.dailyBrakingEventsCount)")
                                                      .font(.body)
                                                      .foregroundColor(.black)
                                              }
                                              .multilineTextAlignment(.center)
                                              .position(
                                                  x: geo.size.width / 2 - 90,
                                                  y: circleCenterY - 80
                                              )

                                              VStack {
                                                  Text("Daily consumption:".localized)
                                                      .font(.body)
                                                      .fontWeight(.bold)
                                                      .foregroundColor(.black)
                                                  Text(String(format: "%.2f €", brakingViewModel.dailyFuelCost))
                                                      .font(.body)
                                                      .foregroundColor(.black)
                                              }
                                              .multilineTextAlignment(.center)
                                              .position(
                                                  x: geo.size.width / 2 + 90,
                                                  y: circleCenterY - 80
                                              )
                                          } else {
                                              Text("Searching for OBD devices...".localized)
                                                  .font(.title2)
                                                  .foregroundColor(.gray)
                                                  .multilineTextAlignment(.center)
                                                  .frame(width: geo.size.width * 0.8)
                                                  .position(
                                                      x: geo.size.width / 2,
                                                      y: circleCenterY - 100
                                                  )
                                          }
                                      }

                    NavigationLink(destination: DashboardView().environmentObject(brakingViewModel)) {
                                       Image(systemName: "fuelpump.fill")
                                           .resizable()
                                           .aspectRatio(contentMode: .fit)
                                           .frame(width: iconSize, height: iconSize)
                                           .foregroundColor(.gray)
                                   }
                                   .position(x: geo.size.width - iconPadding - iconSize / 2, y: iconPadding + iconSize / 2 + 15)

                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(.gray)
                    }
                    .position(x: iconPadding + iconSize / 2, y: iconPadding + iconSize / 2 + 15)


                  

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: eventCircleVerticalSpacing - eventCircleSize) {
                            let topPaddingToFirstEventCenter = initialEventCircleOffset - (circleSize / 2) + lineOverlap
                            Spacer(minLength: topPaddingToFirstEventCenter - (eventCircleSize / 2))

                            ForEach(brakingViewModel.brakingEvents.reversed(), id: \.id) { event in
                                ZStack {
                                    let isExpanded = brakingViewModel.expandedEventId == event.id
                                    Group {
                                        Circle()
                                            .fill(isExpanded ? Color.black : Color.white)
                                            .stroke(Color.black, lineWidth: eventCircleNonExpandedStrokeWidth)
                                            .frame(width: eventCircleSize, height: eventCircleSize)
                                            .animation(.easeInOut(duration: 1.0), value: isExpanded)
                                    }
                                    .onTapGesture {
                                        brakingViewModel.toggleEventExpansion(for: event.id)
                                    }

                                    if isExpanded {
                                        HStack(spacing: 0) {
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(event.timestamp, format: .dateTime.day().month(.abbreviated).year())
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.bottom, 4)

                                                Text(event.address)
                                                    .font(.caption)
                                                    .fontWeight(.regular)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: (geo.size.width / 2) - (eventCircleSize / 2) - 20, alignment: .trailing)

                                            Spacer(minLength: eventCircleSize + 40)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Hard Brake".localized)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text("Speed at stop".localized)
                                                    .font(.caption)
                                                Text("\(event.speed ?? 0) km/h")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("Speed at return".localized)
                                                    .font(.caption)
                                                Text(event.speedAtReturn != nil ? "\(event.speedAtReturn!) km/h" : "N/A")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("RPM lost".localized)
                                                    .font(.caption)
                                                Text(String(format: "%.2f", event.intensity))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("Fuel Consumption".localized)
                                                    .font(.caption)
                                                Text(String(format: "%.2f €", event.fuelCost))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: (geo.size.width / 2) - (eventCircleSize / 2) - 20, alignment: .leading)
                                        }
                                        .frame(width: geo.size.width - 40)
                                        .transition(.scale.combined(with: .opacity).animation(.easeInOut(duration: 0.3)))
                                    }
                                }
                            }
                        }
                        .frame(width: geo.size.width)
                    }
                    .frame(height: geo.size.height - (circleBottomY - lineOverlap))
                    .position(x: geo.size.width / 2, y: (circleBottomY - lineOverlap) + (geo.size.height - (circleBottomY - lineOverlap)) / 2)
                }
                .onAppear {
                    pulseScale = 1.05
                    checkVehicleMassValidity()
                }
                .onChange(of: locationManager.location) { newLocation in
                    if newLocation != nil {
                        fetchData()
                    }
                }
                .onChange(of: selectedFuel) { _ in fetchData() }
                .alert("Vehicle Mass Required".localized, isPresented: $showMassAlert) {
                    Button("Go to Settings".localized) {
                        showMassAlert = false
                        showSettingsView = true
                    }
                } message: {
                    Text("Please enter a valid positive number for your vehicle's mass in the Settings to ensure accurate calculations.".localized)
                }
            }
        }
    }

    private func checkVehicleMassValidity() {
        if storedVehicleMass.isEmpty || Double(storedVehicleMass) == nil || (Double(storedVehicleMass) ?? 0) <= 0 {
            showMassAlert = true
        } else {
            showMassAlert = false
        }
    }

    private func fetchData() {
        guard let location = locationManager.location else {
            print("DEBUG: Location not available for fetching fuel prices in MainView.")
            return
        }
        print("DEBUG: Fetching stations for lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude), fuelType: \(selectedFuel) in MainView.")
        service.fetchStations(lat: location.coordinate.latitude, lon: location.coordinate.longitude, fuelType: selectedFuel) { fetchedStations in
            DispatchQueue.main.async {
                self.stations = fetchedStations
                if fetchedStations.isEmpty {
                    if let fallbackPrice = self.service.getFallbackAverageFuelCost() {
                        self.brakingViewModel.fuelPrice = fallbackPrice
                        print("DEBUG: Using fallback fuel price: \(fallbackPrice) €/L")
                    } else {
                        self.brakingViewModel.fuelPrice = 0.0
                        print("DEBUG: No fuel stations found and no fallback price available.".localized)
                    }
                } else {
                    self.brakingViewModel.fuelPrice = self.averagePrice
                    print("DEBUG: Fetched \(fetchedStations.count) stations in MainView. Average price for \(self.selectedFuel): \(self.averagePrice) €/L")
                }
                if fetchedStations.isEmpty {
                    print("DEBUG: No fuel stations found for the current location and fuel type.".localized)
                }
            }
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

extension RandomAccessCollection {
    func indexed() -> Array<(offset: Int, element: Self.Element)> {
        Array(enumerated())
    }
}

struct MainView_Previews: PreviewProvider {
    class MockOBDViewModel: OBDViewModel {
        override init() {
            super.init()
            self.speed = 30
            self.rpm = 1500
            self.fuelPressure = 100
            self.isConnected = true
            self.initializationStatus = "Mock Connected"
        }
    }

    class MockBrakingViewModel: BrakingViewModel {
        override init(speedPublisher: AnyPublisher<Int, Never>, rpmPublisher: AnyPublisher<Int, Never>, fuelPressurePublisher: AnyPublisher<Int, Never>, locationManager: LocationManager = LocationManager()) {
            super.init(speedPublisher: speedPublisher, rpmPublisher: rpmPublisher, fuelPressurePublisher: fuelPressurePublisher, locationManager: locationManager)

            self.brakingEvents = [
                BrakingEvent(timestamp: Date().addingTimeInterval(-30), deceleration: 20.0, speed: 50, intensity: 0.8, location: CLLocation(latitude: 40.7128, longitude: -74.0060), address: "Via Roma, 1, Napoli", fuelUsedLiters: 0.05, fuelCost: 0.08, speedAtReturn: 5),
                BrakingEvent(timestamp: Date().addingTimeInterval(-60), deceleration: 15.0, speed: 60, intensity: 0.6, location: CLLocation(latitude: 41.9028, longitude: 12.4964), address: "Piazza Navona, Roma", fuelUsedLiters: 0.03, fuelCost: 0.05, speedAtReturn: 10),
                BrakingEvent(timestamp: Date().addingTimeInterval(-90), deceleration: 25.0, speed: 40, intensity: 0.9, location: CLLocation(latitude: 45.4642, longitude: 9.1900), address: "Duomo, Milano", fuelUsedLiters: 0.07, fuelCost: 0.12, speedAtReturn: 8),
                BrakingEvent(timestamp: Date().addingTimeInterval(-120), deceleration: 12.0, speed: 70, intensity: 0.5, location: CLLocation(latitude: 40.8518, longitude: 14.2681), address: "Napoli Centrale", fuelUsedLiters: 0.02, fuelCost: 0.03, speedAtReturn: nil),
                BrakingEvent(timestamp: Date().addingTimeInterval(-150), deceleration: 18.0, speed: 55, intensity: 0.7, location: CLLocation(latitude: 40.7128, longitude: -74.0060), address: "New York, USA", fuelUsedLiters: 0.04, fuelCost: 0.07, speedAtReturn: 15)
            ]
            self.fuelPrice = 1.80
            self.expandedEventId = self.brakingEvents.first?.id
        }
    }

    static var previews: some View {
        let mockOBD = MockOBDViewModel()
        let mockLocationManager = LocationManager()
        let mockBraking = MockBrakingViewModel(
            speedPublisher: mockOBD.$speed.eraseToAnyPublisher(),
            rpmPublisher: mockOBD.$rpm.eraseToAnyPublisher(),
            fuelPressurePublisher: mockOBD.$fuelPressure.eraseToAnyPublisher(),
            locationManager: mockLocationManager
        )
        MainView(obdViewModel: mockOBD, brakingViewModel: mockBraking)
    }
}
