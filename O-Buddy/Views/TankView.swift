//
//  CardView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 29/05/25.
//

import SwiftUI

// ADD: Custom Shape for Diagonal Lines
struct DiagonalLines: Shape {
    let lineSpacing: CGFloat = 7 // CHANGE: Decreased line spacing slightly to make lines more dense
    let lineWidth: CGFloat = 1 // Width of each line

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let diagonalLength = sqrt(rect.width * rect.width + rect.height * rect.height)
        let numLines = Int(diagonalLength / lineSpacing) + 80 // CHANGE: Increased buffer for full coverage

        for i in 0..<numLines {
            let offset = CGFloat(i) * lineSpacing
            let startX = rect.minX - rect.height + offset
            let endX = rect.maxX + rect.height + offset

            path.move(to: CGPoint(x: startX, y: rect.maxY))
            path.addLine(to: CGPoint(x: endX, y: rect.minY))
        }
        return path
    }
}

// CHANGE: Renamed struct from CardView to TankView
struct TankView: View {
    let tankLimit: Double // Total capacity of the tank (e.g., 5L)
    let lostFuelLiters: Double // Amount of fuel lost (e.g., 2L)
    let lostFuelCost: Double // Cost of fuel lost (e.g., 5$)
    let timePeriod: String // "YEARLY", "MONTHLY", "WEEKLY"

    // ADD: Computed property for grammatically correct time period
    private var formattedTimePeriod: String {
        switch timePeriod.uppercased() {
        case "WEEKLY": return "week"
        case "MONTHLY": return "month"
        case "YEARLY": return "year"
        default: return timePeriod.lowercased()
        }
    }

    // Helper view for the tank graphic
    private var tankGraphicView: some View {
        ZStack(alignment: .bottom) {
            // Background of the tank (empty part)
            Rectangle()
                .fill(Color.white)

            // Hatched "lost fuel" part
            GeometryReader { geometry in
                let fillPercentage = lostFuelLiters / tankLimit
                let currentFillHeight = geometry.size.height * fillPercentage // CHANGE: Renamed filledHeight to currentFillHeight for clarity
                let waveAmplitude: CGFloat = 15 // ADD: Amplitude of the wave (half of the original 30 for control point)
                let waveOffset: CGFloat = 0 // ADD: Offset for the wave from the true fill line (can be adjusted)
                
                // CHANGE: Redraw Path to start from bottom for fuel fill effect
                let fuelPath = Path { path in
                    // Start at bottom-left
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    // Line to bottom-right
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    // Line up to the right edge of the fluid level
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - currentFillHeight + waveOffset))
                    // Draw the wave curve from right to left
                    path.addQuadCurve(to: CGPoint(x: 0, y: geometry.size.height - currentFillHeight + waveOffset),
                                      control: CGPoint(x: geometry.size.width / 2, y: geometry.size.height - currentFillHeight - waveAmplitude + waveOffset)) // Control point for the wave
                    // Close the path to form a filled shape
                    path.closeSubpath()
                }
                
                fuelPath
                    .fill(Color.gray.opacity(0.8)) // Base color for hatching
                    // ADD: Overlay diagonal lines
                    .overlay(
                        DiagonalLines()
                            .stroke(Color.black, lineWidth: 1)
                    )
                    // ADD: Mask the combined fill and lines to the fuel shape
                    .mask(fuelPath)
                    // REMOVE: Adjust frame and offset based on new wave calculation from here
            }
        }
    // REMOVE: .frame(height: 300) from tankGraphicView, will be set in CardView's body
    }

    var body: some View {
        VStack(spacing: 0) { // CHANGE: Remove specific fill colors from CardView body, rely on tankGraphicView and overall background
            // ADD: Top Section - Lost Fuel Information
            VStack {
                // CHANGE: Use formattedTimePeriod
                Text("in a \(formattedTimePeriod) you\nhave lost")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(.black)
                
                Text("\(String(format: "%.0f", lostFuelLiters))L (\(String(format: "%.0f", lostFuelCost))$)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            .padding(.top, 40) // Padding from the top edge of the card
            .padding(.horizontal) // Horizontal padding for text

            Spacer() // Pushes the fuel graphic to the bottom
            
            // CHANGE: Middle/Bottom Section - Tank Graphic now fills remaining space
            tankGraphicView
                .frame(height: 250) // ADD: Fixed height for the tank graphic area to match visual proportion
        }
        .background(Color.white) // ADD: Entire card background is white
        .cornerRadius(15)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 10)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// CHANGE: Renamed CardView_Previews to TankView_Previews
struct TankView_Previews: PreviewProvider {
    static var previews: some View {
        TankView(tankLimit: 5.0, lostFuelLiters: 2.0, lostFuelCost: 5.0, timePeriod: "MONTH")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
