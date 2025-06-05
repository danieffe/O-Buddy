import SwiftUI

// ADD: Custom Shape for Diagonal Lines
struct DiagonalLines: Shape {
  let lineSpacing: CGFloat = 7
  let lineWidth: CGFloat = 1

  func path(in rect: CGRect) -> Path {
      var path = Path()
      let diagonalLength = sqrt(rect.width * rect.width + rect.height * rect.height)
      let numLines = Int(diagonalLength / lineSpacing) + 80

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

struct TankView: View {
  let tankLimit: Double
  let lostFuelLiters: Double
  let lostFuelCost: Double
  let timePeriod: String

  // ADD: State for wave animation
  @State private var waveOffset: CGFloat = 0
  // ADD: Timer for wave animation
  let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

  private var formattedTimePeriod: String {
      switch timePeriod.uppercased() {
      case "WEEKLY": return "week"
      case "MONTHLY": return "month"
      case "YEARLY": return "year"
      default: return timePeriod.lowercased()
      }
  }

  private var tankGraphicView: some View {
      ZStack(alignment: .bottom) {
          // Background of the tank (empty part, slight transparency)
          RoundedRectangle(cornerRadius: 12)
              .fill(Color.gray.opacity(0.1))

          // Liquid animato (representing lost fuel)
          GeometryReader { geometry in
              let width = geometry.size.width
              let height = geometry.size.height
              let fillPercentage = lostFuelLiters / tankLimit
              let clampedFillPercentage = min(max(fillPercentage, 0), 1) // Ensure percentage is between 0 and 1
              
              let filledHeight = height * clampedFillPercentage
              
              let waveHeight: CGFloat = 10 // Amplitude of the wave
              let waveLength: CGFloat = width / 2 // Length of one wave cycle
              
              // Path for the animated liquid
              Path { path in
                  // Start from the bottom-left corner
                  path.move(to: CGPoint(x: 0, y: height))
                  // Line to the bottom-right corner
                  path.addLine(to: CGPoint(x: width, y: height))
                  
                  // Base Y-coordinate for the wave (top of the filled liquid)
                  let waveBaseY = height - filledHeight
                  
                  // Line up to the right edge of the fluid level (start of the wave)
                  path.addLine(to: CGPoint(x: width, y: waveBaseY + waveHeight))
                  
                  // Create the waves on the surface (from right to left)
                  for x in stride(from: width, through: 0, by: -1) {
                      let relativeX = (width - x) / waveLength
                      let sine = sin(relativeX * .pi * 4 + waveOffset)
                      let y = waveBaseY + sine * waveHeight
                      path.addLine(to: CGPoint(x: x, y: y))
                  }
                  
                  // Close the path to form a filled shape (down to bottom-left)
                  path.addLine(to: CGPoint(x: 0, y: waveBaseY + waveHeight))
                  path.closeSubpath()
              }
              .fill(
                  LinearGradient(
                      colors: [
                          Color.red.opacity(0.8), // Colors indicating "lost" fuel
                          Color.red.opacity(0.6),
                          Color.red.opacity(0.9)
                      ],
                      startPoint: .top,
                      endPoint: .bottom
                  )
              )
              // Overlay the diagonal lines on the filled liquid
              .overlay(
                  DiagonalLines()
                      .stroke(Color.black, lineWidth: 1)
                      .mask(
                          // Mask the lines to the same liquid path to ensure they only appear on the liquid
                          Path { path in
                              let waveBaseY = height - filledHeight
                              path.move(to: CGPoint(x: 0, y: height))
                              path.addLine(to: CGPoint(x: width, y: height))
                              path.addLine(to: CGPoint(x: width, y: waveBaseY + waveHeight))
                              for x in stride(from: width, through: 0, by: -1) {
                                  let relativeX = (width - x) / waveLength
                                  let sine = sin(relativeX * .pi * 4 + waveOffset)
                                  let y = waveBaseY + sine * waveHeight
                                  path.addLine(to: CGPoint(x: x, y: y))
                              }
                              path.addLine(to: CGPoint(x: 0, y: waveBaseY + waveHeight))
                              path.closeSubpath()
                          }
                      )
              )
              // Clip the entire liquid view to the rounded rectangle shape of the inner tank
              .mask(
                  RoundedRectangle(cornerRadius: 12)
                      .frame(width: width, height: height)
              )
          }
          .padding(4) // Small padding to make the liquid sit slightly inside the rounded rectangle
      }
  }

  var body: some View {
      VStack(spacing: 0) {
          VStack {
              Text("in a \(formattedTimePeriod) you\nhave lost")
                  .multilineTextAlignment(.center)
                  .font(.body)
                  .foregroundColor(.black)
              
              Text("\(String(format: "%.0f", lostFuelLiters))L (\(String(format: "%.0f", lostFuelCost))$)")
                  .font(.headline)
                  .fontWeight(.bold)
                  .foregroundColor(.red)
          }
          .padding(.top, 40)
          .padding(.horizontal)

          Spacer()
          
          tankGraphicView
              .frame(height: 250)
      }
      .background(Color.white)
      .cornerRadius(15)
      .overlay(
          RoundedRectangle(cornerRadius: 15) // CHANGE: Changed from Rectangle to RoundedRectangle for consistent corner radius
              .stroke(Color.black, lineWidth: 10)
      )
      .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
      // ADD: Attach onReceive to update waveOffset
      .onReceive(timer) { _ in
          waveOffset += 0.3 // Increment continuously for rightward movement
      }
  }
}

struct TankView_Previews: PreviewProvider {
  static var previews: some View {
      TankView(tankLimit: 5.0, lostFuelLiters: 2.0, lostFuelCost: 5.0, timePeriod: "MONTH")
          .previewLayout(.sizeThatFits)
          .padding()
  }
}

