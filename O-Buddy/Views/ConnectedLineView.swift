//
//  ConnectedLineView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 27/05/25.
//

import SwiftUI

struct ConnectedLineView: View {
    let circleSize: CGFloat = 40
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
    let verticalOffset: CGFloat = -100
    let lineOverlap: CGFloat = 8

    @State private var animatedLineHeight: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    // ADD: Constants for hollow circles and text
    let hollowCircleSize: CGFloat = 40
    let hollowCircleStrokeWidth: CGFloat = 25
    let firstHollowCircleRelativeYOffset: CGFloat = 90
    let secondHollowCircleRelativeYOffset: CGFloat = 180
    let textHorizontalOffset: CGFloat = 110
    // ADD: Constants for top bar icons
    let iconSize: CGFloat = 30
    let iconPadding: CGFloat = 20


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

                // ADD: First hollow circle
                Circle()
                    .stroke(Color.black, lineWidth: hollowCircleStrokeWidth)
                    .fill(Color.white) // ADD: Fill to make the circle white inside
                    .frame(width: hollowCircleSize, height: hollowCircleSize)
                    .position(
                        x: geo.size.width / 2,
                        y: circleCenterY + firstHollowCircleRelativeYOffset
                    )
                    .opacity(animatedLineHeight > 0 ? 1 : 0)

                // ADD: Second hollow circle
                Circle()
                    .stroke(Color.black, lineWidth: hollowCircleStrokeWidth)
                    .fill(Color.white) // ADD: Fill to make the circle white inside
                    .frame(width: hollowCircleSize, height: hollowCircleSize)
                    .position(
                        x: geo.size.width / 2,
                        y: circleCenterY + secondHollowCircleRelativeYOffset
                    )
                    .opacity(animatedLineHeight > 0 ? 1 : 0)

                // ADD: Aggressive drive text
                Text("Aggressive drive")
                    .foregroundColor(.black)
                    .font(.body)
                    .position(
                        x: geo.size.width / 2 - textHorizontalOffset,
                        y: circleCenterY
                    )

                // ADD: Actual Speed text
                Text("Actual Speed\n120 km/h")
                    .foregroundColor(.black)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .position(
                        x: geo.size.width / 2 + textHorizontalOffset,
                        y: circleCenterY
                    )
                
                // CHANGE: Bluetooth icon to list.clipboard
                Image(systemName: "wave.3.right.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.black)
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
                
                // ADD: Start pulsating animation
                pulseScale = 1.05
            }
        }
    }
}

struct ConnectedLineView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedLineView()
    }
}
