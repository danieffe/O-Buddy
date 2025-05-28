import SwiftUI

struct CalendarView: View {
    @State private var selectedPeriod: Period = .monthly
    
    enum Period: CaseIterable {
        case yearly, monthly, weekly
        
        var title: String {
            switch self {
            case .yearly: return "YEARLY"
            case .monthly: return "MONTHLY"
            case .weekly: return "WEEKLY"
            }
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
                    // Header con icone bluetooth e tastiera
                    HStack {
                        Image(systemName: "bluetooth")
                            .font(.title2)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer().frame(height: 50)
                    
                    // Timeline orizzontale
                    HStack(spacing: 0) {
                        ForEach(Period.allCases, id: \.self) { period in
                            VStack(spacing: 8) {
                                // Linea superiore
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 3)
                                
                                // Punto della timeline
                                Circle()
                                    .fill(selectedPeriod == period ? Color.black : Color.gray)
                                    .frame(width: 12, height: 12)
                                
                                // Linea inferiore
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 3)
                                
                                // Testo del periodo
                                Text(period.title)
                                    .font(.caption)
                                    .fontWeight(selectedPeriod == period ? .bold : .regular)
                                    .foregroundColor(.black)
                                    .padding(.top, 8)
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedPeriod = period
                                }
                            }
                            
                            if period != Period.allCases.last {
                                // Linea di connessione tra i punti
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 3)
                                    .offset(y: -24)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 60)
                    
                    // Contenitore principale con swipe
                    TabView(selection: Binding(
                        get: {
                            switch selectedPeriod {
                            case .yearly: return 0
                            case .monthly: return 1
                            case .weekly: return 2
                            }
                        },
                        set: { newValue in
                            switch newValue {
                            case 0: selectedPeriod = .yearly
                            case 1: selectedPeriod = .monthly
                            case 2: selectedPeriod = .weekly
                            default: break
                            }
                        }
                    )) {
                        // YEARLY
                        createContainer(data: ContainerData(liters: "18L", lostLiters: "14L", cost: "18$", period: "in a year"), isPartial: false, width: 200)
                            .tag(0)
                        
                        // MONTHLY
                        createContainer(data: ContainerData(liters: "5L", lostLiters: "4L", cost: "5$", period: "in a month"), isPartial: false, width: 200)
                            .tag(1)
                        
                        // WEEKLY
                        createContainer(data: ContainerData(liters: "1.5L", lostLiters: "1.2L", cost: "1.5$", period: "in a week"), isPartial: false, width: 200)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 420)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Funzione per creare i contenitori
    func createContainer(data: ContainerData, isPartial: Bool, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Parte superiore marrone
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
            
            // Parte inferiore arancione
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
