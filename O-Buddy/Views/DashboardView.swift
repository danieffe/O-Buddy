//
//  DashboardView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 28/05/25.
//

import SwiftUI

struct DashboardView: View {
@State private var selectedTab: Int? = 0

@EnvironmentObject var brakingViewModel: BrakingViewModel

var body: some View {
    let cardData: [(title: String, lostFuel: Double, lostCost: Double, tankLimit: Double)] = [
        ("WEEKLY", brakingViewModel.weeklyLostFuelLiters, brakingViewModel.weeklyLostFuelCost, 5.0),
        ("MONTHLY", brakingViewModel.monthlyLostFuelLiters, brakingViewModel.monthlyLostFuelCost, 5.0),
        ("YEARLY", brakingViewModel.yearlyLostFuelLiters, brakingViewModel.yearlyLostFuelCost, 5.0)
    ]
    
    ZStack {
        Color.white
            // REMOVE: .edgesIgnoringSafeArea(.all)
        
        VStack(spacing: 0) {
            HStack {
                Spacer()
            }
            .padding(.top, 50)
            
            Text("Check here your Fuel-ish behaviors!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 10)
                        .ignoresSafeArea(.all, edges: .horizontal)
                    
                    HStack(spacing: 0) {
                        Spacer()
                        ForEach(0..<cardData.count, id: \.self) { index in
                            VStack {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 30)
                                    .onTapGesture {
                                        selectedTab = index
                                    }
                                Text(cardData[index].title)
                                    .font(.caption)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                                    .foregroundColor(.black)
                                    .padding(.top, 5)
                                    .onTapGesture {
                                        selectedTab = index
                                    }
                            }
                            .offset(y: -(12 - 40) / 2)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            GeometryReader { geometry in
                let cardWidth = geometry.size.width * 0.7
                let cardSpacing: CGFloat = 30
                let peekAmount: CGFloat = (geometry.size.width - cardWidth) / 2 - 20
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cardSpacing) {
                        ForEach(cardData.indices, id: \.self) { index in
                            let data = cardData[index]
                            TankView(
                                tankLimit: data.tankLimit,
                                lostFuelLiters: data.lostFuel,
                                lostFuelCost: data.lostCost,
                                timePeriod: data.title
                            )
                            .frame(width: cardWidth)
                            .id(index)
                            .opacity(selectedTab == index ? 1 : 0.8)
                            .animation(.easeInOut, value: selectedTab)
                        }
                    }
                    .padding(.horizontal, peekAmount)
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $selectedTab, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
            }
            .frame(height: 400)
            .padding(.bottom, 20)
            .offset(y: -90)
        }
        .navigationTitle("Consumption tanks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
}
struct DashboardView_Previews: PreviewProvider {
static var previews: some View {
DashboardView()
    .environmentObject(BrakingViewModel(
        speedPublisher: (0...100).publisher.eraseToAnyPublisher(),
        rpmPublisher: (0...100).publisher.eraseToAnyPublisher(),
        fuelPressurePublisher: (0...100).publisher.eraseToAnyPublisher()
    ))
}
}


