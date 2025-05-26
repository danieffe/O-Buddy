import SwiftUI

struct ConnectedLineView: View {
    let circleSize: CGFloat = 50
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
    let verticalOffset: CGFloat = -100
    let lineOverlap: CGFloat = 8

    @State private var animatedLineHeight: CGFloat = 0

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
            }
            .onAppear {
                // Calcolo dell'altezza finale della linea spostato qui
                let circleCenterY = geo.size.height / 2 + verticalOffset
                let circleBottomY = circleCenterY + (circleSize / 2)
                let finalHeight = geo.size.height - circleBottomY + lineOverlap
                animatedLineHeight = finalHeight
            }
        }
    }
}

struct ConnectedLineView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedLineView()
    }
}
