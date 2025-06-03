//
//  ConnectedLineView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 27/05/25.
//

import SwiftUI
import Combine
import CoreLocation

struct MainView: View {
    let circleSize: CGFloat = 40
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
    let verticalOffset: CGFloat = -100
    let lineOverlap: CGFloat = 8

    @State private var pulseScale: CGFloat = 1.0
    let eventCircleSize: CGFloat = 40
    let eventCircleStrokeWidth: CGFloat = 25
    let initialEventCircleOffset: CGFloat = 90
    let eventCircleVerticalSpacing: CGFloat = 70
    let eventCircleNonExpandedStrokeWidth: CGFloat = 10


    let iconSize: CGFloat = 30
    let iconPadding: CGFloat = 20

    @StateObject private var obdViewModel: OBDViewModel
    @StateObject private var brakingViewModel: BrakingViewModel
    @StateObject private var locationManager = LocationManager() // Kept as StateObject here
    @State private var stations: [FuelStation] = []
    @State private var selectedFuel = "gasolio"

    private let fuelTypes = ["benzina", "gasolio", "gpl", "metano", "premium", "gasolio_plus"]
    private let service = FuelPriceService()

    init(obdViewModel: OBDViewModel = OBDViewModel(), brakingViewModel: BrakingViewModel? = nil) {
        _obdViewModel = StateObject(wrappedValue: obdViewModel)
        
        let bvm: BrakingViewModel
        if let existingBrakingViewModel = brakingViewModel {
            bvm = existingBrakingViewModel
        } else {
            // Pass locationManager instance to BrakingViewModel during initialization
            let newLocationManager = LocationManager()
            bvm = BrakingViewModel(
                speedPublisher: obdViewModel.$speed,
                rpmPublisher: obdViewModel.$rpm,
                fuelPressurePublisher: obdViewModel.$fuelPressure,
                locationManager: newLocationManager // Pass the locationManager here
            )
            _locationManager = StateObject(wrappedValue: newLocationManager) // Initialize _locationManager
        }
        _brakingViewModel = StateObject(wrappedValue: bvm)
    }

    var averagePrice: Double {
        let prices = stations.compactMap { Double($0.prezzo.replacingOccurrences(of: ",", with: ".")) }
        return prices.isEmpty ? 0.0 : prices.reduce(0, +) / Double(prices.count)
    }

