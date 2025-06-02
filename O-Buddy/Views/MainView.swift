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
    @StateObject private var locationManager = LocationManager()
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
            bvm = BrakingViewModel(
                speedPublisher: obdViewModel.$speed,
                rpmPublisher: obdViewModel.$rpm,
                fuelPressurePublisher: obdViewModel.$fuelPressure
            )
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

                    Text("Actual Speed\n\(obdViewModel.speed) km/h")
                        .foregroundColor(.black)
                        .font(.body)
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
                        .position(x: iconPadding + iconSize / 2, y: iconPadding + iconSize / 2)

                    NavigationLink(destination: DashboardView()) {
                        Image(systemName: "list.clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(.black)
                    }
                    .position(x: geo.size.width - iconPadding - iconSize / 2, y: iconPadding + iconSize / 2)

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
                                            .transition(.scale)
                                        
                                        if isExpanded {
                                            VStack(alignment: .leading, spacing: 4) {
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
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .offset(x: geo.size.width / 2 - geo.size.width / 2 + 100, y: CGFloat(index) * eventCircleVerticalSpacing)
                                            .transition(.scale.combined(with: .opacity).animation(.easeInOut(duration: 0.3)))

                                        }
                                    }
                                    .onTapGesture {
                                        brakingViewModel.toggleEventExpansion(for: event.id)
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
        override init(speedPublisher: Published<Int>.Publisher, rpmPublisher: Published<Int>.Publisher, fuelPressurePublisher: Published<Int>.Publisher) {
            super.init(speedPublisher: speedPublisher, rpmPublisher: rpmPublisher, fuelPressurePublisher: fuelPressurePublisher)
            
            // Populate with sample braking events
            self.brakingEvents = [
                BrakingEvent(timestamp: Date().addingTimeInterval(-30), deceleration: 20.0, speed: 50, intensity: 0.8, fuelUsedLiters: 0.05, fuelCost: 0.08, speedAtReturn: 5),
                BrakingEvent(timestamp: Date().addingTimeInterval(-60), deceleration: 15.0, speed: 60, intensity: 0.6, fuelUsedLiters: 0.03, fuelCost: 0.05, speedAtReturn: 10),
                BrakingEvent(timestamp: Date().addingTimeInterval(-90), deceleration: 25.0, speed: 40, intensity: 0.9, fuelUsedLiters: 0.07, fuelCost: 0.12, speedAtReturn: 8),
                BrakingEvent(timestamp: Date().addingTimeInterval(-120), deceleration: 12.0, speed: 70, intensity: 0.5, fuelUsedLiters: 0.02, fuelCost: 0.03, speedAtReturn: nil),
                BrakingEvent(timestamp: Date().addingTimeInterval(-150), deceleration: 18.0, speed: 55, intensity: 0.7, fuelUsedLiters: 0.04, fuelCost: 0.07, speedAtReturn: 15)
            ]
            self.fuelPrice = 1.80 // Set a sample fuel price for calculations in preview
            self.expandedEventId = self.brakingEvents.first?.id
        }
    }

    static var previews: some View {
        let mockOBD = MockOBDViewModel()
        let mockBraking = MockBrakingViewModel(
            speedPublisher: mockOBD.$speed,
            rpmPublisher: mockOBD.$rpm,
            fuelPressurePublisher: mockOBD.$fuelPressure
        )
        MainView(obdViewModel: mockOBD, brakingViewModel: mockBraking)
    }
}
