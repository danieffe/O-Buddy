import SwiftUI

struct BluetoothSearchView: View {
    @State private var isSearching = true
    @State private var deviceFound = false
    @State private var pulseScale1: CGFloat = 1.0
    @State private var pulseScale2: CGFloat = 1.0
    @State private var pulseScale3: CGFloat = 1.0
    @State private var pulseOpacity1: Double = 1.0
    @State private var pulseOpacity2: Double = 1.0
    @State private var pulseOpacity3: Double = 1.0

    let circleSize: CGFloat = 50
    let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)

    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                ZStack {
                    if isSearching && !deviceFound {
                        Circle()
                            .stroke(Color.black.opacity(pulseOpacity1), lineWidth: 2)
                            .frame(width: 150, height: 150)
                            .scaleEffect(pulseScale1)

                        Circle()
                            .stroke(Color.black.opacity(pulseOpacity2), lineWidth: 2)
                            .frame(width: 150, height: 150)
                            .scaleEffect(pulseScale2)

                        Circle()
                            .stroke(Color.black.opacity(pulseOpacity3), lineWidth: 2)
                            .frame(width: 150, height: 150)
                            .scaleEffect(pulseScale3)
                    }

                    // Cerchio centrale
                    Circle()
                        .fill(deviceFound ? Color.black : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.black, style: strokeStyle)
                                .opacity(deviceFound ? 0 : 1)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .animation(.easeInOut(duration: 0.5), value: deviceFound)
                }

                Spacer()

                Text(deviceFound ? "Dispositivo connesso" :
                     isSearching ? "Ricerca dispositivi Bluetooth..." : "Pronto a cercare")
                    .font(.title2)
                    .padding(.bottom, 50)
                    .foregroundColor(.black)
                    .animation(.easeInOut, value: deviceFound)
            }

            // Solo per simulazione, rimuovere nella versione finale
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            deviceFound.toggle()
                            if deviceFound {
                                stopPulseAnimation()
                            } else {
                                startPulseAnimation()
                            }
                        }
                    }) {
                        Text("Toggle Stato")
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    func startPulseAnimation() {
        isSearching = true

        withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            pulseScale1 = 1.5
            pulseOpacity1 = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseScale2 = 1.5
                pulseOpacity2 = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseScale3 = 1.5
                pulseOpacity3 = 0.0
            }
        }
    }

    func stopPulseAnimation() {
        isSearching = false
        pulseScale1 = 1.0
        pulseScale2 = 1.0
        pulseScale3 = 1.0
        pulseOpacity1 = 1.0
        pulseOpacity2 = 1.0
        pulseOpacity3 = 1.0
    }
}

struct BluetoothSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothSearchView()
    }
}
