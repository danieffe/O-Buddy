//
//  ConnectedLineView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 27/05/25.
//

import SwiftUI
import Combine

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

    let iconSize: CGFloat = 30
    let iconPadding: CGFloat = 20

    @StateObject private var obdViewModel: OBDViewModel
    @StateObject private var brakingViewModel: BrakingViewModel

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
                                // CHANGE: Iterate over enumerated events to get index
                                ForEach(brakingViewModel.brakingEvents.enumerated().reversed(), id: \.element.id) { index, event in
                                    // CHANGE: Removed displayIndex as we are reversing the array directly
                                    // REMOVE: Removed numberOfEvents and displayIndex calculation
                                    Group { // Group to apply onTapGesture to both circle and text
                                        Circle()
                                            // CHANGE: Fill based on event.isExpanded
                                            .fill(event.isExpanded ? Color.black : Color.white)
                                            .stroke(Color.black, lineWidth: eventCircleStrokeWidth)
                                            .frame(width: eventCircleSize, height: eventCircleSize)
                                            // CHANGE: Position circles using the index of the reversed array
                                            .offset(y: CGFloat(index) * eventCircleVerticalSpacing)
                                            .transition(.scale)
                                        
                                        // ADD: Braking event details
                                        if event.isExpanded {
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
                                                Text("7km/h") // Placeholder
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("RPM lost")
                                                    .font(.caption)
                                                Text("1.02") // Placeholder
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("Gasoline Consumption")
                                                    .font(.caption)
                                                Text("+0.20€") // Placeholder
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(8)
                                            .shadow(radius: 3)
                                            // CHANGE: Position text to the right of the circle
                                            .offset(x: geo.size.width / 2 - geo.size.width / 2 + 100, y: CGFloat(index) * eventCircleVerticalSpacing)
                                            .transition(.opacity) // Add transition for text appearance/disappearance
                                        }
                                    }
                                    .onTapGesture {
                                        // CHANGE: Toggle isExpanded for the tapped event
                                        brakingViewModel.brakingEvents[index].isExpanded.toggle()
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
                }
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
    static var previews: some View {
        MainView()
    }
}
