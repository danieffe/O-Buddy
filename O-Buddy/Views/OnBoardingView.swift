import SwiftUI

struct OnboardingView: View {
@State private var currentPage = 0
private let pageCount = 5
@Namespace var onboardingNamespace

var body: some View {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#B1FCFF"), .white]),
            startPoint: .bottom,
            endPoint: .top
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage1().tag(0)
                OnboardingPage2().tag(1)
                OnboardingPage3(namespace: onboardingNamespace).tag(2)
                OnboardingPage4(namespace: onboardingNamespace).tag(3)
                OnboardingPage5().tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            Spacer()

            CustomPageIndicator(currentPage: currentPage, pageCount: pageCount)
                .padding(.bottom, 40)
        }
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
@State private var carMass: String = ""
@State private var selectedFuelType: String = "benzina"

private let fuelTypes = ["benzina", "gasolio", "gpl", "metano"]

var body: some View {
    VStack(spacing: 20) {
        Text("Before we begin we need some informations:")
            .font(.title2)
            .bold()
            .foregroundColor(.black)
            .padding(.top, 40)
            .padding(.bottom, 40)

        VStack(alignment: .leading, spacing: 20) {
            Text("Insert here the mass of your car:")
                .font(.title3)
                .foregroundColor(.black)
            HStack {
                TextField("", text: $carMass)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                Text("Kg")
                    .font(.body)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )

            Text("Insert the type of the fuel :")
                .font(.title3)
                .foregroundColor(.black)
            Picker("Select Fuel Type", selection: $selectedFuelType) {
                ForEach(fuelTypes, id: \.self) { fuel in
                    Text(fuel.capitalized)
                }
            }
            .pickerStyle(.menu)
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.horizontal, 40)

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

struct OnboardingPage3: View {
let namespace: Namespace.ID

var body: some View {
    VStack(spacing: 20) {
        Spacer()

        Circle()
            .stroke(Color.black, lineWidth: 20)
            .frame(width: 80, height: 80)
            .matchedGeometryEffect(id: "onboardingCircle", in: namespace)
        
        Text("This is an event")
            .font(.largeTitle)
            .bold()
            .foregroundColor(.black)
            .padding(.top, 40)

        Text("You'll see events appear when you do a hard brake. try to avoid them when you can.")
            .font(.title2)
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .padding(.horizontal)
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

struct OnboardingPage4: View {
let namespace: Namespace.ID

var body: some View {
    VStack(spacing: 20) {
        Spacer()

        HStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("4 Giu 2025")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)

                Text("New York, USA")
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
                .matchedGeometryEffect(id: "onboardingCircle", in: namespace)
            
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
                Text("Gasoline Consumption")
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
            .padding(.horizontal)
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

struct OnboardingPage5: View {
@Environment(\.dismiss) var dismiss
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

var body: some View {
    VStack(spacing: 50) {
        // ADD: Top header for Consumption Tanks with labels and line
        VStack(spacing: 5) { // Spacing between line/ticks and labels
            ZStack(alignment: .bottom) { // Align items to the bottom of the ZStack
                // Horizontal line
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                    .padding(.horizontal, 40) // Make the line span the width

                // Vertical tick marks on the line
                HStack {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2, height: 10)
                            .offset(y: 4) // Adjust to sit on the 2pt line
                            .frame(maxWidth: .infinity) // Distribute evenly
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Labels (WEEKLY, MONTHLY, YEARLY)
            HStack {
                Text("WEEKLY")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                Text("MONTHLY")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                Text("YEARLY")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40) // Align labels with the line and ticks
        }

        // ADD: TankView previews
        HStack(spacing: 20) { // CHANGE: Increased spacing between tanks
            TankView(tankLimit: 50.0, lostFuelLiters: 15.0, lostFuelCost: 25.0, timePeriod: "WEEKLY")
                .frame(width: 100, height: 180)
            TankView(tankLimit: 50.0, lostFuelLiters: 30.0, lostFuelCost: 50.0, timePeriod: "MONTHLY")
                .frame(width: 100, height: 180)
            TankView(tankLimit: 50.0, lostFuelLiters: 45.0, lostFuelCost: 75.0, timePeriod: "YEARLY")
                .frame(width: 100, height: 180)
        }
        .padding(.horizontal)
        
        // ADD: New instructional text
        Text("In the Consumption Tanks section, you can see detailed consumption over the short / medium / long term.")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .padding(.horizontal)
            .padding(.top, 50) // ADD: Padding to separate from tanks

        Text("Remember to check your driving data after each trip to understand your fuel consumption!")
            .font(.callout)
            .foregroundColor(.orange)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 30) // CHANGE: Increased top padding for the text


        Button {
            hasCompletedOnboarding = true
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
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
        .padding(.horizontal, 40)
    }
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


