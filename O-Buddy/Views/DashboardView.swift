//
//  DashboardView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 28/05/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var selectedTab: Int? = 0 // CHANGE: Default to Weekly (index 0)
    // REMOVE: @State private var dragOffset: CGFloat = 0
    
    // REMOVE: Using fixed card content for now, this will be dynamic later
    // REMOVE: let cardData: [(title: String, lostFuel: Double, lostCost: Double, tankLimit: Double)] = [...]
    
    // ADD: EnvironmentObject for BrakingViewModel
    @EnvironmentObject var brakingViewModel: BrakingViewModel
    
    var body: some View {
        // ADD: Dynamic cardData based on ViewModel
        let cardData: [(title: String, lostFuel: Double, lostCost: Double, tankLimit: Double)] = [
            ("WEEKLY", brakingViewModel.weeklyLostFuelLiters, brakingViewModel.weeklyLostFuelCost, 5.0),
            ("MONTHLY", brakingViewModel.monthlyLostFuelLiters, brakingViewModel.monthlyLostFuelCost, 5.0),
            ("YEARLY", brakingViewModel.yearlyLostFuelLiters, brakingViewModel.yearlyLostFuelCost, 5.0)
        ]
        
        ZStack {
            // CHANGE: Background color to white
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Bar - Empty as icons removed
                HStack {
                    Spacer()
                }
                .padding(.top, 50) // Padding from top edge
                
                // ADD: Text above the tabbar
                Text("Check here your Fuel-ish behaviors!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10) // Add some padding below the text
                
                // Tab Indicators and Labels
                VStack(spacing: 0) {
                    ZStack { // Use ZStack to explicitly layer horizontal line and vertical dashes
                        Rectangle()
                            .fill(Color.black)
                        // CHANGE: Thicker horizontal line
                            .frame(height: 10) // Make the line thicker
                            .ignoresSafeArea(.all, edges: .horizontal) // Extend the line to the edges
                        
                        HStack(spacing: 0) {
                            Spacer()
                            ForEach(0..<cardData.count, id: \.self) { index in
                                VStack {
                                    Rectangle()
                                        .fill(Color.black) // CHANGE: Apply fill BEFORE frame
                                    // CHANGE: Increase height of vertical dashes for more visual impact
                                        .frame(width: 6, height: 30) // Increased height from 25 to 30
                                        .onTapGesture {
                                            selectedTab = index // CHANGE: Assign non-optional Int to optional Int?
                                        }
                                    Text(cardData[index].title)
                                        .font(.caption)
                                        .fontWeight(selectedTab == index ? .bold : .regular)
                                        .foregroundColor(.black)
                                        .padding(.top, 5)
                                        .onTapGesture {
                                            selectedTab = index // CHANGE: Assign non-optional Int to optional Int?
                                        }
                                }
                                // CHANGE: Adjust offset to perfectly center new 30pt dashes on 10pt line
                                .offset(y: -(12 - 40) / 2) // (dash_height - line_height) / 2 = (30 - 10) / 2 = 10
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
                
                // REMOVE: Fuel-themed Title VStack
                Spacer() // This spacer is now the only one pushing content up from the bottom
                
                // Cards Scroll View with Peeking Effect
                GeometryReader { geometry in
                    let cardWidth = geometry.size.width * 0.7
                    let cardSpacing: CGFloat = 30 // CHANGE: Increased card spacing from 20 to 30
                    let peekAmount: CGFloat = (geometry.size.width - cardWidth) / 2 - 20 // Adjusted peek amount
                    
                    // REMOVE: ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cardSpacing) {
                            ForEach(cardData.indices, id: \.self) { index in
                                let data = cardData[index]
                                TankView(
                                    tankLimit: data.tankLimit,
                                    lostFuelLiters: data.lostFuel,
                                    lostFuelCost: data.lostCost,
                                    timePeriod: data.title // Pass the time period for text formatting
                                )
                                .frame(width: cardWidth)
                                .id(index)
                                // REMOVE: .scaleEffect(selectedTab == index ? 1 : 0.9)
                                .opacity(selectedTab == index ? 1 : 0.8)
                                .animation(.easeInOut, value: selectedTab) // Animate opacity
                            }
                        }
                        .padding(.horizontal, peekAmount)
                        .scrollTargetLayout() // ADD: Mark this layout as a scroll target
                        // REMOVE: .offset(x: dragOffset)
                        // REMOVE: .gesture(...)
                    }
                    .scrollPosition(id: $selectedTab, anchor: .center) // ADD: Link scroll position to selectedTab
                    .scrollTargetBehavior(.viewAligned) // ADD: Snap to views
                    // REMOVE: .onAppear { proxy.scrollTo(selectedTab, anchor: .center) }
                    // REMOVE: .onChange(of: selectedTab) { newValue in ... }
                    // REMOVE: } // End of ScrollViewReader
                }
                .frame(height: 400) // Adjusted height for cards
                .padding(.bottom, 20)
                .offset(y: -90) // CHANGE: Lift cards higher (from -40 to -90)
            }
            .navigationTitle("Consumption tanks") // ADD: Navigation title
        }
    }
}
struct DashboardView_Previews: PreviewProvider {
static var previews: some View {
  // CHANGE: Add EnvironmentObject for preview
  DashboardView()
      .environmentObject(BrakingViewModel(
          speedPublisher: (0...100).publisher.eraseToAnyPublisher(),
          rpmPublisher: (0...100).publisher.eraseToAnyPublisher(),
          fuelPressurePublisher: (0...100).publisher.eraseToAnyPublisher()
      ))
}
}
