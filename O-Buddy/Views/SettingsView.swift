//
//  SettingsView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 04/06/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedFuel: String = "gasolio" // State for the selected fuel type
    // Le variabili @State per i toggle generali sono state rimosse
    
    private let fuelTypes = ["benzina", "gasolio", "gpl", "metano"] // Available fuel types

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Fuel Type Section
                Section(header: Text("Fuel Preferences")) {
                    Picker("Select Fuel Type", selection: $selectedFuel) {
                        ForEach(fuelTypes, id: \.self) { fuelType in
                            Text(fuelType.capitalized).tag(fuelType)
                        }
                    }
                    .pickerStyle(.menu) // Modern, compact style for selection
                }

                // MARK: About App Section
                Section(header: Text("About O-Buddy")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0") // Replace with dynamic version if available
                    }
                    }
                }
            }
            .navigationTitle("Settings") // Title for the navigation bar
            .navigationBarTitleDisplayMode(.inline) // Compact title display
        }
    }


// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


