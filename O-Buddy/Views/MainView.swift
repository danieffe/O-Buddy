//
//  ConnectedLineView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 27/05/25.
//

import SwiftUI
import Combine // ADD: Required for Publishers in ViewModels

struct MainView: View {
    let circleSize: CGFloat = 40
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
    let verticalOffset: CGFloat = -100
    let lineOverlap: CGFloat = 8

    // REMOVE: State variable for animatedLineHeight
    // @State private var animatedLineHeight: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    // REMOVE: State variable to control hollow circles visibility
    // @State private var showHollowCircles: Bool = false

    // REMOVE: Constants for hollow circles and text
    // let hollowCircleSize: CGFloat = 40
    // let hollowCircleStrokeWidth: CGFloat = 25
    // let firstHollowCircleRelativeYOffset: CGFloat = 90
    // let secondHollowCircleRelativeYOffset: CGFloat = 180
    // let textHorizontalOffset: CGFloat = 110
    // ADD: Constants for dynamic braking event circles
    let eventCircleSize: CGFloat = 40 // ADD: Size for individual event circles
    let eventCircleStrokeWidth: CGFloat = 25 // ADD: Stroke width for individual event circles
    let initialEventCircleOffset: CGFloat = 90 // ADD: Vertical offset for the first event circle from the main circle
    let eventCircleVerticalSpacing: CGFloat = 70 // ADD: Vertical spacing between consecutive event circles

    // ADD: Constants for top bar icons
    let iconSize: CGFloat = 30
    let iconPadding: CGFloat = 20

    // ADD: ViewModels for braking detection logic
    @StateObject private var obdViewModel: OBDViewModel
    @StateObject private var brakingViewModel: BrakingViewModel

    // ADD: Custom initializer to set up ViewModels
    init() {
        let obdVM = OBDViewModel()
        _obdViewModel = StateObject(wrappedValue: obdVM)
        _brakingViewModel = StateObject(
            wrappedValue: BrakingViewModel(
                speedPublisher: obdVM.$speed,
                rpmPublisher: obdVM.$rpm,
                fuelPressurePublisher: obdVM.$fuelPressure
            )
        )
    }

