import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pageCount = 5
    @Namespace var onboardingNamespace
    @State private var isPage2MassValid: Bool = false

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2(isMassValid: $isPage2MassValid).tag(1)
                    OnboardingPage3(namespace: onboardingNamespace).tag(2)
                    OnboardingPage4(namespace: onboardingNamespace).tag(3)
                    OnboardingPage5().tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .onChange(of: currentPage) { oldValue, newValue in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    if oldValue == 1 && newValue == 2 && !isPage2MassValid {
                        self.currentPage = oldValue
                    }
                }

                Spacer()

                CustomPageIndicator(currentPage: currentPage, pageCount: pageCount)
                    .padding(.bottom, 40)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom) // Ensures the bottom indicator stays put
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome to O-Buddy")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)
                .padding(.top, 40)
            
            Text("Your driving assistant ready to support you!")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Image("OBD")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct OnboardingPage2: View {
    @AppStorage("vehicleMass") private var carMass: String = ""
    @AppStorage("selectedFuel") private var selectedFuelType: String = "benzina"
    @FocusState private var isMassInputFocused: Bool
    @Binding var isMassValid: Bool

    // CHANGE: Mapping for fuel types display names
    private let fuelAPINames = ["benzina", "gasolio", "gpl", "metano"] // Original API names
    private let fuelDisplayNames: [String: String] = [
        "benzina": "Petrol",
        "gasolio": "Diesel",
        "gpl": "LPG",
        "metano": "Methane"
    ]

    private func validateMass() {
        if let mass = Double(carMass), mass > 0 {
            isMassValid = true
        } else {
            isMassValid = false
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Before starting we need some informations:")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .padding(.bottom, 0)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Insert here the mass of your car:")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                HStack {
                    TextField("", text: $carMass)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .frame(width: 220)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .focused($isMassInputFocused)
                        .onChange(of: carMass) { _, _ in
                            validateMass()
                        }
                    Text("Kg")
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 40)

                if !isMassValid {
                    Text("* This section is mandatory to proceed.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Text("Remember to check your car registration document for the correct mass value.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Ex: Italy")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 42)
                    .padding(.bottom, -10)

                Image("CarDocument")
                    .resizable()
                    .frame(height: 240)
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 40)

                HStack {
                    Text("Insert the type of the fuel :")
                        .font(.title3)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Picker("Select Fuel Type", selection: $selectedFuelType) {
                        // CHANGE: Use fuelAPINames for iteration and fuelDisplayNames for text
                        ForEach(fuelAPINames, id: \.self) { fuel in
                            Text(fuelDisplayNames[fuel] ?? fuel.capitalized)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120, height: 40)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            validateMass()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isMassInputFocused = false
                    validateMass()
                }
            }
        }
    }
}

struct OnboardingPage3: View {
    let namespace: Namespace.ID
    @State private var circleOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Circle()
                .stroke(Color.black, lineWidth: 20)
                .frame(width: 80, height: 80)
                .opacity(circleOpacity)
            
            Text("This is an event!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)
                .padding(.top, 40)
                .opacity(textOpacity)

            Text("You'll see events appear when you do an hard brake. Try to avoid them while you can.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .opacity(textOpacity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                circleOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    textOpacity = 1
                }
            }
        }
    }
}

struct OnboardingPage4: View {
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            HStack(spacing: 0) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("4 Jun 2025")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)

                    Text("Napoli Centrale")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Circle()
                    .fill(Color.black)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hard Brake")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Speed at stop")
                        .font(.subheadline)
                    Text("55 km/h")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Speed at return")
                        .font(.subheadline)
                    Text("15 km/h")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("RPM lost")
                        .font(.subheadline)
                    Text("0.70")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Fuel Consumption")
                        .font(.subheadline)
                    Text("0.07 €")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .offset(x: -10)

            Spacer()

            Text("Discover all the details about your brakes events but, most importantly, the consumption due to them!")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage5: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("Tanks")
                .resizable()
                .frame(width: 320, height: 370)
                .padding(.top, 80)
                .padding(.bottom, 5)

            (Text("In the Consumption Tanks section, you can see detailed consumption over the short / medium / long term.\n") +
            Text("⚠️ IMPORTANT:").foregroundColor(.red) +
            Text(" For your own safety remember to check your driving data ONLY AT THE END of your trip!").foregroundColor(.red))
                .font(.title2) // Changed font to title2 as per request
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 10) // Changed padding to 10 for "more justified" look
                .fixedSize(horizontal: false, vertical: true)
                //.bold()
            
            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CustomPageIndicator: View {
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(height: 10)
                .cornerRadius(5)
                .padding(.horizontal, -100)

            HStack(spacing: 32) {
                ForEach(0..<pageCount, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 36, height: 36)

                        if index == currentPage {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea(edges: .horizontal)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    OnboardingView()
}
