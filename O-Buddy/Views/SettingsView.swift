//
//  SettingsView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 27/05/25.
//

import SwiftUI

struct SettingsView: View {
var body: some View {
    ZStack {

        Color.white

        Text("Settings View")
            .font(.largeTitle)
            .foregroundColor(.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}
}

struct SettingsView_Previews: PreviewProvider {
static var previews: some View {
    SettingsView()
}
}

