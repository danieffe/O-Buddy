//
//  SettingView.swift
//  O-Buddy
//
//  Created by Simone Di Blasi on 27/05/25.
//


import SwiftUI

struct SettingView: View {
    @State private var isDarkModeOn = false
    @State private var notificationsEnabled = true
    @State private var useCellularData = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferenze")) {
                    Toggle("Modalità Scura", isOn: $isDarkModeOn)
                    Toggle("Notifiche", isOn: $notificationsEnabled)
                    Toggle("Usa Dati Cellulare", isOn: $useCellularData)
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}

