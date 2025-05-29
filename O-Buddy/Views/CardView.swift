//
//  CardView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 29/05/25.
//

import SwiftUI

struct CardView: View {
    let title: String
    let bottomText: String

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 102/255, green: 71/255, blue: 0))
                .frame(height: 100)
                .overlay(
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            Rectangle()
                .fill(Color(red: 255/255, green: 215/255, blue: 140/255))
                .overlay(
                    VStack {
                        Spacer()
                        Text(bottomText)
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                        if bottomText.contains("4L (5$)") {
                            Text("4L (5$)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                )
        }
        .cornerRadius(15)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 10)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    CardView(title: "Placeholder", bottomText: "Plaeholder")
}
