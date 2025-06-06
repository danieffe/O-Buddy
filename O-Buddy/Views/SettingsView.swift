//
//  SettingsView.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 04/06/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedFuel") private var selectedFuel: String = "gasolio" // State for the selected fuel type, now persistent
    @AppStorage("vehicleMass") private var vehicleMass: String = "" // State for vehicle mass, persistent
    @State private var isMassValid: Bool = true // State to track mass input validity
    // Le variabili @State per i toggle generali sono state rimosse
    
    private let fuelTypes = ["benzina", "gasolio", "gpl", "metano"] // Available fuel types
    
    @FocusState private var isMassInputFocused: Bool

    // Function to validate vehicle mass
    private func validateMass() {
        if vehicleMass.isEmpty {
            isMassValid = true // Allow empty field if not mandatory at this point, or change to false if it must be filled.
            return
        }
        if let mass = Double(vehicleMass), mass > 0 {
            isMassValid = true
        } else {
            isMassValid = false
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Vehicle Information Section
                Section(header: Text("Vehicle Information")) {
                    Picker("Select Fuel Type", selection: $selectedFuel) {
                        ForEach(fuelTypes, id: \.self) { fuelType in
                            Text(fuelType.capitalized).tag(fuelType)
                        }
                    }
                    .pickerStyle(.menu) // Modern, compact style for selection
                    
                    // Vehicle Mass input
                    HStack {
                        Text("Vehicle Mass")
                        Spacer()
                        TextField("Enter mass in Kg", text: $vehicleMass)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(isMassValid ? .primary : .red)
                            .onChange(of: vehicleMass) { _, _ in
                                validateMass()
                            }
                            .focused($isMassInputFocused)
                    }
                    if !isMassValid {
                        Text("Please enter a valid positive number for vehicle mass.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
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
            .navigationTitle("Settings") // Title for the navigation bar
            .navigationBarTitleDisplayMode(.inline) // Compact title display
            .onAppear { // Validate mass on appear
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
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
