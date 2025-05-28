import SwiftUI

struct CalendarView: View {
    @State private var selectedPeriod: Period = .monthly
    @Environment(\.dismiss) private var dismiss
    
    enum Period: CaseIterable, Comparable { // Aggiunto Comparable per il confronto
        case yearly, monthly, weekly
        
        var title: String {
            switch self {
            case .yearly: return "YEARLY"
            case .monthly: return "MONTHLY"
            case .weekly: return "WEEKLY"
            }
        }
        
        // Per confrontare gli enum e capire se sono a sinistra o a destra
        static func < (lhs: Period, rhs: Period) -> Bool {
            let allCases = Period.allCases
            guard let lhsIndex = allCases.firstIndex(of: lhs),
                  let rhsIndex = allCases.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
    }
    
    // Dati per ogni periodo
    var currentContainerData: ContainerData {
        switch selectedPeriod {
        case .yearly:
            return ContainerData(liters: "18L", lostLiters: "14L", cost: "18$", period: "in a year")
        case .monthly:
            return ContainerData(liters: "5L", lostLiters: "4L", cost: "5$", period: "in a month")
        case .weekly:
            return ContainerData(liters: "1.5L", lostLiters: "1.2L", cost: "1.5$", period: "in a week")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer().frame(height: 50)
                    
                    // --- Timeline Section ---
                    VStack {
                        Rectangle() // The horizontal line
                            .fill(Color.black)
                            .frame(height: 10)
                            .padding(.horizontal, 0)
                            .overlay( // Overlay the circles directly on the line
                                HStack(spacing: 0) {
                                    ForEach(Period.allCases, id: \.self) { period in
                                        Circle()
                                            .stroke(Color.black, lineWidth: 15)
                                            .fill(selectedPeriod == period ? Color.black : Color.white)
                                            .frame(width: 40, height: 40)
                                            .frame(maxWidth: .infinity) // Distribute circles evenly
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    selectedPeriod = period
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 40) // Match line's padding for circle distribution
                            )
                        
                        // Text titles below the line
                        HStack(spacing: 0) {
                            ForEach(Period.allCases, id: \.self) { period in
                                Text(period.title)
                                    .font(.system(size: 15))
                                    .fontWeight(selectedPeriod == period ? .bold : .regular)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity) // Match circle distribution
                                    .padding(.top, 25) // Space between line/circles and text
                            }
                        }
                        .padding(.horizontal, 40) // Match line's padding
                    }
                    // --- End Timeline Section ---
                    
                    Spacer().frame(height: 60)
                    
                    // --- Main Container with Pushed-Out Side Previews ---
                    TabView(selection: $selectedPeriod) { // Bind directly to selectedPeriod
                        ForEach(Period.allCases, id: \.self) { period in
                            createContainer(data: getContainerData(for: period), isPartial: false, width: geometry.size.width * 0.65) // Slightly wider main item
                                .scaleEffect(selectedPeriod == period ? 1.0 : 0.95) // Slightly smaller scale for non-selected
                                .offset(x: selectedPeriod == period ? 0 : (period < selectedPeriod ? -geometry.size.width * 0.05 : geometry.size.width * 0.05)) // Push slightly out
                                .opacity(selectedPeriod == period ? 1.0 : 0.7) // Slightly less opaque
                                .tag(period) // Use Period enum directly as tag
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Page swipe style
                    .indexViewStyle(.page(backgroundDisplayMode: .never)) // Hide page dots
                    .frame(height: 450)
                    .padding(.horizontal, geometry.size.width * 0.075) // Less padding, more of the main item
                    .animation(.easeInOut(duration: 0.3), value: selectedPeriod) // Animate changes

                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // Helper to get ContainerData for a given Period
    func getContainerData(for period: Period) -> ContainerData {
        switch period {
        case .yearly:
            return ContainerData(liters: "18L", lostLiters: "14L", cost: "18$", period: "in a year")
        case .monthly:
            return ContainerData(liters: "5L", lostLiters: "4L", cost: "5$", period: "in a month")
        case .weekly:
            return ContainerData(liters: "1.5L", lostLiters: "1.2L", cost: "1.5$", period: "in a week")
        }
    }
    
    // Function to create containers
    func createContainer(data: ContainerData, isPartial: Bool, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Brown top part
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                
                if !isPartial {
                    Text(data.liters)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 120)
            
            // Orange bottom part
            ZStack {
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.4))
                
                if !isPartial {
                    VStack(spacing: 8) {
                        Text("\(data.period) you")
                            .font(.body)
                            .foregroundColor(.black)
                        Text("have lost")
                            .font(.body)
                            .foregroundColor(.black)
                        Text("\(data.lostLiters) (\(data.cost))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(height: 300)
        }
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: isPartial ? 0 : 3)
        )
    }
}

struct ContainerData {
    let liters: String
    let lostLiters: String
    let cost: String
    let period: String
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
