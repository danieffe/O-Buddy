//
//  DashboardView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 28/05/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var selectedTab: Int = 1
    @State private var dragOffset: CGFloat = 0
    @State private var activeCardIndex: Int = 1
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Spacer()
                }
                .padding(.top, 3)
                
                // Fuel-themed Title
                VStack(spacing: 8) {
                    Text("FUELISH BEHAVIORS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("SLIDE TO SEE YOUR FUEL CONSUMPTION TANKS!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                // Tab Indicators
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 6)
                        .padding(.horizontal, -20)
                        .overlay(
                            HStack(spacing: 0) {
                                Spacer()
                                Circle()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(selectedTab == 0 ? .black : .white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 5)
                                    )
                                Spacer()

                                Circle()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(selectedTab == 1 ? .black : .white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 5)
                                    )
                                Spacer()

                                Circle()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(selectedTab == 2 ? .black : .white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 5)
                                    )
                                Spacer()
                            }
                            .padding(.horizontal, -10)
                        )
                    
                    // Tab Labels
                    HStack(spacing: 0) {
                        Spacer()
                        Text("YEARLY")
                            .font(.caption)
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                            .foregroundColor(.black)
                            .onTapGesture { selectedTab = 0 }
                        Spacer()

                        Text("MONTHLY")
                            .font(.caption)
                            .fontWeight(selectedTab == 1 ? .bold : .regular)
                            .foregroundColor(.black)
                            .onTapGesture { selectedTab = 1 }
                        Spacer()

                        Text("WEEKLY")
                            .font(.caption)
                            .fontWeight(selectedTab == 2 ? .bold : .regular)
                            .foregroundColor(.black)
                            .onTapGesture { selectedTab = 2 }
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
                
                Spacer()

                // Cards Scroll View with Peeking Effect
                GeometryReader { geometry in
                    let cardWidth = geometry.size.width * 0.7
                    let cardSpacing: CGFloat = 20
                    let peekAmount: CGFloat = 40
                    let totalSpacing = (geometry.size.width - cardWidth) / 2 - peekAmount
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: cardSpacing) {
                                ForEach(0..<3, id: \.self) { index in
                                    CardView(
                                        title: "5L",
                                        bottomText: (index == 1) ? "in a month you\nhave lost\n4L (5$)" : "Placeholder Text"
                                    )
                                    .frame(width: cardWidth)
                                    .id(index)
                                    .scaleEffect(selectedTab == index ? 1 : 0.9)
                                    .opacity(selectedTab == index ? 1 : 0.8)
                                }
                            }
                            .padding(.horizontal, totalSpacing)
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 30
                                        withAnimation(.spring()) {
                                            if value.translation.width < -threshold {
                                                selectedTab = min(selectedTab + 1, 2)
                                            } else if value.translation.width > threshold {
                                                selectedTab = max(selectedTab - 1, 0)
                                            }
                                            dragOffset = 0
                                            proxy.scrollTo(selectedTab, anchor: .center)
                                        }
                                    }
                            )
                        }
                        .onAppear {
                            proxy.scrollTo(selectedTab, anchor: .center)
                        }
                        .onChange(of: selectedTab) { newValue in
                            withAnimation(.spring()) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .frame(height: 600)
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
