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

    @State private var animatedLineHeight: CGFloat = 0
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
        GeometryReader { geo in
            ZStack {
                Color.white
                    .ignoresSafeArea()

                let circleCenterY = geo.size.height / 2 + verticalOffset
                let circleBottomY = circleCenterY + (circleSize / 2)

                // Linea animata
                Rectangle()
                    .fill(Color.black)
                    .ignoresSafeArea()
                    .frame(width: 15, height: animatedLineHeight)
                    .position(
                        x: geo.size.width / 2,
                        y: circleBottomY - lineOverlap + (animatedLineHeight / 2)
                    )
                    .animation(.easeOut(duration: 1.0), value: animatedLineHeight)

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

                // ADD: Dynamically generated circles for braking events
                ForEach(brakingViewModel.brakingEvents.indexed(), id: \.1.id) { index, event in
                    Circle()
                        .stroke(Color.black, lineWidth: eventCircleStrokeWidth)
                        .fill(Color.white)
                        .frame(width: eventCircleSize, height: eventCircleSize)
                        .position(
                            x: geo.size.width / 2,
                            y: circleCenterY + initialEventCircleOffset + (CGFloat(index) * eventCircleVerticalSpacing)
                        )
                        .opacity(0) // Initial opacity for animation
                        .animation(.easeIn(duration: 0.5).delay(Double(index) * 0.1), value: 1) // ADD: Animation for appearance
                        .onAppear {
                            // Animate to visible when added
                            DispatchQueue.main.async { // Ensure this runs on main thread
                                // This won't work directly with .opacity(0) and .animation() on a ForEach item.
                                // The opacity needs to be bound to a state variable for each item or managed differently.
                                // For simplicity, we'll let the ForEach handle immediate appearance as items are added.
                                // If a fade-in animation is strictly needed per item, each item needs its own @State.
                                // For now, they will just appear as they are added to the array.
                                // A common pattern for animate-on-add is to have a @State for opacity within a custom view for each circle.
                            }
                        }
                        .transition(.scale) // ADD: Transition for new circles appearing
                }

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
                Image(systemName: "list.clipboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.black)
                    .position(x: geo.size.width - iconPadding - iconSize / 2, y: iconPadding + iconSize / 2)
            }
            .onAppear {
                // Calcolo dell'altezza finale della linea spostato qui
                let circleCenterY = geo.size.height / 2 + verticalOffset
                let circleBottomY = circleCenterY + (circleSize / 2)
                let finalHeight = geo.size.height - circleBottomY + lineOverlap
                animatedLineHeight = finalHeight
                
                // CHANGE: Start pulsating animation with a smaller scale to reduce movement
                pulseScale = 1.05
            }
            // REMOVE: Observe brakingViewModel.isBraking to control showHollowCircles
            // .onChange(of: brakingViewModel.isBraking) { newValue in
            //     self.showHollowCircles = newValue
            // }
        }
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