    var body: some View {
        // ADD: NavigationStack for navigation
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    let circleCenterY = geo.size.height / 2 + verticalOffset
                    let circleBottomY = circleCenterY + (circleSize / 2)
                    // ADD: Calculate finalHeight for the line directly
                    let finalHeight = geo.size.height - circleBottomY + lineOverlap


                    // Linea animata
                    Rectangle()
                        .fill(Color.black)
                        .ignoresSafeArea()
                        // CHANGE: Use finalHeight directly, remove animatedLineHeight
                        .frame(width: 15, height: finalHeight)
                        .position(
                            x: geo.size.width / 2,
                            y: circleBottomY - lineOverlap + (finalHeight / 2)
                        )
                        // REMOVE: Line animation
                        // .animation(.easeOut(duration: 1.0), value: animatedLineHeight)

                    // Cerchio centrale
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
                    // ADD: Apply pulsating effect
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.2) // CHANGE: Changed animation duration
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )

                    // REMOVE: First hollow circle
                    // Circle()
                    //     .stroke(Color.black, lineWidth: hollowCircleStrokeWidth)
                    //     .fill(Color.white) // ADD: Fill to make the circle white inside
                    //     .frame(width: hollowCircleSize, height: hollowCircleSize)
                    //     .position(
                    //         x: geo.size.width / 2,
                    //         y: circleCenterY + firstHollowCircleRelativeYOffset
                    //     )
                    //     // CHANGE: Opacity controlled by showHollowCircles
                    //     .opacity(showHollowCircles ? 1 : 0)
                    //     // ADD: Animation for opacity
                    //     .animation(.easeIn(duration: 1.0), value: showHollowCircles)

                    // REMOVE: Second hollow circle
                    // Circle()
                    //     .stroke(Color.black, lineWidth: hollowCircleStrokeWidth)
                    //     .fill(Color.white) // ADD: Fill to make the circle white inside
                    //     .frame(width: hollowCircleSize, height: hollowCircleSize)
                    //     .position(
                    //         x: geo.size.width / 2,
                    //         y: circleCenterY + secondHollowCircleRelativeYOffset
                    //     )
                    //     // CHANGE: Opacity controlled by showHollowCircles
                    //     .opacity(showHollowCircles ? 1 : 0)
                    //     // ADD: Animation for opacity
                    //     .animation(.easeIn(duration: 1.0), value: showHollowCircles)

                    // ADD: Aggressive drive text (always visible)
                    Text("Aggressive drive")
                        .foregroundColor(.black)
                        .font(.body)
                        .position(
                            x: geo.size.width / 2 - 110, // Re-use previous offset
                            y: circleCenterY
                        )

                    // ADD: Actual Speed text (always visible, showing current/last speed)
                    Text("Actual Speed\n\(obdViewModel.speed) km/h") // CHANGE: Display current OBD speed
                        .foregroundColor(.black)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .position(
                            x: geo.size.width / 2 + 110, // Re-use previous offset
                            y: circleCenterY
                        )
                    
                    // CHANGE: Bluetooth icon to list.clipboard
                    Image(systemName: "wave.3.right.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        // CHANGE: Color based on OBD connection status
                        .foregroundColor(obdViewModel.isConnected ? .green : .red)
                        .position(x: iconPadding + iconSize / 2, y: iconPadding + iconSize / 2)

                    // CHANGE: Square grid icon to wave.right
                    // ADD: NavigationLink to DashboardView
                    NavigationLink(destination: DashboardView()) {
                        Image(systemName: "list.clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(.black)
                    }
                    .position(x: geo.size.width - iconPadding - iconSize / 2, y: iconPadding + iconSize / 2)

                    // ADD: Scrollable content for the line and braking events
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) { // VStack to stack line and circles
                            // ADD: Spacer to position the first event circle
                            let topPaddingForScrollViewContent = initialEventCircleOffset - (circleSize / 2) + lineOverlap
                            if topPaddingForScrollViewContent > 0 {
                                Spacer(minLength: topPaddingForScrollViewContent)
                            }

                            // REMOVE: Line definition moved inside ScrollView's VStack
                            // Rectangle()
                            //     .fill(Color.black)
                            //     // REMOVE: ignoresSafeArea() from Rectangle
                            //     .frame(width: 15, height: contentHeight) // Height adjusts dynamically
                            //     // ADD: Overlay for dynamic circles on the line
                            //     .overlay(
                                    ZStack {
                                        ForEach(brakingViewModel.brakingEvents.indexed(), id: \.1.id) { index, event in
                                            // CHANGE: Calculate displayIndex to show newest events at the top
                                            let numberOfEvents = brakingViewModel.brakingEvents.count // ADD: Recalculate numberOfEvents
                                            let displayIndex = numberOfEvents - 1 - index
                                            
                                            Circle()
                                                .stroke(Color.black, lineWidth: eventCircleStrokeWidth)
                                                .fill(Color.white)
                                                .frame(width: eventCircleSize, height: eventCircleSize)
                                                // CHANGE: Position circles relative to the line's top, using displayIndex
                                                .offset(y: CGFloat(displayIndex) * eventCircleVerticalSpacing)
                                                // REMOVE: Initial opacity(0) and its animation
                                                .transition(.scale) // Transition for new circles appearing
                                        }
                                    }
                                // )
                        }
                        // CHANGE: Ensure VStack takes full width to center its content horizontally
                        .frame(width: geo.size.width)
                    }
                    // CHANGE: Position and frame the ScrollView to start below the central circle
                    .frame(height: geo.size.height - (circleBottomY - lineOverlap)) // Set height of ScrollView
                    .position(x: geo.size.width / 2, y: (circleBottomY - lineOverlap) + (geo.size.height - (circleBottomY - lineOverlap)) / 2) // Center the ScrollView vertically in its available space
                }
                .onAppear {
                    // Calcolo dell'altezza finale della linea spostato qui
                    // REMOVE: animatedLineHeight calculation and assignment
                    // let circleCenterY = geo.size.height / 2 + verticalOffset
                    // let circleBottomY = circleCenterY + (circleSize / 2)
                    // let finalHeight = geo.size.height - circleBottomY + lineOverlap
                    
                    // CHANGE: Start pulsating animation with a smaller scale to reduce movement
                    // REMOVE: DispatchQueue.main.asyncAfter as animatedLineHeight is no longer a state
                    pulseScale = 1.05
                }
                // REMOVE: Observe brakingViewModel.isBraking to control showHollowCircles
                // .onChange(of: brakingViewModel.isBraking) { newValue in
                //     self.showHollowCircles = newValue
                // }
            }
        } // ADD: End of NavigationStack
    }
}

// ADD: Extension to get indexed elements for ForEach
extension RandomAccessCollection {
    func indexed() -> Array<(offset: Int, element: Self.Element)> {
        Array(enumerated())
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