    var body: some View {
        NavigationStack {
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

                    Circle()
                        .fill(Color.black)
                        .overlay(
                            Circle()
                                .stroke(Color.black, style: strokeStyle)
                                .opacity(0)
                        )
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

                    Text("Aggressive drive")
                        .foregroundColor(.black)
                        .font(.body)
                        .position(
                            x: geo.size.width / 2 - 110,
                            y: circleCenterY
                        )

                    VStack { // Use VStack to align text vertically
                        Text("Actual Speed")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("\(obdViewModel.speed) km/h")
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    .multilineTextAlignment(.center)
                    .position(
                        x: geo.size.width / 2 + 110,
                        y: circleCenterY
                    )
                    
                    Image(systemName: "wave.3.right.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(obdViewModel.isConnected ? .green : .red)
                        .position(x: geo.size.width - 2 * iconPadding - 1.5 * iconSize, y: iconPadding + iconSize / 2)

                    NavigationLink(destination: DashboardView()) {
                        Image(systemName: "list.clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(.black)
                    }
                    .position(x: geo.size.width - iconPadding - iconSize / 2, y: iconPadding + iconSize / 2)

                    VStack(alignment: .leading) {
                        Text("Today, \(Date.now, format: .dateTime.day().month(.abbreviated).year())")
                            .font(.title) // Changed from .title3 to .title
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Spacer().frame(height: 15)
                        
                        Text("Braking Events: \(brakingViewModel.dailyBrakingEventsCount)")
                            .font(.body) // Changed font size
                            .foregroundColor(.black)
                        
                        Text(String(format: "Daily Consumption: %.2f €", brakingViewModel.dailyFuelCost))
                            .font(.body) // Changed font size
                            .foregroundColor(.black)

                        Text("Your driving style: Placeholder")
                            .font(.body) // Set to same font size as daily consumption
                            .foregroundColor(.black)
                    }
                    .position(x: iconPadding + iconSize / 2 + 95, y: iconPadding + iconSize / 2 + 45) 

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            let topPaddingForScrollViewContent = initialEventCircleOffset - (circleSize / 2) + lineOverlap
                            if topPaddingForScrollViewContent > 0 {
                                Spacer(minLength: topPaddingForScrollViewContent)
                            }

                            ZStack {
                                ForEach(brakingViewModel.brakingEvents.enumerated().reversed(), id: \.element.id) { index, event in
                                    let isExpanded = brakingViewModel.expandedEventId == event.id
                                    Group {
                                        Circle()
                                            .fill(isExpanded ? Color.black : Color.white)
                                            .stroke(Color.black, lineWidth: eventCircleNonExpandedStrokeWidth)
                                            .frame(width: eventCircleSize, height: eventCircleSize)
                                            .offset(y: CGFloat(index) * eventCircleVerticalSpacing)
                                            // ADD: Animation for the circle's position changes
                                            .animation(.easeInOut(duration: 1.0), value: index) // Animates movement based on index change
                                    }
                                    .onTapGesture {
                                        brakingViewModel.toggleEventExpansion(for: event.id)
                                    }
                                    
                                    if isExpanded {
                                        // ADD: Left side details (Date, Address)
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(event.timestamp, format: .dateTime.day().month(.abbreviated).year())
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.bottom, 4)

                                            Text(event.address)
                                                .font(.caption)
                                                .fontWeight(.regular)
                                                .multilineTextAlignment(.trailing) // Align text to the right within its own frame
                                                .padding(.top, 4)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .offset(x: geo.size.width / 2 - geo.size.width / 2 - 100, y: CGFloat(index) * eventCircleVerticalSpacing) // Adjusted X offset for left side
                                        .transition(.scale.combined(with: .opacity).animation(.easeInOut(duration: 0.3)))

                                        // CHANGE: Right side details (technical info)
                                        VStack(alignment: .leading, spacing: 4) {
                                            // REMOVE: Display Date of braking event (moved to left)
                                            Text("Hard Brake")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            Text("Speed at stop")
                                                .font(.caption)
                                            Text("\(event.speed ?? 0) km/h")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                            Text("Speed at return")
                                                .font(.caption)
                                            Text(event.speedAtReturn != nil ? "\(event.speedAtReturn!) km/h" : "N/A")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                            Text("RPM lost")
                                                .font(.caption)
                                            Text(String(format: "%.2f", event.intensity))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                            Text("Gasoline Consumption")
                                                .font(.caption)
                                            Text(String(format: "%.2f €", event.fuelCost))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.red)
                                            // REMOVE: Display Address of braking event (moved to left)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .offset(x: geo.size.width / 2 - geo.size.width / 2 + 100, y: CGFloat(index) * eventCircleVerticalSpacing) // Original X offset for right side
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
                    // Removed fetchData() from onAppear
                }
                .onChange(of: locationManager.location) { newLocation in
                    if newLocation != nil {
                        fetchData()
                    }
                }
                .onChange(of: selectedFuel) { _ in fetchData()
                }
            }
        }
    }

    private func fetchData() {
        guard let location = locationManager.location else {
            print("DEBUG: Location not available for fetching fuel prices in MainView.")
            return
        }
        print("DEBUG: Fetching stations for lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude), fuelType: \(selectedFuel) in MainView.")
        service.fetchStations(lat: location.coordinate.latitude, lon: location.coordinate.longitude, fuelType: selectedFuel) { fetchedStations in
            self.stations = fetchedStations
            self.brakingViewModel.fuelPrice = self.averagePrice
            print("DEBUG: Fetched \(fetchedStations.count) stations in MainView. Average price for \(self.selectedFuel): \(self.averagePrice) €/L")
            if fetchedStations.isEmpty {
                print("DEBUG: No fuel stations found for the current location and fuel type in MainView.")
            }
        }
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
            self.speed = 30 // Example speed
            self.rpm = 1500 // Example RPM
            self.fuelPressure = 100 // Example fuel pressure
            self.isConnected = true // Assume connected for preview
            self.initializationStatus = "Mock Connected"
        }
    }

    class MockBrakingViewModel: BrakingViewModel {
        override init(speedPublisher: Published<Int>.Publisher, rpmPublisher: Published<Int>.Publisher, fuelPressurePublisher: Published<Int>.Publisher, locationManager: LocationManager = LocationManager()) {
            super.init(speedPublisher: speedPublisher, rpmPublisher: fuelPressurePublisher, fuelPressurePublisher: fuelPressurePublisher, locationManager: locationManager)
            
            // Populate with sample braking events
            self.brakingEvents = [
                // CHANGE: Reorder arguments in BrakingEvent initializer to match compiler's expected order (location before fuelUsedLiters)
                BrakingEvent(timestamp: Date().addingTimeInterval(-30), deceleration: 20.0, speed: 50, intensity: 0.8, location: CLLocation(latitude: 40.7128, longitude: -74.0060), address: "Via Roma, 1, Napoli", fuelUsedLiters: 0.05, fuelCost: 0.08, speedAtReturn: 5),
                BrakingEvent(timestamp: Date().addingTimeInterval(-60), deceleration: 15.0, speed: 60, intensity: 0.6, location: CLLocation(latitude: 41.9028, longitude: 12.4964), address: "Piazza Navona, Roma", fuelUsedLiters: 0.03, fuelCost: 0.05, speedAtReturn: 10),
                BrakingEvent(timestamp: Date().addingTimeInterval(-90), deceleration: 25.0, speed: 40, intensity: 0.9, location: CLLocation(latitude: 45.4642, longitude: 9.1900), address: "Duomo, Milano", fuelUsedLiters: 0.07, fuelCost: 0.12, speedAtReturn: 8),
                BrakingEvent(timestamp: Date().addingTimeInterval(-120), deceleration: 12.0, speed: 70, intensity: 0.5, location: CLLocation(latitude: 40.8518, longitude: 14.2681), address: "Napoli Centrale", fuelUsedLiters: 0.02, fuelCost: 0.03, speedAtReturn: nil),
                BrakingEvent(timestamp: Date().addingTimeInterval(-150), deceleration: 18.0, speed: 55, intensity: 0.7, location: CLLocation(latitude: 40.7128, longitude: -74.0060), address: "New York, USA", fuelUsedLiters: 0.04, fuelCost: 0.07, speedAtReturn: 15)
            ]
            self.fuelPrice = 1.80 // Set a sample fuel price for calculations in preview
            self.expandedEventId = self.brakingEvents.first?.id
        }
    }

    static var previews: some View {
        let mockOBD = MockOBDViewModel()
        let mockLocationManager = LocationManager() // Create a mock LocationManager
        let mockBraking = MockBrakingViewModel(
            speedPublisher: mockOBD.$speed,
            rpmPublisher: mockOBD.$rpm,
            fuelPressurePublisher: mockOBD.$fuelPressure,
            locationManager: mockLocationManager // Pass the mock LocationManager
        )
        MainView(obdViewModel: mockOBD, brakingViewModel: mockBraking)
    }
}
